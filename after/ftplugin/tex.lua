vim.wo[0][0].conceallevel = 2
local undo = vim.b.undo_ftplugin
vim.b.undo_ftplugin = (undo and undo ~= "" and undo .. " | " or "") .. "setlocal conceallevel<"
