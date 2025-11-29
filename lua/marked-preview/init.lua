-- marked-preview.nvim
--
-- Main plugin file

local M = {}

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
}

local config = vim.deepcopy(default_config)

-- Pure function to get buffer content
-- @param buf number: Buffer number (defaults to current buffer)
-- @return string: The buffer content
local function get_buffer_content(buf)
  buf = buf or 0
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  return table.concat(lines, "\n")
end

-- Pure function to check if filetype is supported
-- @param filetype string: Filetype to check
-- @return boolean: True if filetype is supported
local function is_supported_filetype(filetype)
  filetype = filetype or vim.bo.filetype
  return vim.tbl_contains(config.filetypes, filetype)
end

-- Copy text to the named clipboard
-- @param text string: The text to copy
-- @return boolean: Success status
local function copy_to_named_clipboard(text)
  local cmd = "pbcopy -pboard mkStreamingPreview"
  local success = false

  local proc = vim.fn.jobstart(cmd, {
    on_exit = function(_, code)
      if code == 0 then
        success = true
      else
        vim.notify("Error copying to clipboard: " .. cmd, vim.log.levels.ERROR)
      end
    end,
  })

  if proc <= 0 then
    vim.notify("Failed to start clipboard process", vim.log.levels.ERROR)
    return false
  end

  vim.fn.chanwrite(proc, text)
  vim.fn.chanclose(proc, "stdin")

  -- Wait briefly for process completion
  vim.wait(100, function()
    return success
  end, 10)

  return success
end

-- Open Marked 2 streaming preview
-- @return boolean: Success status
local function open_marked_app()
  local url = "x-marked://stream/"
  local success = false

  local proc = vim.fn.jobstart({ "open", url }, {
    detach = true,
    on_exit = function(_, code)
      if code == 0 then
        success = true
      else
        vim.notify("Error opening Marked 2: " .. url, vim.log.levels.ERROR)
      end
    end,
  })

  if proc <= 0 then
    vim.notify("Failed to start Marked 2", vim.log.levels.ERROR)
    return false
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
      timer:close()
    end

    timer = vim.defer_fn(function()
      local content = get_buffer_content(buf)
      copy_to_named_clipboard(content)
      state.debounce_timers[buf] = nil
    end, config.debounce_delay)

    state.debounce_timers[buf] = timer
  end
end

-- Update the Marked 2 preview with the current buffer's content
-- @param buf number: Buffer number (defaults to current buffer)
-- @return boolean: Success status
function M.update(buf)
  buf = buf or 0
  local content = get_buffer_content(buf)
  return copy_to_named_clipboard(content)
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

  if not is_supported_filetype(vim.bo[buf].filetype) then
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
    state.debounce_timers[buf]:close()
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

  -- Set up filetype detection
  state.autocommand_group = vim.api.nvim_create_augroup("MarkedPreview", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = state.autocommand_group,
    pattern = config.filetypes,
    callback = function(args)
      local buf = args.buf
      if is_supported_filetype(vim.bo[buf].filetype) then
        vim.notify("Marked preview available for " .. vim.bo.filetype, vim.log.levels.INFO)
      end
    end,
  })
end

return M
