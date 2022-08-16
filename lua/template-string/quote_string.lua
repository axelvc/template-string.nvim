local U = require("template-string.utils")
local C = require("template-string.config")
local M = {}

function M.handle_quote_string(node, buf)
	local text = vim.treesitter.get_node_text(node, buf)

	-- stylua: ignore
	if not U.has_template_string(text) then return end

	local new_text = U.replace_quotes(text, "`")

	-- add brackets if it's jsx attribute
	if C.options.jsx_brackets and U.is_jsx_node(node) then
		new_text = "{" .. new_text .. "}"

		-- move the cursor to stay in the same position after adding brackets
		U.move_cursor({ 0, 1 })
	end

	U.replace_node_text(node, buf, new_text)
end

return M
