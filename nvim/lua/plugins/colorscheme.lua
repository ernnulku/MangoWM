return {
  {
    "vague2k/vague.nvim",
    config = function()
      require("vague").setup({
        -- Minimal pure black background configuration
      })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "vague",
    },
  },
}
