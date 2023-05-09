MetaCode AI is a Neovim plugin and Telescope Extension that combines the power of AI-powered language models with the precision of project-specific information to provide helpful suggestions and answers to programming tasks. By parsing your project's configuration files, MetaCode AI enhances the context for the LangChain framework, which in turn consults the official documentation related to your config files, packages, and frameworks used. This integration with Telescope ensures that the AI's suggestions are accurate and up-to-date, minimizing the risk of AI hallucinations and streamlining the process of asking questions and receiving relevant answers.

Installation

(This Telescope Extension is still under construction)

You can install MetaCode AI using Packer, a package manager for Neovim. Follow the instructions below to install the plugin.

Install Packer if you haven't already.

Add the following code block to your `plugins.lua` file:

```
use {
    'bitcode/metacode_ai',
    branch = 'master',
    requires = {'nvim-telescope/telescope.nvim'},
    config = function()
        require('telescope').load_extension('metacode_ai')
    end,
    post_install = function()
        local plugin_dir = vim.fn.stdpath('data')..'/site/pack/packer/start/metacode_ai/python'
        vim.fn.system('pip install --user .', plugin_dir)
    end,
}
```

Add the following line to your init.lua file:


`require('telescope').load_extension('metacode_ai')`

Create a `.env` file in your home directory with the following structure, replacing the placeholder values with your actual API keys:

```
OPENAI_API_KEY=your_openai_api_key
COHERE_API_KEY=your_cohere_api_key
GOOSEAI_API_KEY=your_gooseai_api_key
HUGGINGFACEHUB_API_TOKEN=your_huggingfacehub_api_token
HUGGINGFACE_API_KEY=your_huggingface_api_key
CEREBRIUMAI_API_KEY=your_cerebriumai_api_key
SERPAPI_API_KEY=your_serpapi_api_key
GOOGLE_API_KEY=your_google_api_key
GOOGLE_CSE_ID=your_google_cse_id
WOLFRAM_ALPHA_APPID=your_wolfram_alpha_appid
```

The plugin will load the API keys from the .env file in your home directory.

Restart Neovim, and the plugin should be ready to use.

Now you can use MetaCode AI to get AI-powered assistance directly in Neovim. Enjoy!
