-- Asking Tree-sitter for an ancestor walks down from the root of the tree, and
-- reading node text is an API call.
local M = {
	math = 1,
	text = 2,
	label = 3,
	first = 0,
	last = 0,
	depth = 0,
	start = {},
	finish = {},
	kind = {},
	buf = nil,
	lines = nil,
}

M.captures = { _math = M.math, _text = M.text, _label = M.label }

-- Regions are nested or disjoint and arrive in document order.
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
