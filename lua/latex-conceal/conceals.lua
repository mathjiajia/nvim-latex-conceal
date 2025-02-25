local M = {}

local function read_query_files(filenames)
	local contents = ""

	for _, filename in ipairs(filenames) do
		local file, err = io.open(filename, "r")
		local payload = ""
		if file then
			payload = file:read("*a")
			io.close(file)
		else
			error(err)
		end
		contents = contents .. "\n" .. payload
	end
	return contents
end

---@param match TSMatch
---@param pred string[]
---@return boolean
local function hasgrandparent(match, _, _, pred)
	local nodes = match[pred[2]]
	if not nodes or #nodes == 0 then
		return true
	end

	local types = { unpack(pred, 3) }
	for _, node in ipairs(nodes) do
		if vim.list_contains(types, node:parent():parent():type()) then
			return true
		end
	end
	return false
end

---@param match TSMatch
---@param pred string[]
local function setpairs(match, _, source, pred, metadata)
	-- (#set-pairs! @aa key list)
	local id = pred[2]
	local key = pred[3]
	local nodes = match[id]
	if not nodes or #nodes == 0 then
		return
	end

	for _, node in ipairs(nodes) do
		local node_text = vim.treesitter.get_node_text(node, source)
		-- if metadata[capture_id] and metadata[capture_id].range then
		-- 	local sr, sc, er, ec = unpack(metadata[capture_id].range)
		-- 	node_text = vim.api.nvim_buf_get_text(source, sr, sc, er, ec, {})[1]
		-- end
		for i = 4, #pred, 2 do
			if node_text == pred[i] then
				metadata[key] = pred[i + 1]
				break
			end
		end
	end
end

local function load_queries(args)
	local filenames = vim.treesitter.query.get_files("latex", "highlights")
	vim.treesitter.query.add_predicate("has-grandparent?", hasgrandparent, { force = true })
	vim.treesitter.query.add_directive("set-pairs!", setpairs, { force = true, all = true })
	for _, name in ipairs(args.enabled) do
		local files = vim.api.nvim_get_runtime_file("queries/latex/conceal_" .. name .. ".scm", true)
		for _, file in ipairs(files) do
			table.insert(filenames, file)
		end
	end
	local strings = read_query_files(filenames) or ""
	local added_query_start = [[(generic_command
    command: ((command_name) @conceal
    (#any-of? @conceal
	]]
	local added_query_middle = [[
	))
	(#set-pairs! @conceal conceal
	]]
	local added_query_end = "))"
	for command, conceal in pairs(args.add) do
		added_query_start = added_query_start .. '"\\\\' .. command .. '" '
		added_query_middle = added_query_middle .. '"\\\\' .. command .. '" "' .. conceal .. '" '
	end
	if next(args.add) then
		strings = strings .. added_query_start .. added_query_middle .. added_query_end
	end
	vim.treesitter.query.set("latex", "highlights", strings)
end

function M.init(args)
	if args.enabled == false then
		return
	end
	load_queries(args)
end

return M
