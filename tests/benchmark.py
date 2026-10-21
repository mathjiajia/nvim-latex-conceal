#!/usr/bin/env python3
"""Measure real Neovim redraws in a fixed-size Unix terminal."""

from __future__ import annotations

import argparse
import errno
import fcntl
import json
import math
import os
from pathlib import Path
import pty
import re
import select
import shutil
import signal
import statistics
import struct
import subprocess
import sys
import tempfile
import termios
import time


ROOT = Path(__file__).resolve().parent.parent
WORKER = ROOT / "tests" / "benchmark.lua"
WIDTH, HEIGHT = 120, 40
TAIL_BYTES = 8192
METRICS = {
    "attach_first_paint_ms": "Attach and first paint",
    "cached_redraw": "Cached full redraw",
    "cursor": "Cursor move",
    "scroll_line": "Scroll one line",
    "jump": "Distant jump",
    "edit": "Text edit and repaint",
    "edit_math": "Formula edit and repaint",
}


def integer_at_least(minimum):
    def parse(value):
        try:
            number = int(value)
        except ValueError as exc:
            raise argparse.ArgumentTypeError("must be an integer") from exc
        if number < minimum:
            raise argparse.ArgumentTypeError(f"must be at least {minimum}")
        return number

    return parse


def positive_seconds(value):
    try:
        number = float(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("must be a positive number of seconds") from exc
    if not math.isfinite(number) or number <= 0:
        raise argparse.ArgumentTypeError("must be a positive, finite number of seconds")
    return number


def arguments():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", type=Path, help="compare another plugin checkout")
    parser.add_argument("--lines", type=integer_at_least(100), default=10000, help="TeX lines (default: 10000)")
    parser.add_argument("--runs", type=integer_at_least(1), default=4, help="fresh processes per checkout (default: 4)")
    parser.add_argument("--steps", type=integer_at_least(1), default=40, help="samples per operation (default: 40)")
    parser.add_argument("--warmup", type=integer_at_least(0), default=10, help="warmups per operation (default: 10)")
    parser.add_argument("--output", type=Path, help="write full results and provenance as JSON")
    parser.add_argument("--nvim", default="nvim", help="Neovim executable (default: nvim)")
    parser.add_argument("--timeout", type=positive_seconds, default=120, help="seconds per process (default: 120)")
    args = parser.parse_args()
    executable = shutil.which(os.path.expanduser(args.nvim))
    if not executable:
        parser.error(f"Neovim executable was not found or is not executable: {args.nvim}")
    args.nvim = str(Path(executable).resolve())
    if not WORKER.is_file():
        parser.error(f"Lua benchmark worker is missing: {WORKER}")
    if args.baseline:
        args.baseline = args.baseline.expanduser().resolve()
        if not (args.baseline / "plugin" / "latex-conceal.lua").is_file():
            parser.error(f"baseline is not a plugin checkout: {args.baseline}")
    if args.output:
        args.output = args.output.expanduser().resolve()
        if not args.output.parent.is_dir() or args.output.is_dir():
            parser.error(f"output must be a file in an existing directory: {args.output}")
    return args


def process_pid(pid_file):
    try:
        pid = int(pid_file.read_text().strip())
        return pid if pid > 1 and pid != os.getpid() else None
    except (OSError, ValueError):
        return None


def stop_process(process, pid_file):
    """Stop both the launcher group and a Neovim spawned by a wrapper."""
    actual_pid = process_pid(pid_file)

    def send(sig):
        try:
            os.killpg(process.pid, sig)
        except ProcessLookupError:
            pass
        if actual_pid and actual_pid != process.pid:
            try:
                os.kill(actual_pid, sig)
            except ProcessLookupError:
                pass

    send(signal.SIGTERM)
    try:
        process.wait(timeout=0.5)
    except subprocess.TimeoutExpired:
        pass
    send(signal.SIGKILL)
    process.wait(timeout=5)


def diagnostics(terminal, log_file):
    # Escape codes are useful to the PTY but not to a failure report.
    text = terminal.decode("utf-8", errors="replace")
    text = re.sub(r"\x1b\][^\x07]*(?:\x07|\x1b\\)", "", text)
    text = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", text)
    text = "".join(char for char in text if char.isprintable() or char in "\n\t")
    parts = ["Terminal tail:\n" + text[-2000:]] if text.strip() else []
    try:
        with log_file.open("rb") as log:
            log.seek(0, os.SEEK_END)
            log.seek(max(0, log.tell() - 2000))
            tail = log.read().decode("utf-8", errors="replace").strip()
        if tail:
            parts.append("Neovim log tail:\n" + tail)
    except OSError:
        pass
    return "\n".join(parts)


def validate_result(result, args):
    if not isinstance(result, dict):
        raise ValueError("worker result must be a JSON object")
    if result.get("error"):
        raise ValueError(str(result["error"])[-4000:])
    for key in ("lines", "steps", "warmup"):
        if result.get(key) != getattr(args, key):
            raise ValueError(f"worker returned unexpected {key}")
    samples = result.get("samples", {})
    if not isinstance(samples, dict):
        raise ValueError("worker samples must be a JSON object")
    for key in METRICS:
        values = [result.get(key)] if key == "attach_first_paint_ms" else samples.get(key)
        expected = 1 if key == "attach_first_paint_ms" else args.steps
        if not isinstance(values, list) or len(values) != expected:
            raise ValueError(f"worker returned incomplete {key} samples")
        if any(isinstance(value, bool) or not isinstance(value, (int, float))
               or not math.isfinite(value) or value < 0 for value in values):
            raise ValueError(f"worker returned invalid {key} timings")
    validation = result.get("validation")
    if not isinstance(validation, dict) or not validation.get("highlighter"):
        raise ValueError("worker did not validate active Tree-sitter highlighting")
    uis = validation.get("ui")
    if not isinstance(uis, list) or not any(
        isinstance(ui, dict) and ui.get("width") == WIDTH and ui.get("height") == HEIGHT for ui in uis
    ):
        raise ValueError(f"worker did not validate a {WIDTH}x{HEIGHT} terminal UI")


def run_once(args, root, output, log_file):
    master, slave = pty.openpty()
    process = None
    tail = bytearray()
    pid_file = Path(str(output) + ".pid")
    try:
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", HEIGHT, WIDTH, 0, 0))
        env = os.environ.copy()
        if env.get("NVIM_TREESITTER"):
            env["NVIM_TREESITTER"] = str(Path(env["NVIM_TREESITTER"]).expanduser().resolve())
        env.update(
            TERM="xterm-256color",
            NVIM_LOG_FILE=str(log_file),
            CONCEAL_BENCH_ROOT=str(root),
            CONCEAL_BENCH_LINES=str(args.lines),
            CONCEAL_BENCH_STEPS=str(args.steps),
            CONCEAL_BENCH_WARMUP=str(args.warmup),
            CONCEAL_BENCH_OUTPUT=str(output),
            CONCEAL_BENCH_SCRIPT=str(WORKER),
        )
        process = subprocess.Popen(
            [args.nvim, "-u", "NONE", "-i", "NONE", "--noplugin", "-n", "-c",
             "lua dofile(vim.env.CONCEAL_BENCH_SCRIPT)"],
            stdin=slave, stdout=slave, stderr=slave,
            cwd=output.parent, env=env, start_new_session=True,
        )
        os.close(slave)
        slave = None
        deadline = time.monotonic() + args.timeout
        terminal_open = True
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise TimeoutError(f"Neovim exceeded {args.timeout:g} seconds")
            if terminal_open:
                ready, _, _ = select.select([master], [], [], min(0.1, remaining))
                if ready:
                    try:
                        chunk = os.read(master, 65536)
                    except OSError as exc:
                        if exc.errno != errno.EIO:
                            raise
                        chunk = b""
                    if chunk:
                        tail.extend(chunk)
                        del tail[:-TAIL_BYTES]
                    else:
                        terminal_open = False
            elif process.poll() is None:
                time.sleep(min(0.05, remaining))
            if process.poll() is not None:
                break
        if not output.is_file():
            raise RuntimeError(f"Neovim exited with status {process.returncode} without results")
        result = json.loads(output.read_text())
        validate_result(result, args)
        if process.returncode:
            raise RuntimeError(f"Neovim exited with status {process.returncode}")
        return result
    except KeyboardInterrupt:
        if process is not None:
            stop_process(process, pid_file)
        raise
    except (OSError, ValueError, RuntimeError) as exc:
        if process is not None:
            stop_process(process, pid_file)
        detail = diagnostics(tail, log_file)
        raise RuntimeError(f"{exc}" + (f"\n{detail}" if detail else "")) from exc
    finally:
        if slave is not None:
            os.close(slave)
        os.close(master)


def provenance(root):
    info = {"root": str(root), "commit": None, "dirty": None}
    if not shutil.which("git"):
        return info
    try:
        revision = subprocess.run(
            ["git", "-C", str(root), "rev-parse", "HEAD"],
            capture_output=True, text=True, timeout=5, check=True,
        )
        status = subprocess.run(
            ["git", "-C", str(root), "status", "--porcelain"],
            capture_output=True, text=True, timeout=5, check=True,
        )
        info.update(commit=revision.stdout.strip(), dirty=bool(status.stdout.strip()))
    except (OSError, subprocess.SubprocessError):
        pass
    return info


def aggregate(runs):
    return {
        key: statistics.median(
            run[key] if key == "attach_first_paint_ms" else statistics.median(run["samples"][key])
            for run in runs
        )
        for key in METRICS
    }


def print_summary(results, args):
    labels = ["baseline", "current"] if args.baseline else ["current"]
    print("Operation (ms)".ljust(27) + "".join(label.title().rjust(13) for label in labels))
    print("-" * (27 + 13 * len(labels)))
    for key, description in METRICS.items():
        print(description.ljust(27) + "".join(
            f"{results['variants'][label]['median_ms'][key]:13.3f}" for label in labels
        ))
    print(f"\nMedians of {args.runs} fresh runs; {args.steps} samples and {args.warmup} warmups per operation.")
    print(f"{args.lines:,} TeX lines, {WIDTH}x{HEIGHT} PTY; attach excludes Neovim startup.")
    if args.baseline:
        print("Checkout order alternates between runs; measurements run sequentially.")
    if args.output:
        print(f"Full results: {args.output}")


def main():
    args = arguments()
    roots = {"current": ROOT}
    if args.baseline:
        roots = {"baseline": args.baseline, **roots}
    results = {
        "schema_version": 1,
        "method": {
            "lines": args.lines, "runs": args.runs, "steps": args.steps, "warmup": args.warmup,
            "viewport": {"width": WIDTH, "height": HEIGHT},
            "nvim_executable": args.nvim,
            "statistic": "median of per-run medians; attach is the median of fresh-process samples",
            "sequential": True, "alternating_order": bool(args.baseline),
        },
        "variants": {label: {**provenance(root), "runs": []} for label, root in roots.items()},
    }
    try:
        with tempfile.TemporaryDirectory(prefix="latex-conceal-benchmark-") as directory:
            temporary = Path(directory)
            for run in range(args.runs):
                order = list(roots)
                if run % 2:
                    order.reverse()
                for label in order:
                    print(f"Run {run + 1}/{args.runs}: {label}", file=sys.stderr, flush=True)
                    try:
                        result = run_once(
                            args, roots[label], temporary / f"{label}-{run + 1}.json",
                            temporary / f"{label}-{run + 1}.log",
                        )
                    except RuntimeError as exc:
                        raise RuntimeError(f"{label}, run {run + 1}: {exc}") from exc
                    results["variants"][label]["runs"].append(result)
        for variant in results["variants"].values():
            variant["median_ms"] = aggregate(variant["runs"])
        if args.output:
            args.output.write_text(json.dumps(results, indent=2, ensure_ascii=False) + "\n")
        print_summary(results, args)
        return 0
    except KeyboardInterrupt:
        print("Benchmark interrupted; child processes stopped.", file=sys.stderr)
        return 130
    except (OSError, RuntimeError) as exc:
        print(f"Benchmark failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
