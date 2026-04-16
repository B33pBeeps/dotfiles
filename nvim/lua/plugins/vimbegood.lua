return {
	-- vim-be-good plugin
	{
		"ThePrimeagen/vim-be-good",
		event = "VimEnter", -- Optional, if you want to delay loading until Vim is ready.
		config = function()
			-- You can add any configuration options for vim-be-good here.
		end,
	},

	-- nvim-treesitter-context plugin
	{
		"nvim-treesitter/nvim-treesitter-context",
		after = "nvim-treesitter", -- Ensure that nvim-treesitter is loaded before this
		config = function()
			require("treesitter-context").setup({
				-- Add any configuration options for treesitter-context here if necessary.
			})
		end,
	},
}
