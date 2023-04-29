local has_telescope, telescope = pcall(require, 'telescope.builtin')
if not has_telescope then
  error('This extension requires nvim-telescope/telescope.nvim')
end

local builtin = require('telescope')
local telescope = require('telescope')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')

local metacode_ai = {}

local function get_user_question(on_done, opts)
  local config_opts = vim.tbl_extend("force", {prompt_title = "Enter your question"}, opts)

  telescope.pickers.new(config_opts, {
    prompt_title = config_opts.prompt_title,
    finder = telescope.finders.new_table {
      results = {},
      entry_maker = function(entry)
        return {
          display = entry,
          ordinal = entry,
          value = entry,
        }
      end,
    },
    sorter = telescope.sorters.get_generic_fuzzy_sorter(),
    attach_mappings = function(prompt_bufnr, map)
      local function on_select()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        on_done(selection.value)
      end

map("i", "<CR>", on_select)
      map("n", "<CR>", on_select)

      return true
    end,
  }):find()
end

local function query_metacode_ai(package_name, package_version, user_question)
  local result = vim.api.nvim_call_function("py3eval", {string.format([[
import vim
from metacode_ai.metacode_ai import MetaCodeAIQuery
try:
    result = MetaCodeAIQuery('%s', '%s', vim.eval('expand("%:p:h")'), '%s')
except Exception as e:
    result = str(e)
result]], package_name, package_version, user_question)})
  return result
end

function metacode_ai.metacode_ai_picker(opts)
  opts = opts or {}
  get_user_question(function(user_question)
    local package_name = vim.g.metacode_ai_package_name or "default_package_name"
    local package_version = vim.g.metacode_ai_package_version or "default_package_version"

    local answer = query_metacode_ai(package_name, package_version, user_question)

    local default_opts = {
      prompt_title = 'MetaCode AI Answer',
      layout_config = {
        prompt_position = "top",
        preview_position = "top",
        preview_height = 0.5,
      },
    }
    local config_opts = vim.tbl_extend("force", default_opts, opts)

    telescope.pickers.new(config_opts, {
      prompt_title = config_opts.prompt_title,
      finder = telescope.finders.new_table {
        results = {answer},
        entry_maker = telescope.make_entry.gen_from_string(config_opts),
      },
      sorter = telescope.sorters.get_generic_fuzzy_sorter(),
    }):find()
  end, opts)
end

telescope.extensions.metacode_ai = metacode_ai

return metacode_ai
