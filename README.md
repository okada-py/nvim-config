# nvim-config

WSL2 (Ubuntu) 上で使っている Neovim の設定。プラグイン管理は `mini.deps`。

## 構成

| パス | 内容 |
| --- | --- |
| `init.lua` | 本体。オプション・キーマップ・autocmd・プラグイン設定 |
| `lua/lsp/` | LSP の設定(basedpyright / ruff / lua_ls) |
| `lua/user_command.lua` | 自作コマンド(`:InitLua` など) |
| `lua/bool_fn.lua` | `vim.fn` の戻り値を真偽値で扱うヘルパー(`vim.bool_fn.has('mac')` など) |
| `after/ftplugin/` | ファイルタイプ別の設定(Python は 4 スペース、`:Black` で整形) |
| `docs/commands.md` | 忘れがちな Vim コマンドのメモ |

## 外部ツール

なくても起動はするが、該当機能が使えなくなる。

- **zenhan.exe** — IME 自動オフ用(後述)。入手先: <https://github.com/iuchim/zenhan>
  置き場所は環境変数 `ZENHAN` にフルパス(WSL 側の `/mnt/c/...` 形式)で設定する。
  未設定なら PATH 上の `zenhan.exe` を探す。

  ```fish
  # ~/.config/fish/conf.d/zenhan.fish など、リポジトリ外に置く
  set -gx ZENHAN /mnt/c/Users/<Windowsユーザー名>/bin/zenhan.exe
  ```
- **black** — Python の整形(`:Black` / `<space>I`)
- **basedpyright / ruff / lua-language-server** — LSP

## 意図が見えにくい設定

### IME を自動で半角英数に戻す (`init.lua`)

日本語入力のままインサートモードを抜けると、ノーマルモードのキー入力が IME に吸われて
コマンドが効かない。これを防ぐため、`InsertLeave` / `CmdlineLeave` で
`zenhan.exe 0` を呼んで Windows の IME をオフにしている。

- WSL からは Windows の IME を直接操作できないので、Windows 側の exe を叩いている
- exe が見つかったときだけ autocmd を登録するので、WSL 以外の環境では何もしない
- 遅延を避けるため `vim.system(..., { detach = true })` で非同期実行
- パスに Windows のユーザー名が入るので、`init.lua` には書かず環境変数 `ZENHAN` で渡している

### 折り返しを有効に戻す (`init.lua` の `mini.basics` の直後)

`mini.basics` が `wrap = false` にするので、`setup()` の後で `wrap = true` に上書きしている。
`breakindent` / `linebreak` は `mini.basics` 側で有効になっている。

### 外部で変更されたファイルの自動再読み込み (`init.lua`)

Claude Code など nvim 外でファイルが編集されることが多いので、`autoread` に加えて
`FocusGained` / `BufEnter` / `CursorHold` で `checktime` を実行している。
コマンドラインウィンドウ中に `checktime` するとエラーになるため、ノーマルモードのときだけ実行する。

### 専用ターミナル (`<space>t`)

右側 40% にターミナルを開閉する。閉じるときはウィンドウを隠すだけでバッファは残すので、
Python の実行や Claude のセッションを開き直しても続きから使える。
