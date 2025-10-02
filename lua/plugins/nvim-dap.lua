return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui",
		"theHamsta/nvim-dap-virtual-text",
		"nvim-neotest/nvim-nio",
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		-- Setup dapui
		dapui.setup({
			icons = { expanded = "▾", collapsed = "▸" },
			mappings = {
				-- Use a table to apply multiple mappings
				expand = { "<CR>", "<2-LeftMouse>" },
				open = "o",
				remove = "d",
				edit = "e",
				repl = "r",
				toggle = "t",
			},
			layouts = {
				{
					elements = {
						{ id = "scopes", size = 0.25 },
						{ id = "breakpoints", size = 0.25 },
						{ id = "stacks", size = 0.25 },
						{ id = "watches", size = 0.25 },
					},
					size = 40,
					position = "left",
				},
				{
					elements = {
						{ id = "repl", size = 0.5 },
						{ id = "console", size = 0.5 },
					},
					size = 10,
					position = "bottom",
				},
			},
			floating = {
				max_height = nil,
				max_width = nil,
				border = "single",
				mappings = {
					close = { "q", "<Esc>" },
				},
			},
			windows = { indent = 1 },
		})

		-- Setup virtual text
		require("nvim-dap-virtual-text").setup({
			enabled = true,
			enabled_commands = true,
			highlight_changed_variables = true,
			highlight_new_as_changed = false,
			show_stop_reason = true,
			commented = false,
		})

		-- LLDB adapter configuration
		dap.adapters.lldb = {
			type = "executable",
			command = "/usr/bin/lldb-vscode", -- adjust as needed, must be absolute path
			name = "lldb",
		}

		-- CodeLLDB adapter (alternative, requires installation via Mason)
		dap.adapters.codelldb = {
			type = "server",
			port = "${port}",
			executable = {
				command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
				args = { "--port", "${port}" },
			},
		}

		-- C++ configurations
		dap.configurations.cpp = {
			{
				name = "Launch",
				type = "lldb",
				request = "launch",
				program = function()
					return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
				end,
				cwd = "${workspaceFolder}",
				stopOnEntry = false,
				args = {},
				runInTerminal = false,
			},
			{
				name = "Launch (CodeLLDB)",
				type = "codelldb",
				request = "launch",
				program = function()
					return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
				end,
				cwd = "${workspaceFolder}",
				stopOnEntry = false,
				args = {},
				runInTerminal = false,
			},
		}

		-- C configurations (same as C++)
		dap.configurations.c = dap.configurations.cpp

		-- Function to load VS Code launch.json configurations
		local function load_vscode_launch_json()
			local vscode_dir = vim.fn.getcwd() .. "/.vscode"
			local launch_json_path = vscode_dir .. "/launch.json"
			
			-- Only try to load if the file exists
			if vim.fn.filereadable(launch_json_path) ~= 1 then
				return -- Silently return if no launch.json exists
			end
			
			local file = io.open(launch_json_path, "r")
			if not file then
				return -- Silently return if file can't be opened
			end
			
			local content = file:read("*all")
			file:close()
			
			-- Remove comments from JSON (VS Code allows comments, vim.json.decode doesn't)
			content = content:gsub("/%*.-%*/", "") -- Remove /* */ comments
			content = content:gsub("//[^\n]*", "") -- Remove // comments
			
			-- Parse JSON
			local ok, launch_config = pcall(vim.json.decode, content)
			if ok and launch_config and launch_config.configurations then
				for _, config in ipairs(launch_config.configurations) do
					-- Map VS Code types to nvim-dap types
					local type_mapping = {
						cppdbg = "codelldb",
						lldb = "codelldb",
						gdb = "lldb"
					}
					
					-- Determine filetype from VS Code config
					local filetype = "cpp" -- default
					if config.type == "cppdbg" or config.type == "lldb" then
						filetype = "cpp"
					elseif config.program and config.program:match("%.c$") then
						filetype = "c"
					end
					
					local dap_config = {
						name = config.name or "VS Code Config",
						type = type_mapping[config.type] or config.type,
						request = config.request or "launch",
						program = config.program,
						args = config.args or {},
						cwd = config.cwd or "${workspaceFolder}",
						environment = config.environment or {},
						stopOnEntry = config.stopAtEntry or false,
						runInTerminal = config.console == "integratedTerminal" or false,
						-- Copy any additional VS Code specific settings
						preLaunchTask = config.preLaunchTask,
						postDebugTask = config.postDebugTask,
						miDebuggerPath = config.miDebuggerPath,
						setupCommands = config.setupCommands
					}
					
					-- Initialize filetype configurations if not exists
					if not dap.configurations[filetype] then
						dap.configurations[filetype] = {}
					end
					
					-- Add configuration
					table.insert(dap.configurations[filetype], dap_config)
				end
				
				-- Only notify if we actually loaded configurations
				if #launch_config.configurations > 0 then
					vim.notify("Loaded " .. #launch_config.configurations .. " debug configurations from launch.json", vim.log.levels.INFO)
				end
			end
			-- Silently ignore parse errors - launch.json is optional
		end

		-- Load launch.json automatically
		vim.api.nvim_create_autocmd({"VimEnter", "DirChanged"}, {
			callback = load_vscode_launch_json,
			group = vim.api.nvim_create_augroup("DapVSCodeLaunch", { clear = true })
		})

		-- Command to manually reload launch.json
		vim.api.nvim_create_user_command("DapLoadLaunchJson", load_vscode_launch_json, {
			desc = "Load VS Code launch.json configurations"
		})

		-- Auto-open/close dapui
		dap.listeners.after.event_initialized["dapui_config"] = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated["dapui_config"] = function()
			dapui.close()
		end
		dap.listeners.before.event_exited["dapui_config"] = function()
			dapui.close()
		end

		-- Keymaps for debugging
		vim.keymap.set("n", "<F5>", function()
			-- Check if we're in a cmake project and use cmake debug if available
			local cmake_tools = pcall(require, "cmake-tools")
			if cmake_tools then
				vim.cmd("CMakeDebug")
			else
				dap.continue()
			end
		end, { desc = "Start/Continue debugging" })

		vim.keymap.set("n", "<F9>", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
		vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Step over" })
		vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Step into" })
		vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Step out" })

		vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "[D]ebug toggle [B]reakpoint" })
		vim.keymap.set("n", "<leader>dB", function()
			dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
		end, { desc = "[D]ebug conditional [B]reakpoint" })
		vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "[D]ebug [C]ontinue" })
		vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "[D]ebug step [O]ver" })
		vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "[D]ebug step [I]nto" })
		vim.keymap.set("n", "<leader>dO", dap.step_out, { desc = "[D]ebug step [O]ut" })
		vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "[D]ebug [R]EPL" })
		vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "[D]ebug run [L]ast" })
		vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "[D]ebug [T]erminate" })
		vim.keymap.set("n", "<leader>dL", "<cmd>DapLoadLaunchJson<CR>", { desc = "[D]ebug [L]oad launch.json" })

		-- DAP UI keymaps
		vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "[D]ebug toggle [U]I" })
		vim.keymap.set({ "n", "v" }, "<leader>dh", function()
			require("dap.ui.widgets").hover()
		end, { desc = "[D]ebug [H]over" })
		vim.keymap.set({ "n", "v" }, "<leader>dp", function()
			require("dap.ui.widgets").preview()
		end, { desc = "[D]ebug [P]review" })
		vim.keymap.set("n", "<leader>df", function()
			local widgets = require("dap.ui.widgets")
			widgets.centered_float(widgets.frames)
		end, { desc = "[D]ebug [F]rames" })
		vim.keymap.set("n", "<leader>ds", function()
			local widgets = require("dap.ui.widgets")
			widgets.centered_float(widgets.scopes)
		end, { desc = "[D]ebug [S]copes" })
	end,
}
