-- marked-preview.nvim
--
-- Main plugin file using URL scheme approach (vim-marked style)

local M = {}

-- Global vim reference
local vim = vim

-- Plugin state managed per buffer
local state = {
  watching_buffers = {},
  debounce_timers = {},
  autocommand_group = nil,
}

-- Default configuration
local default_config = {
  filetypes = { "markdown", "mkd", "ghmarkdown", "vimwiki" },
  debounce_delay = 500, -- milliseconds
  auto_start_watching = false, -- Automatically start watching supported filetypes
  focus_on_update = false, -- Bring Marked 2 to foreground on update
  silent_updates = false, -- Reduce notification spam
}

local config = vim.deepcopy(default_config)

-- Pure function to get buffer content
-- @param buf number: Buffer number (defaults to current buffer)
-- @return string: The buffer content
local function get_buffer_content(buf)
  buf = buf or 0
  -- Safety check for valid buffer
  if not vim.api.nvim_buf_is_valid(buf) then
    return ""
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  return table.concat(lines, "\n")
end

-- Pure function to check if filetype is supported
-- @param filetype string: Filetype to check
-- @return boolean: True if filetype is supported
local function is_supported_filetype(filetype)
  filetype = filetype or vim.bo.filetype

  -- If filetype is empty, try to detect from buffer name as fallback
  if filetype == "" then
    local bufname = vim.api.nvim_buf_get_name(0)
    if bufname:match("%.md$") or bufname:match("%.markdown$") then
      filetype = "markdown"
    elseif bufname:match("%.mkd$") then
      filetype = "mkd"
    end
  end

  return config.filetype_set[filetype]
end

-- URL encode text for use in URL parameters
-- From vim-marked: https://github.com/itspriddle/vim-marked
local function url_encode(str)
  -- Use vim-marked's approach with iconv for proper encoding
  local encoded = vim.fn.iconv(str, "latin1", "utf-8")
  encoded = encoded:gsub("[^A-Za-z0-9_.~-]", function(c)
    return string.format("%%%02X", string.byte(c))
  end)
  return encoded
end

-- Check if Marked 2 is running and has a streaming preview window
-- @return boolean: True if streaming preview window exists
local function has_streaming_preview()
  -- Check if Marked 2 is running
  local running_cmd =
    'osascript -e \'tell application "System Events" to get name of every process whose background only is false\' 2>/dev/null | grep -q "Marked 2"'
  local is_running = vim.fn.system(running_cmd) == ""

  if not is_running then
    return false
  end

  -- Check if streaming preview window exists
  local windows_cmd =
    'osascript -e \'tell application "Marked 2" to get name of windows\' 2>/dev/null | grep -q "Streaming Preview"'
  return vim.fn.system(windows_cmd) == ""
end

-- Focus existing streaming preview window
-- @return boolean: Success status
local function focus_streaming_preview()
  local cmd =
    'osascript -e \'tell application "System Events" to tell process "Marked 2" to set frontmost to true\' 2>/dev/null'
  return vim.fn.system(cmd) == ""
end

-- Update Marked 2 preview using URL scheme (vim-marked approach)
-- @param text string: The text to preview
-- @param callback function: Optional callback to run on completion
local function update_marked_preview(text, callback)
  local encoded_text = url_encode(text)
  local url = "x-marked://preview?text=" .. encoded_text

  -- Check if streaming preview already exists
  local has_existing_preview = has_streaming_preview()

  -- Use vim-marked's approach: execute open command directly
  -- Note: Using -g flag to open in background (doesn't bring app to foreground)
  local cmd = string.format("open -g '%s'", url)
  local success = vim.fn.system(cmd) == ""

  -- If we have an existing preview window, focus it instead of creating new ones
  if success and has_existing_preview then
    focus_streaming_preview()
  end

  -- Bring Marked 2 to foreground if configured
  if success and config.focus_on_update then
    vim.fn.system("open -a Marked\\ 2")
  end

  if success and not config.silent_updates then
    if has_existing_preview then
      vim.notify("Preview updated in existing window", vim.log.levels.INFO)
    else
      vim.notify("Preview updated successfully", vim.log.levels.INFO)
    end
  elseif not success then
    vim.notify("Error updating Marked 2 preview", vim.log.levels.ERROR)
  end

  if callback then
    callback(success)
  end

  return success
end

-- Open Marked 2 streaming preview
-- @return boolean: Success status
local function open_marked_app()
  local url = "x-marked://stream/"

  -- Use vim-marked's approach: execute open command directly
  local cmd = string.format("open '%s'", url)
  local success = vim.fn.system(cmd) == ""

  if not success then
    vim.notify("Error opening Marked 2 streaming preview", vim.log.levels.ERROR)
  end

  return success
end

-- Create debounced update function for a buffer
-- @param buf number: Buffer number
-- @return function: Debounced update function
local function create_debounced_update(buf)
  local timer = nil

  return function()
    if timer then
      pcall(timer.close, timer)
    end

    timer = vim.defer_fn(function()
      local content = get_buffer_content(buf)
      update_marked_preview(content, function(success)
        if success then
          -- Optional: add success notification if needed
        end
      end)
      state.debounce_timers[buf] = nil
    end, config.debounce_delay)

    state.debounce_timers[buf] = timer
  end
end

-- Update the Marked 2 preview with the current buffer's content
-- @param buf number: Buffer number (defaults to current buffer)
-- @param callback function: Optional callback to run on completion
-- @return boolean: Success status
function M.update(buf, callback)
  buf = buf or 0
  local content = get_buffer_content(buf)
  return update_marked_preview(content, callback)
end

-- Open Marked 2 streaming preview window
-- @return boolean: Success status
function M.open_marked()
  return open_marked_app()
end

-- Start watching a buffer for changes
-- @param buf number: Buffer number (defaults to current buffer)
-- @return boolean: Success status
function M.start_watching(buf)
  buf = buf or 0

  if state.watching_buffers[buf] then
    vim.notify("Already watching buffer " .. buf, vim.log.levels.INFO)
    return false
  end

  -- In headless mode, filetype detection may not work, so be more permissive
  local filetype = vim.bo[buf].ft
  if filetype == "" then
    -- Allow starting in headless mode for testing
    filetype = "markdown"
  end

  if not is_supported_filetype(filetype) then
    vim.notify("Filetype not supported for buffer " .. buf, vim.log.levels.WARN)
    return false
  end

  -- Create autocommand group if it doesn't exist
  if not state.autocommand_group then
    state.autocommand_group = vim.api.nvim_create_augroup("MarkedPreview", { clear = true })
  end

  local debounced_update = create_debounced_update(buf)

  -- Set up autocommands for text changes
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" }, {
    group = state.autocommand_group,
    buffer = buf,
    callback = debounced_update,
  })

  state.watching_buffers[buf] = true
  vim.notify("Started watching buffer " .. buf .. " for changes", vim.log.levels.INFO)
  return true
end

-- Stop watching a buffer for changes
-- @param buf number: Buffer number (defaults to current buffer)
-- @return boolean: Success status
function M.stop_watching(buf)
  buf = buf or 0

  if not state.watching_buffers[buf] then
    vim.notify("Not currently watching buffer " .. buf, vim.log.levels.INFO)
    return false
  end

  -- Clear autocommands for this buffer
  if state.autocommand_group then
    vim.api.nvim_clear_autocmds({ group = state.autocommand_group, buffer = buf })
  end

  -- Cancel any pending debounce timer for this buffer
  if state.debounce_timers[buf] then
    pcall(state.debounce_timers[buf].close, state.debounce_timers[buf])
    state.debounce_timers[buf] = nil
  end

  state.watching_buffers[buf] = nil
  vim.notify("Stopped watching buffer " .. buf .. " for changes", vim.log.levels.INFO)
  return true
end

-- Check if a buffer is currently being watched
-- @param buf number: Buffer number (defaults to current buffer)
-- @return boolean: True if buffer is being watched
function M.is_watching(buf)
  buf = buf or 0
  return state.watching_buffers[buf] or false
end

-- Setup function with configuration
-- @param user_config table: User configuration
function M.setup(user_config)
  -- Deep merge user config with defaults
  if user_config then
    config = vim.tbl_deep_extend("force", vim.deepcopy(default_config), user_config)
  end

  -- Create a set for faster filetype lookups
  config.filetype_set = {}
  for _, ft in ipairs(config.filetypes) do
    config.filetype_set[ft] = true
  end

  -- Set up filetype detection
  state.autocommand_group = vim.api.nvim_create_augroup("MarkedPreview", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = state.autocommand_group,
    pattern = config.filetypes,
    callback = function(args)
      local buf = args.buf
      if is_supported_filetype(vim.bo[buf].filetype) then
        if config.auto_start_watching then
          M.start_watching(buf)
        else
          vim.notify("Marked preview available for " .. vim.bo.filetype, vim.log.levels.INFO)
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufDelete", {
    group = state.autocommand_group,
    pattern = "*",
    callback = function(args)
      if M.is_watching(args.buf) then
        M.stop_watching(args.buf)
      end
    end,
  })

  -- Setup commands module
  require("marked-preview.commands").setup()
end

return M
