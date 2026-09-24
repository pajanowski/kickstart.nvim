-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

vim.pack.add {
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = vim.version.range '*' },
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
}

vim.keymap.set('n', '\\', '<Cmd>Neotree reveal<CR>', { desc = 'NeoTree reveal', silent = true })

require('neo-tree').setup {
  filesystem = {
    window = {
      mappings = {
        ['\\'] = 'close_window',
      },
    },
  },
}

-- A neo-tree buffer is generated at runtime, so a session that saves one restores
-- an empty window named `neo-tree filesystem [1]` instead of a file tree.
local session_group = vim.api.nvim_create_augroup('kickstart-neo-tree-session', { clear = true })

---@param buf integer
---@return boolean
local function is_stale_tree(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype == 'neo-tree' then return false end
  return vim.fs.basename(vim.api.nvim_buf_get_name(buf)):match '^neo%-tree %a+ %[%d+%]$' ~= nil
end

-- Close the tree before the session is written, so it never gets saved in the first place.
vim.api.nvim_create_autocmd('VimLeavePre', {
  group = session_group,
  callback = function() pcall(vim.cmd, 'Neotree close') end,
})

-- Clean up anything an already-saved session brings back, then open a real tree for the cwd.
vim.api.nvim_create_autocmd('SessionLoadPost', {
  group = session_group,
  callback = function()
    local had_tree = false

    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if is_stale_tree(vim.api.nvim_win_get_buf(win)) then
        had_tree = true
        pcall(vim.api.nvim_win_close, win, true)
      end
    end

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if is_stale_tree(buf) then
        had_tree = true
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end

    if had_tree then vim.schedule(function() pcall(vim.cmd, 'Neotree show') end) end
  end,
})
