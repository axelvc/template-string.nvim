local U = require("template-string.utils")
local C = require("template-string.config")
local quote = require("template-string.quote_string")
local template = require("template-string.template_string")
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local M = {}

function M.handle_type()
	local node = U.get_string_node()

	-- stylua: ignore
	if not node then return end

	local buf = vim.api.nvim_win_get_buf(0)

	if node:type() == "string" then
		quote.handle_quote_string(node, buf)
	elseif C.options.remove_template_string then
		template.handle_template_string(node, buf)
	end
end

function M.setup(options)
	C.options = vim.tbl_extend("force", C.options, options or {})
	M.group = augroup("TemplateString", { clear = true })

	autocmd("FileType", {
		group = M.group,
		pattern = "*",
		callback = function(ev)
			if not vim.tbl_contains(C.options.filetypes, ev.match) then
				return
			end

			autocmd({ "TextChanged", "TextChangedI" }, {
				group = M.group,
				buffer = ev.buf,
				callback = M.handle_type,
			})
		end,
	})
end

return M
