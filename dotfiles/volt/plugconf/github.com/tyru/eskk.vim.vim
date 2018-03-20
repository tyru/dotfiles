
function! s:config()
  " augroup vimrc-eskk-vimenter
  "   autocmd!
  "   autocmd VimEnter *
  "   \   let &statusline .= '%( | %{exists("g:loaded_autoload_eskk") ? eskk#statusline("IM:%s", "IM:off") : ""}%)' |
  "   \   autocmd! vimrc-eskk-vimenter
  " augroup END

  " skkdict
  let skk_user_dict = '~/.skkdict/user-dict'
  let skk_user_dict_encoding = 'utf-8'
  let skk_system_dict = '~/.skkdict/system-dict'
  let skk_system_dict_encoding = 'euc-jp'

  let g:eskk#dictionary = {
  \   'path': skk_user_dict,
  \   'encoding': skk_user_dict_encoding,
  \}
  let g:eskk#large_dictionary = {
  \   'path': skk_system_dict,
  \   'encoding': skk_system_dict_encoding,
  \}
  " let g:eskk#server = {
  " \   'host': 'localhost',
  " \   'port': 1178,
  " \}

  " let g:eskk#log_cmdline_level = 2
  " let g:eskk#log_file_level = 4
endfunction
