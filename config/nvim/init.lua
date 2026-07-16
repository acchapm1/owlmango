vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.base46_cache = vim.fn.stdpath("data") .. "/nvchad/base46/"
vim.g.nvchad_config = vim.fn.stdpath("config") .. "/lua/chadrc.lua"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
    config = function()
      require("options")
    end,
  },
  { import = "plugins" },
})

local chadrc = require("chadrc")
vim.g.nvchad_theme = (chadrc.base46 and chadrc.base46.theme) or chadrc.ui.theme

local nvconfig = require("nvconfig")
nvconfig.base46.theme = vim.g.nvchad_theme
nvconfig.ui.theme = chadrc.ui and chadrc.ui.theme or vim.g.nvchad_theme

local ok, base46 = pcall(require, "base46")
if ok and base46.load_all_highlights then
  base46.load_all_highlights()
end

dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")
require("nvchad.autocmds")
