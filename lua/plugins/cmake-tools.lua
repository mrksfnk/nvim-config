return {
	"Civitasv/cmake-tools.nvim",
	event = "VimEnter",
	dependencies = {
		{ "stevearc/overseer.nvim", opts = {} },
		{ "akinsho/toggleterm.nvim", version = "*", config = true },
	},
	config = function()
		require("cmake-tools").setup({
			cmake_command = "cmake", -- this is used to specify cmake command path
			ctest_command = "ctest", -- this is used to specify ctest command path
			cmake_regenerate_on_save = false, -- auto generate when save CMakeLists.txt
			cmake_generate_options = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=1" }, -- this will be passed when invoke `CMakeGenerate`
			cmake_build_options = {}, -- this will be passed when invoke `CMakeBuild`
			-- support macro expansion:
			--       ${kit}
			--       ${kitGenerator}
			--       ${variant:xx}
			cmake_build_directory = "../../build/"
				.. vim.fn.fnamemodify(vim.loop.cwd(), ":t")
				.. "_${variant:buildType}", -- this is used to specify generate directory for cmake, allows macro expansion, relative to vim.loop.cwd()
			cmake_soft_link_compile_commands = true, -- this will automatically make a soft link from compile commands file to project root dir
			cmake_compile_commands_from_lsp = false, -- this will automatically set compile commands file location using lsp, to use it, please set `cmake_soft_link_compile_commands` to false
			cmake_kits_path = nil, -- this is used to specify global cmake kits path, see CMakeKits for detailed usage
			cmake_variants_message = {
				short = { show = true }, -- whether to show short message
				long = { show = true, max_length = 40 }, -- whether to show long message
			},
			cmake_dap_configuration = { -- debug settings for cmake
				name = "cpp",
				type = "codelldb", -- or "lldb" depending on which adapter you prefer
				request = "launch",
				stopOnEntry = false,
				runInTerminal = false,
				console = "integratedTerminal",
				env = {
					__NV_PRIME_RENDER_OFFLOAD = "1",
					__GLX_VENDOR_LIBRARY_NAME = "nvidia",
					__VK_LAYER_NV_optimus = "NVIDIA_only",
					VK_ICD_FILENAMES = "/usr/share/vulkan/icd.d/nvidia_icd.json",
				},
			},
			cmake_executor = { -- executor to use
				name = "quickfix", -- name of the executor
				opts = {}, -- the options the executor will get, possible values depend on the executor type. See `default_opts` for possible values.
				default_opts = { -- a list of default and possible values for executors
					quickfix = {
						show = "always", -- "always", "only_on_error"
						position = "belowright", -- "vertical", "horizontal", "leftabove", "aboveleft", "rightbelow", "belowright", "topleft", "botright", use `:h vertical` for example to see help on them
						size = 10,
						encoding = "utf-8", -- if encoding is not "utf-8", it will be converted to "utf-8" using `vim.fn.iconv`
						auto_close_when_success = false, -- typically, you can use it with the "always" option; it will auto-close the quickfix buffer if the execution is successful.
					},
					toggleterm = {
						open_mapping = [[<leader>`]],
						insert_mappings = true,
						terminal_mappings = true,
						start_in_insert = true,
						direction = "float", -- 'vertical' | 'horizontal' | 'tab' | 'float'
						close_on_exit = false, -- whether close the terminal when exit
						auto_scroll = true, -- whether auto scroll to the bottom
					},
					overseer = {
						new_task_opts = {
							strategy = {
								"toggleterm",
								direction = "horizontal",
								autos_croll = true,
								quit_on_exit = "success",
							},
						}, -- options to pass into the `overseer.new_task` command
						on_new_task = function(task)
							require("overseer").open({ enter = false, direction = "right" })
						end, -- a function that gets overseer.Task when it is created, before calling `task:start`
					},
					terminal = {
						name = "Main Terminal",
						prefix_name = "[CMakeTools]: ", -- This must be included and must be unique, otherwise the terminals will not work. Do not use a simple spacebar " ", or any generic name
						split_direction = "horizontal", -- "horizontal", "vertical"
						split_size = 11,

						-- Window handling
						single_terminal_per_instance = true, -- Single viewport, multiple windows
						single_terminal_per_tab = true, -- Single viewport per tab
						keep_terminal_static_location = true, -- Static location of the viewport if avialable

						-- Running Tasks
						start_insert = false, -- If you want to enter terminal with :startinsert upon using :CMakeRun
						focus = false, -- Focus on terminal when cmake task is launched.
						do_not_add_newline = false, -- Do not hit enter on the command inserted when using :CMakeRun, allowing a chance to review or modify the command before hitting enter.
					}, -- terminal executor uses the values in cmake_terminal
				},
			},
			cmake_runner = { -- runner to use
				name = "quickfix", -- name of the runner
				opts = {}, -- the options the runner will get, possible values depend on the runner type. See `default_opts` for possible values.
				default_opts = { -- a list of default and possible values for runners
					quickfix = {
						show = "always", -- "always", "only_on_error"
						position = "belowright", -- "bottom", "top"
						size = 10,
						encoding = "utf-8",
						auto_close_when_success = false, -- typically, you can use it with the "always" option; it will auto-close the quickfix buffer if the execution is successful.
					},
					toggleterm = {
						direction = "float", -- 'vertical' | 'horizontal' | 'tab' | 'float'
						close_on_exit = false, -- whether close the terminal when exit
						auto_scroll = true, -- whether auto scroll to the bottom
					},
					overseer = {
						new_task_opts = {
							strategy = {
								"toggleterm",
								direction = "horizontal",
								autos_croll = true,
								quit_on_exit = "success",
							},
						}, -- options to pass into the `overseer.new_task` command
						on_new_task = function(task) end, -- a function that gets overseer.Task when it is created, before calling `task:start`
					},
					terminal = {
						name = "Main Terminal",
						prefix_name = "[CMakeTools]: ", -- This must be included and must be unique, otherwise the terminals will not work. Do not use a simple spacebar " ", or any generic name
						split_direction = "horizontal", -- "horizontal", "vertical"
						split_size = 11,

						-- Window handling
						single_terminal_per_instance = true, -- Single viewport, multiple windows
						single_terminal_per_tab = true, -- Single viewport per tab
						keep_terminal_static_location = true, -- Static location of the viewport if avialable

						-- Running Tasks
						start_insert = false, -- If you want to enter terminal with :startinsert upon using :CMakeRun
						focus = false, -- Focus on terminal when cmake task is launched.
						do_not_add_newline = false, -- Do not hit enter on the command inserted when using :CMakeRun, allowing a chance to review or modify the command before hitting enter.
					},
				},
			},
			cmake_notifications = {
				runner = { enabled = true },
				executor = { enabled = true },
				spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }, -- icons used for progress display
				refresh_rate_ms = 100, -- how often to iterate icons
			},
		})
		-- Setup keymaps for CMake
		vim.keymap.set("n", "<leader>bs", "<cmd>CMakeSettings<CR>", { desc = "CMake [B]uild show [S]ettings" })
		vim.keymap.set(
			"n",
			"<leader>bg",
			"<cmd>CMakeGenerate -G Ninja<CR>",
			{ desc = "CMake [B]uild Configure & [G]enerate" }
		)
		vim.keymap.set("n", "<leader>bb", "<cmd>CMakeBuild<CR>", { desc = "CMake [B]uild current target" })
		vim.keymap.set("n", "<leader>br", "<cmd>CMakeRun<CR>", { desc = "CMake [B]uild [R]un current target" })
		vim.keymap.set("n", "<S-F5>", "<cmd>CMakeRun<CR>", { desc = "CMake [B]uild [R]un current target" })
		vim.keymap.set("n", "<leader>bd", "<cmd>CMakeDebug<CR>", { desc = "CMake [B]uild [D]ebug current target" })
		vim.keymap.set("n", "<leader>bt", "<cmd>CMakeSelectBuildTarget<CR>", { desc = "CMake [B]uild select [T]arget" })
		vim.keymap.set(
			"n",
			"<leader>bc",
			"<cmd>CMakeSelectBuildType<CR>",
			{ desc = "CMake [B]uild select [C]config type" }
		)
		vim.keymap.set("n", "<leader>be", function()
			local build_directory = require("cmake-tools").get_build_directory()
			if build_directory then
				vim.cmd("e" .. build_directory .. "/CMakeCache.txt")
			end
		end, { desc = "CMake [B]uild [E]dit cache" })
		vim.keymap.set("n", "<leader>bw", function()
			local build_directory = require("cmake-tools").get_build_directory()
			if build_directory then
				vim.cmd("!rm -rf " .. build_directory .. "/*")
			end
		end, { desc = "CMake [B]uild [W]ipe cache" })
	end,
}
