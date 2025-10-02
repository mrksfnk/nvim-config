return {
	"nvim-treesitter/nvim-treesitter",
	branch = "master",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter.configs").setup({
			ensure_installed = {
				"c",
				"cpp",
				"cmake",
				"markdown",
				"python",
			},
			highlight = {
				disable = {
					"text",
				},
			},
		})
	end,
}
