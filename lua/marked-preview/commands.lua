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
  local commands = {
    MarkedPreviewUpdate = { func = "update", desc = "Update Marked 2 preview with current buffer content" },
    MarkedPreviewOpen = { func = "open_marked", desc = "Open Marked 2 streaming preview window" },
    MarkedPreviewStart = { func = "start_watching", desc = "Start watching current buffer for automatic updates" },
    MarkedPreviewStop = { func = "stop_watching", desc = "Stop watching current buffer for changes" },
  }

  for name, cmd in pairs(commands) do
    vim.api.nvim_create_user_command(name, function()
      require("marked-preview")[cmd.func]()
    end, { desc = cmd.desc })
  end
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
