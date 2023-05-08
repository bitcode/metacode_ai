-- Check if telescope is installed, otherwise throw an error 
if not pcall(require, 'telescope') then
  error('This extension requires nvim-telescope/telescope.nvim')
end

return require('telescope').register_extension {
  setup = function(ext_config, config)
    -- access extension config and user config
  end,
  exports = {
    metacode_ai = require('metacode_ai').metacode_ai_picker
  },
}
