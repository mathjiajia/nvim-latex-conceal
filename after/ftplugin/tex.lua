vim.wo[0][0].conceallevel = 2
vim.b.undo_ftplugin = (vim.b.undo_ftplugin and vim.b.undo_ftplugin .. " | " or "") .. "setlocal conceallevel<"
