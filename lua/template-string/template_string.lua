local U = require("template-string.utils")
local C = require("template-string.config")
local M = {}

---@param str	string
---@return boolean
function M.is_multiline(str)
	return str:match("\n") ~= nil
end

---return if the given string node is part of a tag function
---e.g - css`some text`
---@param node userdata tsnode
---@return boolean
function M.is_tag_function(node)
	return node:parent():type() == "call_expression"
end

function M.handle_template_string(node, buf)
	local text = vim.treesitter.get_node_text(node, buf)

	-- backticks must be kept on these cases
	if U.has_template_string(text) or M.is_multiline(text) or M.is_tag_function(node) then
		return
	end

	local quotes = C.options.restore_quotes.normal

	-- replace node with its parent to remove brackets when replacing text
	if C.options.jsx_brackets and U.is_jsx_node(node) then
		node = node:parent()
		quotes = C.options.restore_quotes.jsx

		-- move the cursor to stay in the same position after removing brackets
		U.move_cursor({ 0, -1 })
	end

	local new_text = U.replace_quotes(text, quotes)
	U.replace_node_text(node, buf, new_text)
end

return M
