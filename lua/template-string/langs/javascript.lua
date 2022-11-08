local U = require("template-string.utils")
local C = require("template-string.config")

local M = {}

---know if the given node is part of a tag function
---e.g - css`some text`
---@param node userdata tsnode
---@return boolean
function M.is_tag_function(node)
  return node:parent():type() == "call_expression"
end

---know if the given node has manual backticks
---considering manual backticks when never were template substitutions (${})
---@param node userdata tsnode
---@return boolean
function M.has_manual_backticks(node)
  local child_count = node:named_child_count()

  return child_count == 0
end

---@param text string
---@return boolean
function M.has_quotes(text)
  return text:match("[\"']") ~= nil
end

---@param text string
---@return boolean
function M.is_already_template(text)
  return text:match("^{?`.*`}?$") ~= nil
end

---@param text string
---@return boolean
function M.has_substitutions(text)
  return text:match("${.*}") ~= nil
end

---know if given node must be handled as part of a JSX attribute
---@param node userdata tsnode
---@return boolean
function M.is_jsx_node(node)
  local parent_types = {
    string = "jsx_attribute",
    template_string = "jsx_expression",
  }

  return parent_types[node:type()] == node:parent():type()
end

---@param text string
---@param new_quote string
---@return string
function M.replace_quotes(text, new_quote)
  return new_quote .. text:sub(2, -2) .. new_quote
end

---@param node userdata tsnode
---@param buf number bufnr
function M.handle_quote_string(node, buf)
  local text = vim.treesitter.get_node_text(node, buf)

  if U.is_undo_or_redo()
      or not M.has_substitutions(text)
      -- ignore last redo
      or M.is_already_template(text)
      -- ignore multiline quote string (treesitter could detect quote string in bad syntax)
      or U.is_multiline(text)
  then
    return
  end

  local new_text = M.replace_quotes(text, U.quote.BACKTICK)

  -- add brackets if it's jsx attribute
  if C.options.jsx_brackets and M.is_jsx_node(node) then
    new_text = "{" .. new_text .. "}"

    -- move the cursor to stay in the same position after adding brackets
    U.move_cursor({ 0, 1 })
  end

  U.replace_node_text(node, buf, new_text)
end

---@param node userdata tsnode
---@param buf number bufnr
function M.handle_template_string(node, buf)
  local text = vim.treesitter.get_node_text(node, buf)

  -- backticks must be kept on these cases
  if M.has_substitutions(text)
      or M.has_quotes(text)
      or M.has_manual_backticks(node)
      or M.is_tag_function(node)
      or U.is_multiline(text)
  then
    return
  end

  local quotes = C.options.restore_quotes.normal

  -- replace node with its parent to remove brackets when replacing text
  if C.options.jsx_brackets and M.is_jsx_node(node) then
    node = node:parent()
    quotes = C.options.restore_quotes.jsx

    -- move the cursor to stay in the same position after removing brackets
    U.move_cursor({ 0, -1 })
  end

  local new_text = M.replace_quotes(text, quotes)
  U.replace_node_text(node, buf, new_text)
end

function M.on_type()
  local node = U.get_string_node()

  -- stylua: ignore
  if not node then return end

  local buf = vim.api.nvim_win_get_buf(0)

  if node:type() == "string" then
    M.handle_quote_string(node, buf)
  elseif C.options.remove_template_string then
    M.handle_template_string(node, buf)
  end
end

return M
