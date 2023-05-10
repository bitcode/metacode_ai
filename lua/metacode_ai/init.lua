local M = {}

local telescope = require('telescope')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local sorters = require('telescope.sorters')
local conf = require("telescope.config").values


local function get_user_question(on_done, opts)
  local config_opts = vim.tbl_extend("force", {prompt_title = "Enter your question"}, opts)

  pickers.new(config_opts, {
    prompt_title = config_opts.prompt_title,
    finder = finders.new_table {
      results = {},
      entry_maker = function(entry)
        return {
          display = entry,
          ordinal = entry,
          value = entry,
        }
      end,
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)

    local function on_select(prompt_bufnr, on_done)
  local selection = action_state.get_selected_entry()
  if not selection then
    -- If there is no selection, just return
    return
  end
  print("User question:", selection.value) -- Added for debugging
  -- Call on_done with the selected value without closing the window
  on_done(selection.value)
end

      map("i", "<CR>", on_select)
      map("n", "<CR>", on_select)

      return true
    end,
  }):find()
end

local function query_metacode_ai(package_name, package_version, user_question)
	print("Querying MetaCode AI with:", package_name, package_version, user_question) -- Added for debugging
  local result = vim.api.nvim_call_function("MetaCodeAIQuery", {package_name, package_version, user_question})
  return result
end

function M.metacode_ai_picker(opts)
  opts = opts or {}

  local finder = finders.new_table {
    results = {},
    entry_maker = function(entry)
      return {
        display = entry,
        ordinal = entry,
        value = entry,
      }
    end,
  }

  local function update_finder_with_answer(answer)
    finder:clear()
    finder:add_entry(answer)
  end

  get_user_question(function(user_question)
    local package_name = vim.g.metacode_ai_package_name or "default_package_name"
    local package_version = vim.g.metacode_ai_package_version or "default_package_version"

    local answer = query_metacode_ai(package_name, package_version, user_question)
    update_finder_with_answer(answer)
  end, opts)

  local default_opts = {
  prompt_title = 'MetaCode AI Answer',
  layout_strategy = "vertical",
  layout_config = {
    prompt_position = "top",
    preview_height = 0.5,
  },
}

  local config_opts = vim.tbl_extend("force", default_opts, opts)

  local function on_select(prompt_bufnr, on_done)
	   print("on_select called") -- Added for debugging
    local selection = action_state.get_selected_entry()
    if not selection then
      -- If there is no selection, just return
      return
    end
    -- Call on_done with the selected value without closing the window
    on_done(selection.value)
  end

  pickers.new(config_opts, {
    prompt_title = config_opts.prompt_title,
    finder = finder,
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      map("i", "<CR>", function() on_select(prompt_bufnr, update_finder_with_answer) end)
      map("n", "<CR>", function() on_select(prompt_bufnr, update_finder_with_answer) end)
      return true
    end,
  }):find()
end

return M
