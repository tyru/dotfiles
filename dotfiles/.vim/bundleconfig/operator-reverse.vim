let s:config = BundleConfigGet()

function! s:config.config()
    Map -remap [nxo] <operator>rl <Plug>(operator-reverse-lines)
    Map -remap [nxo] <operator>rw <Plug>(operator-reverse-text)
endfunction