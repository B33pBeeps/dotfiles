return {
	{
		"folke/snacks.nvim",
		opts = function(_, opts)
			opts.picker = opts.picker or {}

			opts.picker.sources = opts.picker.sources or {}
			opts.picker.sources.explorer = opts.picker.sources.explorer or {}

			-- Overwrite with your layout
			opts.picker.sources.explorer.layout = {
				{ preview = true },
				layout = {
					box = "horizontal",
					width = 0.8,
					height = 0.8,
					{
						box = "vertical",
						border = "rounded",
						title = "{source} {live} {flags}",
						title_pos = "center",
						{ win = "input", height = 1, border = "bottom" },
						{ win = "list", border = "none" },
					},
					{ win = "preview", border = "rounded", width = 0.7, title = "{preview}" },
				},
			}

			-- Optionally ensure auto-close is true (as you mentioned it's needed)
			opts.picker.sources.explorer.auto_close = true

			-- Adding the terminal window option
			opts.terminal = opts.terminal or {}
			opts.terminal.win = opts.terminal.win or {}
			opts.terminal.win.position = "float"

			return opts
		end,
	},
}
