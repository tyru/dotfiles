
let g:netrw_nogx = 1
Map -remap [nx] gx <Plug>(openbrowser-smart-search)
MapAlterCommand o[pen] OpenBrowserSmartSearch
" MapAlterCommand alc OpenBrowserSmartSearch -alc

" let g:openbrowser_open_filepath_in_vim = 0
if $VIMRC_USE_VIMPROC !=# 2
    let g:openbrowser_use_vimproc = $VIMRC_USE_VIMPROC
endif
" let g:openbrowser_force_foreground_after_open = 1

command! OpenBrowserCurrent execute "OpenBrowser" "file:///" . expand('%:p:gs?\\?/?')
