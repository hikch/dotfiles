" ----------------------------------------------------------------------
"  Kaoriya の設定を反映しない
"
let g:gvimrc_local_finish = 0

set guifont=Menlo\ \Regular\ for\ Powerline:h14

"---------------------------------------------------------------------------
" Color scheme
"
colorscheme solarized


"---------------------------------------------------------------------------
" 日本語入力に関する設定:
"
if has('multi_byte_ime') || has('xim') || has('gui_macvim')
  " IME ON時のカーソルの色を設定(設定例:紫)
  highlight CursorIM guibg=Purple guifg=NONE
  " 挿入モード・検索モードでのデフォルトのIME状態設定
  set iminsert=0 imsearch=0
  if has('xim') && has('GUI_GTK')
    " XIMの入力開始キーを設定:
    " 下記の s-space はShift+Spaceの意味でkinput2+canna用設定
    "set imactivatekey=s-space
  endif
  " 挿入モードでのIME状態を記憶させない場合、次行のコメントを解除
  "inoremap <silent> <ESC> <ESC>:set iminsert=0<CR>
endif

"
" MacVim-KaoriYa固有の設定
"
let $SSH_ASKPASS = simplify($VIM . '/../../MacOS') . '/macvim-askpass'
set noimdisable
" set imdisableactivate
