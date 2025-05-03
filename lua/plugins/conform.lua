return {
	"stevearc/conform.nvim",
	dependencies = {
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function(event)
		local ensure_installed = vim.tbl_keys({})
		vim.list_extend(ensure_installed, {
			"stylua",
			"clang-format",
			"black",
			"rustfmt",
		})
		require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

		local conform = require("conform")
		conform.setup({
			formatters_by_ft = {
				lua = { "stylua" },
				cpp = { "clang-format" },
				-- Conform will run multiple formatters sequentially
				python = { "black" },
				-- You can customize some of the format options for the filetype (:help conform.format)
				rust = { "rustfmt", lsp_format = "fallback" },
				-- Conform will run the first available formatter
				json = { "clang-format" },
				zig = function(args)
					vim.lsp.buf.code_action({ context = { only = { "source.fixAll" } }, apply = true })
					vim.loop.sleep(5)
					vim.lsp.buf.format()
				end,
				-- Formatters for all filetypes
				["*"] = {},
				-- Formatters for filetypes without formatters
				["_"] = { "trim_whitespace" },
			},
			default_format_opts = {
				lsp_format = "fallback",
			},
			format_on_save = {
				-- These options will be passed to conform.format()
				timeout_ms = 500,
				lsp_format = "fallback",
			},
		})
		vim.keymap.set("n", "<leader>ff", conform.format, { buffer = event.buf, desc = "[F]ormat [f]ile" })
	end,
}
