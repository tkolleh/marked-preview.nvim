-- marked-preview.nvim - Plugin loader in Lua
--
-- This file loads the plugin and sets up user commands

-- Check if plugin is already loaded
if vim.g.loaded_marked_preview then
  return
end

-- Set plugin loaded flag
vim.g.loaded_marked_preview = 1

-- Setup the plugin
require("marked-preview").setup()
