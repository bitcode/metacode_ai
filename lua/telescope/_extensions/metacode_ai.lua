local has_telescope, telescope = pcall(require, 'telescope')

if not has_telescope then
  error('This extension requires nvim-telescope/telescope.nvim')
end

local metacode_ai = {}

function metacode_ai.metacode_ai_picker()
  local user_question = vim.fn.input("Ask a question: ")

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
end

telescope.extensions.metacode_ai = metacode_ai

return metacode_ai
