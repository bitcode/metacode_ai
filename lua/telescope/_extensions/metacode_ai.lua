-- Check if telescope is installed, otherwise throw an error
if not pcall(require, 'telescope') then
  error('This extension requires nvim-telescope/telescope.nvim')
end

-- Import required telescope modules
local telescope = require('telescope')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local sorters = require('telescope.sorters')

-- Create a table to store the metacode_ai functions
local metacode_ai = {}

-- Function to get the user's question using telescope's picker
local function get_user_question(on_done, opts)
  -- Merge the default options with the provided options
  local config_opts = vim.tbl_extend("force", {prompt_title = "Enter your question"}, opts)

  -- Create a new picker with the given options
  pickers.new(config_opts, {
    prompt_title = config_opts.prompt_title,
    finder = finders.new_table {  -- change this line
      results = {},
      entry_maker = function(entry)
        return {
          display = entry,
          ordinal = entry,
          value = entry,
        }
      end,
    },
    sorter = telescope.sorters.get_generic_fuzzy_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      -- Function to handle the selection of an entry in the picker
      local function on_select()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        on_done(selection.value)
      end

      -- Map the <CR> key to the on_select function in both normal and insert mode
      map("i", "<CR>", on_select)
      map("n", "<CR>", on_select)

      return true
    end,
  }):find()
end

-- Function to query the metacode_ai API
local function query_metacode_ai(package_name, package_version, user_question)
  local result = vim.api.nvim_call_function("py3eval", {string.format([[
import vim
from metacode_ai.metacode_ai import MetaCodeAIQuery
try:
    result = MetaCodeAIQuery('%s', '%s', vim.eval('expand("%:p:h")'), '%s')
except Exception as e:
    result = str(e)
result]], package_name, package_version, vim.fn.expand("%:p:h"), user_question)})
  return result
end

-- Main function to create the metacode_ai picker
function metacode_ai.metacode_ai_picker(opts)
  opts = opts or {}

  -- Print the provided options for debugging purposes
  print("opts: ")
  print(vim.inspect(opts))

  -- Get the user's question using the get_user_question function
  get_user_question(function(user_question)
    -- Get the package name and version from the global variables
    local package_name = vim.g.metacode_ai_package_name or "default_package_name"
    local package_version = vim.g.metacode_ai_package_version or "default_package_version"

    -- Query the metacode_ai API with the package name, version, and user question
    local answer = vim.api.nvim_call_function("MetaCodeAIQuery", {package_name, package_version, user_question})

    -- Set the default options for the answer picker
    local default_opts = {
      prompt_title = 'MetaCode AI Answer',
      layout_config = {
        prompt_position = "top",
        preview_position = "top",
        preview_height = 0.5,
      },
    }
    -- Merge the default options with the provided options
    local config_opts = vim.tbl_extend("force", default_opts, opts)

    -- Print the final options for debugging purposes
    print("config_opts: ")
    print(vim.inspect(config_opts))

    -- Create a new picker to display the answer
    pickers.new(config_opts, {
      prompt_title = config_opts.prompt_title,
      finder = telescope.finders.new_table {
        results = {answer},
        entry_maker = telescope.make_entry.gen_from_string(config_opts),
      },
      sorter = telescope.sorters.get_generic_fuzzy_sorter(),
    }):find()
  end, opts)
end

-- Register the metacode_ai extension with telescope
return telescope.register_extension {
  exports = {
    metacode_ai_picker = metacode_ai.metacode_ai_picker
  },
}
