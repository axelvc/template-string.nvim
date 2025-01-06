local U = require("template-string.utils")
local C = require("template-string.config")
local M = {}

function M.on_type()
	local node = U.get_string_node({
		"string_literal",
		"raw_string_literal",
		"verbatim_string_literal",
		"interpolated_string_expression",
	})
	if not node then
		return
	end
	local buf = vim.api.nvim_win_get_buf(0)
	local text = vim.treesitter.get_node_text(node, buf)

	if M.is_string_literal(text) and M.can_interpolate(text) then
		-- "{foo}" -> $"{foo}"
		-- @"{foo}" -> $@"{foo}"
		local new_text = "$" .. text
		local lines = U.is_multiline(text) and M.get_text_lines(new_text) or { new_text }
		U.replace_node_text(node, buf, lines)
		if not U.is_multiline(text) or M.is_cursor_in_first_row(node) then
			U.move_cursor({ 0, 1 })
		end
	elseif C.options.remove_template_string and not M.is_string_literal(text) and not M.can_interpolate(text) then
		-- $"foo" -> "foo"
		local new_text = text:sub(2)
		local is_multiline = U.is_multiline(text)
		local lines = is_multiline and M.get_text_lines(new_text) or { new_text }
		if not is_multiline or M.is_cursor_in_first_row(node) then
			U.move_cursor({ 0, -1 })
		end
		U.replace_node_text(node, buf, lines)
	end
end

---@param text string
function M.is_string_literal(text)
	return text:match("^%$") == nil
end

---@param text string
---@return boolean
function M.can_interpolate(text)
	-- remove scaped brackets and ignore nested interpolations
	return text:gsub("{{", ""):gsub("}}", ""):match("{.-}") ~= nil
end

---convert a single multiline string to a table of strings
---@param text string
---@return string[]
function M.get_text_lines(text)
	return vim.split(text, "\n", {})
end

---know if the cursor row is the same as the first row of a multiline node
---@param node TSNode
function M.is_cursor_in_first_row(node)
	local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1
	local node_row = node:range()

	return cursor_row == node_row
end

return M
