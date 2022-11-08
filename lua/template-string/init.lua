local C = require("template-string.config")
local handler = require("template-string.langs")
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local M = {}

function M.handle_text_changed()
	handler.js.on_type()
end

function M.setup(options)
	-- update config
	C.options = vim.tbl_extend("force", C.options, options or {})

	-- set autocmd
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
				callback = M.handle_text_changed,
			})
		end,
	})
end

return M
