local ts_utils = require("nvim-treesitter.ts_utils")
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local M = {}

M.options = {
	filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
	jsx_brackets = true,
	remove_template_string = false,
}

M.group = augroup("TemplateString", { clear = true })

function M.get_string_node()
	local node = ts_utils.get_node_at_cursor()

	-- stylua: ignore
	if not node then return end

	local type = node:type()

	if type == "string" then
		return node
	elseif type == "string_fragment" then
		return node:parent()
	elseif type == "template_string" then
		return node
	end
end

function M.handle_string(node, buf)
	local text = vim.treesitter.get_node_text(node, buf)

	-- stylua: ignore
	if not text:match("${.*}") then return end

	-- change quotes to backticks
	local new_text = "`" .. text:sub(2, -2) .. "`"

	-- add brackets if it's jsx attribute
	if M.options.jsx_brackets and node:parent():type() == "jsx_attribute" then
		local row, col = unpack(vim.api.nvim_win_get_cursor(0))

		new_text = "{" .. new_text .. "}"
		-- moving the cursor to stay in the same position after adding brackets
		vim.api.nvim_win_set_cursor(0, { row, col + 1 })
	end

	-- replace text with template string
	local sr, sc, er, ec = node:range()
	vim.api.nvim_buf_set_text(buf, sr, sc, er, ec, { new_text })
end

function M.handle_template(node, buf)
	local text = vim.treesitter.get_node_text(node, buf)

	if text:match("${.*}") or text:match("\n") or node:parent():type() == "call_expression" then
		return
	end

	-- change backticks to quotes
	-- TODO: detect which quotes are used in the file
	local new_text = "'" .. text:sub(2, -2) .. "'"

	if node:parent():type() == "jsx_expression" then
		local row, col = unpack(vim.api.nvim_win_get_cursor(0))

		-- replace node with parent to remove jsx brackets
		node = node:parent()

		-- moving the cursor to stay in the same position after adding brackets
		vim.api.nvim_win_set_cursor(0, { row, col - 1 })
	end

	-- replace text with template string
	local sr, sc, er, ec = node:range()
	vim.api.nvim_buf_set_text(buf, sr, sc, er, ec, { new_text })
end

function M.handle_type()
	local node = M.get_string_node()

	-- stylua: ignore
	if not node then return end

	local buf = vim.api.nvim_win_get_buf(0)

	if node:type() == "string" then
		M.handle_string(node, buf)
	elseif M.options.remove_template_string then
		M.handle_template(node, buf)
	end
end

function M.setup(options)
	M.options = vim.tbl_extend("force", M.options, options or {})

	autocmd("FileType", {
		group = M.group,
		pattern = "*",
		callback = function(ev)
			if not vim.tbl_contains(M.options.filetypes, ev.match) then
				return
			end

			autocmd("TextChangedI", {
				group = M.group,
				buffer = ev.buf,
				callback = M.handle_type,
			})
		end,
	})
end

return M
