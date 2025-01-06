local C = require("template-string.config")
local handler = require("template-string.langs")
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local M = {}

function M.handle_text_changed()
	local filetype = vim.opt.filetype:get()

	if filetype == "python" then
		handler.python.on_type()
  elseif filetype == 'cs' then
    handler.csharp.on_type()
	else
		handler.js.on_type()
	end
end

function M.enable()
	C.state.enabled = true
end

function M.disable()
	C.state.enabled = false
end

function M.toggle()
	C.state.enabled = not C.state.enabled
end

function M.setup(options)
	-- update config
	C.options = vim.tbl_extend("force", C.options, options or {})

	-- set autocmd
	M.group = augroup("TemplateString", { clear = true })

	vim.api.nvim_create_user_command("TemplateString", function(opts)
		local params = vim.split(opts.args, "%s+", { trimempty = true })

		local action_name = params[1]

		if action_name == "enable" then
			M.enable()
		elseif action_name == "disable" then
			M.disable()
		elseif action_name == "toggle" then
			M.toggle()
		end
	end, {
		bang = true,
		nargs = "?",
		complete = function(_, cmd_line)
			local cmds = { "enable", "disable", "toggle" }
			return cmds
		end,
	})

	autocmd("FileType", {
		group = M.group,
		pattern = C.options.filetypes,
		callback = function(ev)
			vim.api.nvim_clear_autocmds({
				event = { "TextChanged", "TextChangedI" },
				buffer = ev.buf,
				group = M.group,
			})

			autocmd({ "TextChanged", "TextChangedI" }, {
				group = M.group,
				buffer = ev.buf,
				callback = function()
					if not C.state.enabled then
						return
					end
					M.handle_text_changed()
				end,
			})
		end,
	})
end

return M
