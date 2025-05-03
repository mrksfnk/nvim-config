return {
	'nvim-telescope/telescope.nvim', tag = '0.1.8',
	dependencies = {
		'nvim-lua/plenary.nvim',
		-- required for live_grep and grep_string and first priority for find_files
		'BurntSushi/ripgrep',				
		{
			'nvim-telescope/telescope-fzf-native.nvim',
			build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release',
			cond = function()
				return vim.fn.executable 'cmake' == 1
			end,
		},
		{ 'nvim-telescope/telescope-ui-select.nvim' },
		{ 'nvim-telescope/telescope-file-browser.nvim' },

		-- Useful for getting pretty icons, but requires a Nerd Font.
		{ 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
	},
	config = function()
		-- Enable telescope extensions, if they are installed
		pcall(require('telescope').load_extension, 'fzf')
		pcall(require('telescope').load_extension, 'ui-select')
		pcall(require('telescope').load_extension, 'file_browser')
		-- Configure keymaps
		local builtin = require('telescope.builtin')
		vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = 'Telescope find files' })
		vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = 'Telescope live grep' })
		vim.keymap.set('n', '<leader>sb', builtin.buffers, { desc = 'Telescope buffers' })
		vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = 'Telescope help tags' })
	end,
}
