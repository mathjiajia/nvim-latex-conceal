-- What the renderer already knows while it evaluates the conceal query, shared
-- with the query's predicates and directives. Asking Tree-sitter for an
-- ancestor walks down from the root of the tree, and reading node text is an
-- API call; both would otherwise happen several times per captured node.
--
-- The query yields captures in document order, so the `@_math`, `@_text` and
-- `@_label` regions around a node have all been recorded when the node's own
-- predicates run. `start`, `finish` and `kind` hold the regions still open at
-- the last recorded one, innermost last, as byte offsets.
local M = {
	math = 1,
	text = 2,
	label = 3,
	-- Regions are known for nodes starting in rows [first, last); none are
	-- while `last` is zero, so that other users of the query ask Tree-sitter.
	first = 0,
	last = 0,
	depth = 0,
	start = {},
	finish = {},
	kind = {},
	-- The buffer being collected and its lines by row.
	buf = nil,
	lines = nil,
}

M.captures = { _math = M.math, _text = M.text, _label = M.label }

-- Regions are nested or disjoint and arrive in document order, so one that
-- ends before the next begins can be dropped.
---@param kind integer
---@param node TSNode
function M.record(kind, node)
	local _, _, start, _, _, finish = node:range(true)
	local depth, finishes = M.depth, M.finish
	while depth > 0 and finishes[depth] <= start do
		depth = depth - 1
	end
	depth = depth + 1
	M.start[depth], finishes[depth], M.kind[depth] = start, finish, kind
	M.depth = depth
end

return M
