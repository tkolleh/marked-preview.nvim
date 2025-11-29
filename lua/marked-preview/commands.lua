-- marked-preview.nvim - Plugin commands in Lua
--
-- This file sets up user commands for the marked-preview plugin

local M = {}

-- Global vim reference
local vim = vim

-- Plugin loaded flag
M.loaded = false

-- Generate help tags if available
local function generate_help_tags()
  if vim.fn.exists(":helptags") > 0 then
    vim.cmd("silent! helptags ALL")
  end
end

-- Define user commands
local function define_commands()
  vim.api.nvim_create_user_command("MarkedPreviewUpdate", function()
    require("marked-preview").update()
  end, { desc = "Update Marked 2 preview with current buffer content" })

  vim.api.nvim_create_user_command("MarkedPreviewOpen", function()
    require("marked-preview").open_marked()
  end, { desc = "Open Marked 2 streaming preview window" })

  vim.api.nvim_create_user_command("MarkedPreviewStart", function()
    require("marked-preview").start_watching()
  end, { desc = "Start watching current buffer for automatic updates" })

  vim.api.nvim_create_user_command("MarkedPreviewStop", function()
    require("marked-preview").stop_watching()
  end, { desc = "Stop watching current buffer for changes" })
end

-- Setup function for commands module
function M.setup()
  if M.loaded then
    return
  end

  -- Set plugin loaded flag
  vim.g.loaded_marked_preview = 1
  M.loaded = true

  -- Generate help tags
  generate_help_tags()

  -- Define commands
  define_commands()
end

return M
