-- Python は PEP8 に従い 4 スペースインデント
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 4
vim.opt_local.tabstop = 4
vim.opt_local.expandtab = true

-- black でバッファを整形する(:Black / <space>I)
-- black は stdin から読み整形結果を stdout に返すので、それを取り込む。
-- --stdin-filename でファイルパスを渡し、pyproject.toml の設定を効かせる。
-- 成功(exit 0)時のみ適用し、失敗時は元のバッファを壊さず通知する。
-- LSP経由の <space>i(ruff format)はそのまま併用できる。
local function format_with_black()
  local buf = vim.api.nvim_get_current_buf()
  local input = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n')
  local fname = vim.api.nvim_buf_get_name(buf)

  local output = vim.fn.systemlist(
    { 'black', '-q', '--stdin-filename', fname, '-' },
    input
  )

  if vim.v.shell_error ~= 0 then
    vim.notify('black:\n' .. table.concat(output, '\n'), vim.log.levels.ERROR)
    return
  end

  -- カーソル位置・スクロール位置を保持して置き換える
  local view = vim.fn.winsaveview()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
  vim.fn.winrestview(view)
end

vim.api.nvim_buf_create_user_command(0, 'Black', function()
  format_with_black()
end, { desc = 'Format buffer with black' })

vim.keymap.set('n', '<space>I', format_with_black,
  { buffer = true, desc = 'Format buffer with black' })
