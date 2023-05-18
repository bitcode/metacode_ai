local M = {}

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

	    local function on_select(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  if not selection then
    -- If there is no selection, just return
    return
  end
  print("User question:", selection.value) -- Added for debugging
  -- Call on_done with the selected value without closing the window
  on_done(selection.value)
end

      map("i", "<CR>", function() on_select(prompt_bufnr) end)
      map("n", "<CR>", on_select)

      return true
    end,
  }):find()
end

return M
