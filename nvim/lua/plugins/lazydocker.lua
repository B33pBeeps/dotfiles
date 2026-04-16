return {
	{
		"folke/snacks.nvim",
		opts = function(_, opts)
			-- Add lazydocker command
			opts.lazydocker = opts.lazydocker or {}
		end,
		keys = {
			{
				"<leader>td",
				function()
					require("snacks").terminal.open("lazydocker", {
						cwd = vim.fn.getcwd(),
						interactive = true,
					})
				end,
				desc = "Lazydocker",
			},
		},
	},
}
