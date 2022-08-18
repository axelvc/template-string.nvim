local ts_utils = require("nvim-treesitter.ts_utils")

local M = {}

M.quote = {
	SINGLE = [[']],
	DOUBLE = [["]],
	BACKTICK = [[`]],
}

--- NOTE: this doesn't detect the last redo
function M.is_undo_or_redo()
	local tree = vim.fn.undotree()

	return tree.seq_cur ~= tree.seq_last
end

---find the closest outward string node from the cursor and return if found
function M.get_string_node()
	local node = ts_utils.get_node_at_cursor()
	local valid_nodes = { "string", "template_string" }

	---depth limited to avoid unnecesary depth search
	local max_depth = 3
	for _ = 1, max_depth do
		-- stylua: ignore
		if not node then return end

		if vim.tbl_contains(valid_nodes, node:type()) then
			return node
		end

		node = node:parent()
	end
end

---@param str	string
---@return boolean
function M.is_multiline(str)
	return str:match("\n") ~= nil
end

---@param str string
---@return boolean
function M.has_template_string(str)
	return str:match("${.*}") ~= nil
end

---know if given node must be handled as part of a JSX attribute
---@param node userdata tsnode
---@return boolean
function M.is_jsx_node(node)
	local parent_types = {
		string = "jsx_attribute",
		template_string = "jsx_expression",
	}

	return parent_types[node:type()] == node:parent():type()
end

---@param str string
---@param new_quote string
---@return string
function M.replace_quotes(str, new_quote)
	return new_quote .. str:sub(2, -2) .. new_quote
end

---@param node userdata tsnode
---@param buf buffer id
---@param str string new string
function M.replace_node_text(node, buf, str)
	local sr, sc, er, ec = node:range()

	vim.api.nvim_buf_set_text(buf, sr, sc, er, ec, { str })
end

---move cursor relative to the current position
---@param pos table (row, col) tuple
function M.move_cursor(pos)
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))

	pos[1] = pos[1] + row
	pos[2] = pos[2] + col

	vim.api.nvim_win_set_cursor(0, pos)
end

return M
