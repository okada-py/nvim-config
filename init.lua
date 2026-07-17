-- cache init.lua
vim.loader.enable()

-- share clipboard with OS
vim.opt.clipboard = 'unnamedplus'

-- 分割は右/下に開く(mini.pickの <C-v>/<C-s> もこれに従う)
vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.expandtab = true
vim.opt.shiftround = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2

vim.opt.scrolloff = 3

vim.opt.whichwrap = 'b,s,h,l,<,>,[,],~'

require('user_command')

require('bool_fn')

-- augroup for this config file
local augroup = vim.api.nvim_create_augroup('init.lua', {})


-- wrapper function to use internal augroup
local function create_autocmd(event, opts)
  vim.api.nvim_create_autocmd(event, vim.tbl_extend('force', {
    group = augroup,
  }, opts))
end

-- https://vim-jp.org/vim-users-jp/2011/02/20/Hack-202.html
create_autocmd('BufWritePre', {
  pattern = '*',
  callback = function(event)
    local dir = vim.fs.dirname(event.file)
    local force = vim.v.cmdbang == 1
    if not vim.bool_fn.isdirectory(dir) == 0
        and (force or vim.fn.confirm('"' .. dir .. '" does not exist. Create?', "&Yes\n&No") == 1) then
      vim.fn.mkdir(vim.fn.iconv(dir, vim.opt.encoding:get(), vim.opt.termencoding:get()), 'p')
    end
  end,
  desc = 'Auto mkdir to save file'
})

vim.keymap.set('n', 'p', 'p`]', { desc = 'Paste and move to the end' })
vim.keymap.set('n', 'P', 'P`]', { desc = 'Paste and move to the end' })

vim.keymap.set('x', 'p', 'P', { desc = 'Paste without change register' })
vim.keymap.set('x', 'P', 'p', { desc = 'Paste with change register' })

vim.keymap.set({ 'n', 'x' }, 'x', '"_d', { desc = 'Delete using blackhole register' })
vim.keymap.set('n', 'X', '"_D', { desc = 'Delete using blackhole register' })
vim.keymap.set('o', 'x', 'd', { desc = 'Delete using x' })

vim.keymap.set('c', '<c-b>', '<left>', { desc = 'Emacs like left' })
vim.keymap.set('c', '<c-f>', '<right>', { desc = 'Emacs like right' })
vim.keymap.set('c', '<c-a>', '<home>', { desc = 'Emacs like home' })
vim.keymap.set('c', '<c-e>', '<end>', { desc = 'Emacs like end' })
vim.keymap.set('c', '<c-h>', '<bs>', { desc = 'Emacs like bs' })
vim.keymap.set('c', '<c-d>', '<del>', { desc = 'Emacs like del' })

vim.keymap.set('n', '<space>;', '@:', { desc = 'Re-run the last command' })

vim.keymap.set('n', '<space>w', '<cmd>write<cr>', { desc = 'Write' })

vim.keymap.set({ 'n', 'x' }, 'so', ':source<cr>', { silent = true, desc = 'Source current script' })

vim.keymap.set('c', '<c-n>', function()
  return vim.bool_fn.wildmenumode() and '<c-n>' or '<down>'
end, { expr = true, desc = 'Select next' })
vim.keymap.set('c', '<c-p>', function()
  return vim.bool_fn.wildmenumode() and '<c-p>' or '<up>'
end, { expr = true, desc = 'Select previous' })

vim.keymap.set('n', '<space>q', function()
  if not pcall(vim.cmd.tabclose) then
    vim.cmd.quit()
  end
end, { desc = 'Quit current tab or window' })

vim.keymap.set('n', 'q:', '<nop>', { desc = 'Disable cmdwin' })

-- 縦分割の専用ターミナルをトグル開閉する(Python実行・Claude起動を使い回す)
-- セッションは閉じずに隠すだけなので、再度開くと続きから使える
local term_state = { buf = -1, win = -1 }
local function toggle_terminal()
  -- すでに開いていれば隠す(バッファは残す)
  if vim.api.nvim_win_is_valid(term_state.win) then
    vim.api.nvim_win_hide(term_state.win)
    term_state.win = -1
    return
  end

  -- 右側に縦分割で開く(幅は画面の40%)
  vim.cmd('botright vsplit')
  term_state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(term_state.win, math.floor(vim.o.columns * 0.4))

  -- 生きているターミナルバッファがあれば再利用、なければ新規作成
  if vim.api.nvim_buf_is_valid(term_state.buf) then
    vim.api.nvim_win_set_buf(term_state.win, term_state.buf)
  else
    vim.cmd.terminal()
    term_state.buf = vim.api.nvim_get_current_buf()
  end

  vim.cmd.startinsert()
end
vim.keymap.set('n', '<space>t', toggle_terminal, { desc = 'Toggle terminal' })

-- 外部(Claude等)で編集されたファイルを自動で読み直す
vim.opt.autoread = true
create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold' }, {
  pattern = '*',
  callback = function()
    if vim.fn.mode() == 'n' and vim.fn.getcmdwintype() == '' then
      vim.cmd('checktime')
    end
  end,
  desc = 'Reload files changed on disk',
})

-- Clone 'mini.nvim' manually in a way that it gets managed by 'mini.deps'
local path_package = vim.fn.stdpath('data') .. '/site/'
local mini_path = path_package .. 'pack/deps/start/mini.nvim'
if not vim.uv.fs_stat(mini_path) then
  vim.cmd('echo "Installing `mini.nvim`" | redraw')
  local clone_cmd = {
    'git', 'clone', '--filter=blob:none',
    'https://github.com/echasnovski/mini.nvim', mini_path
  }
  vim.fn.system(clone_cmd)
  vim.cmd('packadd mini.nvim | helptags ALL')
  vim.cmd('echo "Installed `mini.nvim`" | redraw')
end

-- Set up 'mini.deps' (customize to your liking)
require('mini.deps').setup({ path = { package = path_package } })

local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

now(function()
  require('mini.icons').setup()
end)

now(function()
  require('mini.basics').setup({
    options = {
      extra_ui = true,
    },
    mappings = {
      option_toggle_prefix = 'm',
    },
  })
end)

later(function()
  add('https://github.com/vim-jp/vimdoc-ja')
  -- Prefer Japanese as the help language
  vim.opt.helplang:prepend('ja')
end)

now(function()
  require('mini.statusline').setup()
  vim.opt.laststatus = 3
  vim.opt.cmdheight = 0
end)

-- require('mini.statusline').setup()と同じlaterの中に追加
create_autocmd({ 'RecordingEnter', 'CmdlineEnter' }, {
  pattern = '*',
  callback = function()
    vim.opt.cmdheight = 1
  end,
})
create_autocmd('RecordingLeave', {
  pattern = '*',
  callback = function()
    vim.opt.cmdheight = 0
  end,
})
create_autocmd('CmdlineLeave', {
  pattern = '*',
  callback = function()
    if vim.fn.reg_recording() == '' then
      vim.opt.cmdheight = 0
    end
  end,
})

now(function()
  require('mini.misc').setup()

  MiniMisc.setup_restore_cursor()

  vim.api.nvim_create_user_command('Zoom', function()
    MiniMisc.zoom(0, {})
  end, { desc = 'Zoom current buffer' })
  vim.keymap.set('n', 'mz', '<cmd>Zoom<cr>', { desc = 'Zoom current buffer' })
end)

now(function()
  require('mini.notify').setup()

  vim.notify = require('mini.notify').make_notify({
    ERROR = { duration = 10000 }
  })

  -- require('mini.notify').setup()と同じnowに追加
  vim.api.nvim_create_user_command('NotifyHistory', function()
    MiniNotify.show_history()
  end, { desc = 'Show notify history' })
end)

now(function()
  vim.cmd.colorscheme('minicyan')
end)

later(function()
  local hipatterns = require('mini.hipatterns')
  local hi_words = require('mini.extra').gen_highlighter.words
  hipatterns.setup({
    highlighters = {
      -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
      fixme = hi_words({ 'FIXME', 'Fixme', 'fixme' }, 'MiniHipatternsFixme'),
      hack = hi_words({ 'HACK', 'Hack', 'hack' }, 'MiniHipatternsHack'),
      todo = hi_words({ 'TODO', 'Todo', 'todo' }, 'MiniHipatternsTodo'),
      note = hi_words({ 'NOTE', 'Note', 'note' }, 'MiniHipatternsNote'),
      -- Highlight hex color strings (`#rrggbb`) using that color
      hex_color = hipatterns.gen_highlighter.hex_color(),
    },
  })
end)

later(function()
  require('mini.cursorword').setup()
end)

later(function()
  require('mini.indentscope').setup()
end)

later(function()
  require('mini.trailspace').setup()
end)

-- require('mini.trailspace').setup()と同じlaterに追加
vim.api.nvim_create_user_command(
  'Trim',
  function()
    MiniTrailspace.trim()
    MiniTrailspace.trim_last_lines()
  end,
  { desc = 'Trim trailing space and last blank lines' }
)

now(function()
  require('mini.sessions').setup()
end)

local function is_blank(arg)
  return arg == nil or arg == ''
end
local function get_sessions(lead)
  -- ref: https://qiita.com/delphinus/items/2c993527df40c9ebaea7
  return vim
      .iter(vim.fs.dir(MiniSessions.config.directory))
      :map(function(v)
        local name = vim.fn.fnamemodify(v, ':t:r')
        return vim.startswith(name, lead) and name or nil
      end)
      :totable()
end
vim.api.nvim_create_user_command('SessionWrite', function(arg)
  local session_name = is_blank(arg.args) and vim.v.this_session or arg.args
  if is_blank(session_name) then
    vim.notify('No session name specified', vim.log.levels.WARN)
    return
  end
  vim.cmd('%argdelete')
  MiniSessions.write(session_name)
end, { desc = 'Write session', nargs = '?', complete = get_sessions })

vim.api.nvim_create_user_command('SessionDelete', function(arg)
  MiniSessions.select('delete', { force = arg.bang })
end, { desc = 'Delete session', bang = true })

vim.api.nvim_create_user_command('SessionLoad', function()
  MiniSessions.select('read', { verbose = true })
end, { desc = 'Load session' })

vim.api.nvim_create_user_command('SessionEscape', function()
  vim.v.this_session = ''
end, { desc = 'Escape session' })

vim.api.nvim_create_user_command('SessionReveal', function()
  if is_blank(vim.v.this_session) then
    vim.print('No session')
    return
  end
  vim.print(vim.fn.fnamemodify(vim.v.this_session, ':t:r'))
end, { desc = 'Reveal session' })

-- この下にmini.starterの設定

now(function()
  require('mini.starter').setup()
end)

later(function()
  require('mini.pairs').setup()
end)

later(function()
  require('mini.surround').setup()
end)

later(function()
  local gen_ai_spec = require('mini.extra').gen_ai_spec
  require('mini.ai').setup({
    custom_textobjects = {
      B = gen_ai_spec.buffer(),
      D = gen_ai_spec.diagnostic(),
      I = gen_ai_spec.indent(),
      L = gen_ai_spec.line(),
      N = gen_ai_spec.number(),
      J = { { '()%d%d%d%d%-%d%d%-%d%d()', '()%d%d%d%d%/%d%d%/%d%d()' } }
    },
  })
end)

later(function()
  local function mode_nx(keys)
    return { mode = 'n', keys = keys }, { mode = 'x', keys = keys }
  end
  local clue = require('mini.clue')
  clue.setup({
    triggers = {
      -- Leader triggers
      mode_nx('<leader>'),

      -- Built-in completion
      { mode = 'i', keys = '<c-x>' },

      -- `g` key
      mode_nx('g'),

      -- Marks
      mode_nx("'"),
      mode_nx('`'),

      -- Registers
      mode_nx('"'),
      { mode = 'i', keys = '<c-r>' },
      { mode = 'c', keys = '<c-r>' },

      -- Window commands
      { mode = 'n', keys = '<c-w>' },

      -- bracketed commands
      { mode = 'n', keys = '[' },
      { mode = 'n', keys = ']' },

      -- `z` key
      mode_nx('z'),

      -- surround
      mode_nx('s'),

      -- text object
      { mode = 'x', keys = 'i' },
      { mode = 'x', keys = 'a' },
      { mode = 'o', keys = 'i' },
      { mode = 'o', keys = 'a' },

      -- option toggle (mini.basics)
      { mode = 'n', keys = 'm' },
    },

    clues = {
      -- Enhance this by adding descriptions for <Leader> mapping groups
      clue.gen_clues.builtin_completion(),
      clue.gen_clues.g(),
      clue.gen_clues.marks(),
      clue.gen_clues.registers({ show_contents = true }),
      clue.gen_clues.windows({ submode_resize = true, submode_move = true }),
      clue.gen_clues.z(),
      { mode = 'n', keys = 'mm', desc = '+mini.map' },
    },
  })
end)

now(function()
  require('lsp')
end)

-- lspの設定のnow()の中に追加
create_autocmd('LspAttach', {
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

    vim.keymap.set('n', 'grd', function()
      vim.lsp.buf.definition()
    end, { buffer = args.buf, desc = 'vim.lsp.buf.definition()' })

    vim.keymap.set('n', '<space>i', function()
      vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
    end, { buffer = args.buf, desc = 'Format buffer' })
  end,
})

later(function()
  require('mini.fuzzy').setup()
  require('mini.completion').setup({
    lsp_completion = {
      process_items = MiniFuzzy.process_lsp_items,
    },
  })

  -- improve fallback completion
  vim.opt.complete = { '.', 'w', 'k', 'b', 'u' }
  vim.opt.completeopt:append('fuzzy')
  vim.opt.dictionary:append('/usr/share/dict/words') -- 注意1

  -- define keycodes
  local keys = {
    cn = vim.keycode('<c-n>'),
    cp = vim.keycode('<c-p>'),
    ct = vim.keycode('<c-t>'),
    cd = vim.keycode('<c-d>'),
    cr = vim.keycode('<cr>'),
    cy = vim.keycode('<c-y>'),
  }

  -- select by <tab>/<s-tab>
  vim.keymap.set('i', '<tab>', function()
    -- popup is visible -> next item
    -- popup is NOT visible -> add indent
    return vim.bool_fn.pumvisible() and keys.cn or keys.ct
  end, { expr = true, desc = 'Select next item if popup is visible' })
  vim.keymap.set('i', '<s-tab>', function()
    -- popup is visible -> previous item
    -- popup is NOT visible -> remove indent
    return vim.bool_fn.pumvisible() and keys.cp or keys.cd
  end, { expr = true, desc = 'Select previous item if popup is visible' })

  -- complete by <cr>
  vim.keymap.set('i', '<cr>', function()
    if not vim.bool_fn.pumvisible() then
      -- popup is NOT visible -> insert newline
      return require('mini.pairs').cr() -- 注意2
    end
    local item_selected = vim.fn.complete_info()['selected'] ~= -1
    if item_selected then
      -- popup is visible and item is selected -> complete item
      return keys.cy
    end
    -- popup is visible but item is NOT selected -> hide popup and insert newline
    return keys.cy .. keys.cr
  end, { expr = true, desc = 'Complete current item if item is selected' })

  require('mini.snippets').setup({
    mappings = {
      jump_prev = '<c-k>',
    },
  })
end)

later(function()
  require('mini.tabline').setup()
end)

later(function()
  require('mini.bufremove').setup()

  vim.api.nvim_create_user_command(
    'Bufdelete',
    function()
      MiniBufremove.delete()
    end,
    { desc = 'Remove buffer' }
  )
end)

now(function()
  require('mini.files').setup()

  vim.api.nvim_create_user_command(
    'Files',
    function()
      MiniFiles.open()
    end,
    { desc = 'Open file exproler' }
  )
end)

later(function()
  require('mini.pick').setup({
    mappings = {
      -- <C-v> はターミナル(Windows Terminal等)の貼り付けと競合するため
      -- 縦分割で開くキーを <C-o> ("open in vsplit") に変更
      choose_in_vsplit = '<C-o>',
    },
  })

  vim.ui.select = MiniPick.ui_select

  vim.keymap.set('n', '<space>f', function()
    MiniPick.builtin.files({ tool = 'git' })
  end, { desc = 'mini.pick.files' })
  vim.keymap.set('n', '<space>b', function()
    local wipeout_cur = function()
      vim.api.nvim_buf_delete(MiniPick.get_picker_matches().current.bufnr, {})
    end
    local buffer_mappings = { wipeout = { char = '<c-d>', func = wipeout_cur } }
    MiniPick.builtin.buffers({ include_current = false }, { mappings = buffer_mappings })
  end, { desc = 'mini.pick.buffers' })
  require('mini.visits').setup()
  vim.keymap.set('n', '<space>h', function()
    require('mini.extra').pickers.visit_paths()
  end, { desc = 'mini.extra.visit_paths' })
  vim.keymap.set('c', 'h', function()
    if vim.fn.getcmdtype() .. vim.fn.getcmdline() == ':h' then
      return '<c-u>Pick help<cr>'
    end
    return 'h'
  end, { expr = true, desc = 'mini.pick.help' })
end)

later(function()
  require('mini.diff').setup()
end)

later(function()
  require('mini.git').setup()

  vim.keymap.set({ 'n', 'x' }, '<space>gs', MiniGit.show_at_cursor, { desc = 'Show at cursor' })
end)

later(function()
  require('mini.operators').setup({
    replace = { prefix = 'R' },
    exchange = { prefix = 'g/' },
  })

  vim.keymap.set('n', 'RR', 'R', { desc = 'Replace mode' })
end)

later(function()
  require('mini.jump').setup({
    delay = {
      idle_stop = 10,
    },
  })
end)

later(function()
  require('mini.jump2d').setup()
end)

later(function()
  local animate = require('mini.animate')
  animate.setup({
    cursor = {
      -- Animate for 100 milliseconds with linear easing
      timing = animate.gen_timing.linear({ duration = 100, unit = 'total' }),
    },
    scroll = {
      -- Animate for 150 milliseconds with linear easing
      timing = animate.gen_timing.linear({ duration = 150, unit = 'total' }),
    }
  })
end)

later(function()
  require('mini.bracketed').setup()
end)

later(function()
  require('mini.splitjoin').setup({
    mappings = {
      toggle = 'gS',
      split = 'ss',
      join = 'sj',
    },
  })
end)

later(function()
  require('mini.move').setup()
end)

later(function()
  require('mini.align').setup()
end)

later(function()
  local map = require('mini.map')

  map.setup({
    integrations = {
      map.gen_integration.builtin_search(),
      map.gen_integration.diff(),
      map.gen_integration.diagnostic(),
    },
    symbols = {
      encode = map.gen_encode_symbols.shade('2x1'),
      scroll_line = '>',
      scroll_view = '|',
    },
    window = {
      side = 'right',
      width = 10,
      winblend = 0,
    },
  })

  vim.keymap.set('n', 'mmf', MiniMap.toggle_focus, { desc = 'MiniMap.toggle_focus' })
  vim.keymap.set('n', 'mms', MiniMap.toggle_side, { desc = 'MiniMap.toggle_side' })
  vim.keymap.set('n', 'mmt', MiniMap.toggle, { desc = 'MiniMap.toggle' })
end)

later(function()
  add({
    source = 'https://github.com/nvim-treesitter/nvim-treesitter',
    hooks = {
      post_checkout = function()
        vim.cmd.TSUpdate()
      end,
    },
  })

  local ts = require('nvim-treesitter')

  ts.setup({
    install_dir = vim.fn.stdpath('data') .. '/site',
  })

  ts.install({
    'lua',
    'vim',
    'vimdoc',
    'python',
  })

  create_autocmd('FileType', {
    pattern = {
      'lua',
      'vim',
      'vimdoc',
      'python',
    },
    callback = function(args)
      pcall(vim.treesitter.start, args.buf)
    end,
    desc = 'Start treesitter highlighting',
  })
end)

later(function()
  -- .ipynb を `# %%` 区切りのスクリプト形式で編集（保存時に .ipynb へ書き戻し）
  -- 別途 `pip install jupytext` が必要
  add('https://github.com/GCBallesteros/jupytext.nvim')
  require('jupytext').setup({
    -- 'hydrogen' = percent形式。filetypeがpythonになりLSP/treesitterが効く
    style = 'hydrogen',
  })
end)
