local U = require("template-string.utils")
local C = require("template-string.config")

local M = {}

---@param text string
---@return boolean
function M.is_quote_string(text)
  local prefix = text:match("^([rf]+)[\"']")
  return not prefix or prefix:find("f") == nil
end

---@param text string
---@return boolean
function M.has_interpolations(text)
  -- remove scaped brackets and ignore nested interpolations
  return text:gsub("{{", ""):gsub("}}", ""):match("{[^{}][^{}]-}") ~= nil
end

---know if the given node is part of a "format" method
---e.g: "some text".format()
---@param node userdata tsnode
---@param buf number bufnr
---@return boolean
function M.has_format_method(node, buf)
  local parent = node:parent()

  if parent:type() ~= "attribute" then
    return false
  end

  local sibling_node = node:next_named_sibling()
  local sibling_text = vim.treesitter.get_node_text(sibling_node, buf)

  return sibling_text:match("format") ~= nil
end

---convert a single multiline string to a table of strings
---@param text string
---@return string[]
function M.get_text_lines(text)
  return vim.split(text, "\n", {})
end

---know if the cursor row is the same as the first row of a multiline node
---@param node userdata tsnode
function M.is_cursor_in_first_row(node)
  local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local node_row = node:range()

  return cursor_row == node_row
end

---know if the cursor column is before at first string quote
---@param node userdata tsnode
---@param text string
---@return boolean
function M.before_quotes(node, text)
  local node_row, node_col = node:range()
  local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
  local first_quote_col = text:find("['\"]") + node_col

  cursor_row = cursor_row - 1

  return node_row == cursor_row and cursor_col < first_quote_col
end

---@param node userdata tsnode
---@param buf number bufnr
---@param text string
function M.handle_quote_string(node, buf, text)
  -- ignore cases
  if U.is_undo_or_redo()
      or M.has_format_method(node, buf)
      or not M.has_interpolations(text)
      or M.before_quotes(node, text)
  then
    return
  end

  -- convert to f-string
  local new_text = "f" .. text
  local lines = U.is_multiline(text) and M.get_text_lines(new_text) or { new_text }

  U.replace_node_text(node, buf, lines)

  if not U.is_multiline(text) or M.is_cursor_in_first_row(node) then
    U.move_cursor({ 0, 1 })
  end
end

---@param node userdata tsnode
---@param buf number bufnr
---@param text string
function M.handle_f_string(node, buf, text)
  -- ignore cases
  if U.is_undo_or_redo()
      or M.has_interpolations(text)
      or M.before_quotes(node, text)
      or not U.has_child_nodes(node) -- is a manual f-string
  then
    return
  end

  -- convert to quote string
  local prefix = text:match("^([rf]+)[\"']")
  local new_text = prefix:gsub("f", "") .. text:sub(#prefix + 1)
  local lines = U.is_multiline(text) and M.get_text_lines(new_text) or { new_text }

  if not U.is_multiline(text) or M.is_cursor_in_first_row(node) then
    U.move_cursor({ 0, -1 })
  end

  U.replace_node_text(node, buf, lines)
end

function M.on_type()
  local node = U.get_string_node({ "string" })

  -- stylua: ignore
  if not node then return end

  local buf = vim.api.nvim_win_get_buf(0)
  local text = vim.treesitter.get_node_text(node, buf)

  if M.is_quote_string(text) then
    M.handle_quote_string(node, buf, text)
  elseif C.options.remove_template_string then
    M.handle_f_string(node, buf, text)
  end
end

return M
