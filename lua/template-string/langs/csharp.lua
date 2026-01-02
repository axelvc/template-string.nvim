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

	local bad = M.before_quotes(node, text) or U.is_undo_or_redo()
	local is_literal = M.is_string_literal(text)
	local interpolated = M.has_interpolation(text)

	local should_add_dollar = not bad and is_literal and interpolated
	local should_del_dollar = not bad and C.options.remove_template_string and not is_literal and not interpolated

	if should_add_dollar then
		M.add_dollar(node, buf, text)
	elseif should_del_dollar then
		-- NOTE: csharp parser parses empty interpolation as ERROR
		-- so when you delete all interpolated values within {}
		-- it will not reach here because we don't get a valid node
		-- so the $ prefix will not be deleted in this case
		-- However it's strange that it works when only one empty interpolation were presented
		-- but fails on multiple empty interpolations
		M.del_dollar(node, buf, text)
	end
end

---@param node TSNode
---@param buf number
---@param text string
function M.add_dollar(node, buf, text)
	-- "{foo}" -> $"{foo}"
	-- @"{foo}" -> $@"{foo}"
	local new_text = "$" .. text
	local lines = U.is_multiline(text) and M.get_text_lines(new_text) or { new_text }

	U.replace_node_text(node, buf, lines)

	if not U.is_multiline(text) or M.is_cursor_in_first_row(node) then
		U.move_cursor({ 0, 1 })
	end
end

---@param node TSNode
---@param buf number
---@param text string
function M.del_dollar(node, buf, text)
	-- $"foo" -> "foo"
	-- @$"foo" -> @"foo"
	local prefix = text:match('^([%$@]+)"')
	local new_text = prefix:gsub("%$", "") .. text:sub(#prefix + 1)
	local is_multiline = U.is_multiline(text)
	local lines = is_multiline and M.get_text_lines(new_text) or { new_text }

	if not is_multiline or M.is_cursor_in_first_row(node) then
		U.move_cursor({ 0, -1 })
	end

	U.replace_node_text(node, buf, lines)
end

---@param node TSNode
---@param text string
---@return boolean
function M.before_quotes(node, text)
	local node_row, node_col = node:range()
	local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
	local first_quote_col = text:find('"') + node_col

	cursor_row = cursor_row - 1

	return node_row == cursor_row and cursor_col < first_quote_col
end
---@param text string
---@return boolean
function M.is_string_literal(text)
	local prefix = text:match('^([%$@]+)"')
	return not prefix or prefix:find("%$") == nil
end

---@param text string
---@return boolean
function M.has_interpolation(text)
	-- remove escaped brackets and ignore nested interpolations
	return text:gsub("{{", ""):gsub("}}", ""):match("{[^{}][^{}]-}") ~= nil
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
