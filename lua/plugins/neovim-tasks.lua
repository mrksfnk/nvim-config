return {
	"mrksfnk/neovim-tasks",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"mfussenegger/nvim-dap",
	},
	config = function(event)
		if vim.fn.exists("g:os") == 0 then
			local is_windows = vim.fn.has("win64") == 1 or vim.fn.has("win32") == 1 or vim.fn.has("win16") == 1
			if is_windows then
				vim.g.os = "Windows"
			else
				local uname_output = vim.fn.system("uname")
				vim.g.os = string.gsub(uname_output, "\n", "")
			end
		end

		local Path = require("plenary.path")
		local tasks = require("tasks")
		tasks.setup({
			default_params = { -- Default module parameters with which `neovim.json` will be created.
				cmake = {
					cmd = "cmake", -- CMake executable to use, can be changed using `:Task set_module_param cmake cmd`.
					build_dir = tostring(Path:new("{cwd}") / ".." / ".." / "Builds" / "{cwd_dirname}-{build_type}"), -- Build directory. The expressions `{cwd}`, `{os}` and `{build_type}` will be expanded with the corresponding text values. Could be a function that return the path to the build directory.
					build_type = "Debug", -- Build type, can be changed using `:Task set_module_param cmake build_type`.
					dap_name = "lldb", -- DAP configuration name from `require('dap').configurations`. If there is no such configuration, a new one with this name as `type` will be created.
					args = { -- Task default arguments.
						configure = {
							"-D",
							"CMAKE_EXPORT_COMPILE_COMMANDS=1",
							"-G",
							vim.g.os == "Windows" and "Visual Studio 17 2022" or "Ninja",
						},
					},
				},
			},
			save_before_run = true, -- If true, all files will be saved before executing a task.
			params_file = "neovim.json", -- JSON file to store module and task parameters.
			quickfix = {
				pos = "botright", -- Default quickfix position.
				height = 12, -- Default height.
			},
			dap_open_command = function()
				return require("dap").repl.open()
			end, -- Command to run after starting DAP session. You can set it to `false` if you don't want to open anything or `require('dapui').open` if you are using https://github.com/rcarriga/nvim-dap-ui
		})
		-- Use different keymaps to avoid conflicts with cmake-tools
		vim.keymap.set("n", "<leader>tg", function()
			tasks.start("auto", "configure")
		end, { buffer = event.buffer, desc = "[T]asks [G]enerate project" })
		vim.keymap.set("n", "<leader>te", function()
			tasks.start("auto", "edit_cache")
		end, { buffer = event.buffer, desc = "[T]asks [E]dit project configuration" })
		vim.keymap.set("n", "<leader>tw", function()
			tasks.start("auto", "clean")
		end, { buffer = event.buffer, desc = "[T]asks [W]ipe project configuration" })
		vim.keymap.set("n", "<leader>tb", function()
			tasks.start("auto", "build")
		end, { buffer = event.buffer, desc = "[T]asks [B]uild project" })
		vim.keymap.set("n", "<leader>tr", function()
			tasks.start("auto", "run")
		end, { buffer = event.buffer, desc = "[T]asks [R]un project" })
		vim.keymap.set("n", "<leader>td", function()
			tasks.start("auto", "debug")
		end, { buffer = event.buffer, desc = "[T]asks [D]ebug project" })
		vim.keymap.set("n", "<leader>tt", function()
			tasks.start("auto", "test")
		end, { buffer = event.buffer, desc = "[T]asks [T]est project" })
	end,
}
