local has_telescope, telescope = pcall(require, 'telescope.builtin')
if not has_telescope then
  error('This extension requires nvim-telescope/telescope.nvim')
end

local builtin = require('telescope')
local themes = require('telescope.themes')

local metacode_ai = {}

local function get_user_question(on_done)
  local opts = {
    prompt_title = "Enter your question",
  }

  telescope.pickers.new(opts, {
    prompt_title = opts.prompt_title,
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

function metacode_ai.metacode_ai_picker()
  get_user_question(function(user_question)
    local function query_metacode_ai(package_name, package_version)
      local result = vim.api.nvim_exec(
        [[python3 << EOF
import vim
from metacode_ai.metacode_ai import MetaCodeAIQuery
result = MetaCodeAIQuery(vim.eval('b:package_name'), vim.eval('b:package_version'), vim.eval('expand("%:p:h")'), vim.eval('b:user_question'))
vim.command(f'let b:result = {result}')
EOF]], true)
      return vim.api.nvim_buf_get_var(0, "result")
    end

    local package_name = vim.g.metacode_ai_package_name
    local package_version = vim.g.metacode_ai_package_version

    local answer = query_metacode_ai(package_name, package_version)

    local opts = {
      prompt_title = 'MetaCode AI Answer',
      layout_config = {
        prompt_position = "top",
        preview_position = "top",
        preview_height = 0.5,
      },
    }

    telescope.pickers.new(opts, {
      prompt_title = opts.prompt_title,
      finder = telescope.finders.new_table {
        results = {answer},
        entry_maker = telescope.make_entry.gen_from_string(opts),
      },
      sorter = telescope.sorters.get_generic_fuzzy_sorter(),
    }):find()
  end)
end

telescope.extensions.metacode_ai = metacode_ai

return metacode_ai
