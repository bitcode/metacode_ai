local has_telescope, telescope = pcall(require, 'telescope')

if not has_telescope then
  error('This extension requires nvim-telescope/telescope.nvim')
end

local metacode_ai = {}

-- Define your custom pickers and actions here.
function metacode_ai.example_picker()
  -- Configure your picker options and mappings.
  local opts = {
    prompt_title = 'Example Picker',
    sorter = telescope.sorters.get_generic_fuzzy_sorter(),
    layout_config = {
      prompt_position = "top",
      prompt_height = 5,
    },
    -- Add other picker configuration options here.
  }

  local function example_action(prompt_bufnr)
    -- Handle selected item and close Telescope window.
    local entry = telescope.actions.get_selected_entry(prompt_bufnr)
    telescope.actions.close(prompt_bufnr)

    -- Perform your custom action on the selected item.
    print('Selected entry: ', entry.value)
  end

  telescope.pickers.new(opts, {
    prompt_title = opts.prompt_title,
    finder = telescope.finders.new_table {
      -- Add your list of items here.
      results = { 'item1', 'item2', 'item3' },
      entry_maker = telescope.make_entry.gen_from_string(opts),
    },
    previewer = telescope.previewers.display_content.new(opts),
    sorter = opts.sorter,
    attach_mappings = function(_, map)
      -- Bind your custom action to the "Enter" key.
      map('i', '<CR>', example_action)
      map('n', '<CR>', example_action)
      return true
    end,
  }):find()
end

-- Register your extension with Telescope.
telescope.extensions.metacode_ai = metacode_ai

return metacode_ai
