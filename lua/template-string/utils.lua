local M = {}

M.quote = {
	SINGLE = [[']],
	DOUBLE = [["]],
	BACKTICK = [[`]],
}

M.get_cusor_node = vim.treesitter.get_node or require("nvim-treesitter.ts_utils").get_node_at_cursor

--- NOTE: this doesn't detect the last redo
function M.is_undo_or_redo()
	local tree = vim.fn.undotree()

	return tree.seq_cur ~= tree.seq_last
end

---find the closest outward string node from the cursor and return if found
---@param valid_nodes string[]
function M.get_string_node(valid_nodes)
	local node = M.get_cusor_node()

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

---@param node userdata tsnode
---@param buf number bufnr
---@param new_text string[] list of replacements
function M.replace_node_text(node, buf, new_text)
	local sr, sc, er, ec = node:range()

	vim.api.nvim_buf_set_text(buf, sr, sc, er, ec, new_text)
end

---move cursor relative to the current position
---@param pos table (row, col) tuple
function M.move_cursor(pos)
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))

	pos[1] = pos[1] + row
	pos[2] = pos[2] + col

	vim.api.nvim_win_set_cursor(0, pos)
end

---@param node userdata tsnode
---@return boolean
function M.has_child_nodes(node)
	for child in node:iter_children() do
		if child:named() and child:type() ~= "escape_sequence" then
			return true
		end
	end

	return false
end

return M
