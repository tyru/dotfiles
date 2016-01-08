" Don't set scriptencoding before 'encoding' option is set!
" scriptencoding utf-8

" vim:set et fen fdm=marker:

" See also: ~/.vimrc or ~/_vimrc



" let $VIMRC_DEBUG = 1
" let $VIMRC_DISABLE_MYAUTOCMD = 1
" let $VIMRC_DISABLE_VIMENTER = 1
" let $VIMRC_LOAD_NO_PLUGINS = 1

" 0: vimproc disabled
" 1: vimproc enabled
" 2: plugin default(auto)
if !exists('$VIMRC_USE_VIMPROC')
    let $VIMRC_USE_VIMPROC = 1
endif
if !exists('$VIMRC_FORCE_LANG_C')
    let $VIMRC_FORCE_LANG_C = 0
endif
if !exists('$VIMRC_LOAD_MENU')
    let $VIMRC_LOAD_MENU = 1
endif


" Basic {{{

" Reset all options
set all&

" Reset auto-commands
augroup vimrc
    autocmd!
augroup END


" TODO Clear mappings mapped only in vimrc, but plugin mappings.
" mapclear
" mapclear!
" " mapclear!!!!
" lmapclear


if $VIMRC_FORCE_LANG_C
    language messages C
    language time C
endif

if $VIMRC_LOAD_MENU
    " Load current locale and &encoding menu.
    set guioptions+=m
else
    set guioptions+=M
    let did_install_default_menus = 1
    let did_install_syntax_menu = 1
endif

filetype plugin indent on

if filereadable(expand('~/.vimrc.local'))
    execute 'source' expand('~/.vimrc.local')
endif

" }}}
" Utilities {{{

" Export variables/functions {{{

let g:VIMRC = {}

" }}}

" Constants {{{
let s:is_win = has('win16') || has('win32') || has('win64') || has('win95')
let s:is_unix_terminal = !s:is_win && has('unix') && !has('gui_running')
let g:VIMRC.is_win = s:is_win
let g:VIMRC.is_unix_terminal = s:is_unix_terminal
" }}}

" Function {{{

function! s:SID() "{{{
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction "}}}
let s:SNR_PREFIX = '<SNR>' . s:SID() . '_'
function! s:SNR(map) "{{{
    return s:SNR_PREFIX . a:map
endfunction "}}}

" e.g.) s:has_plugin('eskk') ? 'yes' : 'no'
"       s:has_plugin('indent/vim.vim') ? 'yes' : 'no'
function! s:has_plugin(name)
    let nosuffix = a:name =~? '\.vim$' ? a:name[:-5] : a:name
    let nosuffix = s:toslash(nosuffix)
    let suffix   = a:name =~? '\.vim$' ? a:name      : a:name . '.vim'
    let suffix   = s:toslash(suffix)
    return &rtp =~# '\c\<' . nosuffix . '\>'
    \   || globpath(&rtp, suffix, 1) != ''
    \   || globpath(&rtp, nosuffix, 1) != ''
    \   || globpath(&rtp, 'autoload/' . suffix, 1) != ''
    \   || globpath(&rtp, 'autoload/' . tolower(suffix), 1) != ''
endfunction

function! s:toslash(path) "{{{
    return substitute(a:path, '\', '/', 'g')
endfunction "}}}

function! s:echomsg(hl, msg) "{{{
    execute 'echohl' a:hl
    try
        echomsg a:msg
    finally
        echohl None
    endtry
endfunction "}}}
function! s:warn(msg) "{{{
    call s:echomsg('WarningMsg', a:msg)
endfunction "}}}
function! s:error(msg) "{{{
    call s:echomsg('ErrorMsg', a:msg)
endfunction "}}}

function! s:splitmapjoin(str, pattern, expr, sep)
    return join(map(split(a:str, a:pattern, 1), a:expr), a:sep)
endfunction
function! s:map_lines(str, expr)
    return s:splitmapjoin(a:str, '\n', a:expr, "\n")
endfunction


" Quickfix utility functions {{{
function! s:quickfix_get_winnr()
    " quickfix window is usually at bottom,
    " thus reverse-lookup.
    for winnr in reverse(range(1, winnr('$')))
        if getwinvar(winnr, '&buftype') ==# 'quickfix'
            return winnr
        endif
    endfor
    return 0
endfunction
function! s:quickfix_exists_window()
    return !!s:quickfix_get_winnr()
endfunction
function! s:quickfix_supported_quickfix_title()
    return s:Compat.has_version('7.3')
endfunction
function! s:quickfix_get_search_word()
    " NOTE: This function returns a string starting with "/"
    " if previous search word is found.
    " This function can't use an empty string
    " as a failure return value, because ":vimgrep /" also returns an empty string.

    " w:quickfix_title only works 7.3 or later.
    if !s:quickfix_supported_quickfix_title()
        return ''
    endif

    let qf_winnr = s:quickfix_get_winnr()
    if !qf_winnr
        copen
    endif

    try
        let qf_title = getwinvar(qf_winnr, 'quickfix_title')
        if qf_title ==# ''
            return ''
        endif

        " NOTE: Supported only :vim[grep] command.
        let rx = '^:\s*\<vim\%[grep]\>\s*\(/.*\)'
        let m = matchlist(qf_title, rx)
        if empty(m)
            return ''
        endif

        return m[1]
    finally
        if !qf_winnr
            cclose
        endif
    endtry
endfunction

let g:VIMRC.quickfix_exists_window = function(s:SNR('quickfix_exists_window'))

" }}}

" }}}

" Commands {{{

command!
\   -bar -nargs=1
\   Nop
\   command! -bar -bang -nargs=* <args> :



" :autocmd is listed in |:bar|
command! -bang -nargs=* VimrcAutocmd autocmd<bang> vimrc <args>

if exists('$VIMRC_DISABLE_MYAUTOCMD')
    Nop VimrcAutocmd
endif



command!
\   -nargs=+
\   Lazy
\   call s:cmd_lazy(<q-args>)

if exists('$VIMRC_DISABLE_VIMENTER')
    Nop Lazy
endif

function! s:cmd_lazy(q_args) "{{{
    if a:q_args == ''
        return
    endif
    if VimStarting()
        execute 'VimrcAutocmd VimEnter *'
        \       join([
        \           'try',
        \               'execute '.string(a:q_args),
        \           'catch',
        \               'call StartDebugMode(' . string(expand('<sfile>:p')) . ')',
        \           'endtry',
        \       ], " | ")
    else
        execute a:q_args
    endif
endfunction "}}}

" }}}

" }}}
" Encoding {{{
let s:enc = 'utf-8'

let &enc = s:enc
let &fenc = s:enc
let &termencoding = s:enc
let s:fencs = [s:enc] + split(&fileencodings, ',') + ['iso-2022-jp', 'iso-2022-jp-3', 'cp932']
let &fileencodings = join(filter(s:fencs, 'count(s:fencs, v:val) == 1'), ',')

unlet s:fencs
unlet s:enc

scriptencoding utf-8

set fileformats=unix,dos,mac
if exists('&ambiwidth')
    set ambiwidth=double
endif

" }}}
" Load Plugins {{{

" Load vim-rtputil {{{
set rtp+=$MYVIMDIR/macros/vim-rtputil
" }}}

" ... {{{
let s:loading_bundleconfig = {}
let s:bundleconfig = {}
let s:plugins = rtputil#new()
call s:plugins.reset()

function! s:cmd_load_plugin(args, now)
    for path in a:args
        if !isdirectory(expand(path))
            call s:error(path . ": no such a bundle directory")
            return
        endif
        let nosufname = s:get_no_suffix_name(path)
        let bcconf = {
        \   'path': path, 'name': nosufname,
        \   'done': 0, 'disabled': 0,
        \   'userconf': {},
        \}
        " To load $MYVIMDIR/bundleconfig/<name>.vim
        let s:bundleconfig[nosufname] = bcconf
        if a:now
            " Change 'runtimepath' immediately.
            call rtputil#append(path)
        else
            " Change 'runtimepath' later.
            call s:plugins.append(path)
        endif
    endfor
endfunction

function! s:cmd_disable_plugin(args)
    let pattern = a:args[0]
    let nosufname = s:get_no_suffix_name(pattern)
    " To load $MYVIMDIR/bundleconfig/<name>.vim
    if has_key(s:bundleconfig, nosufname)
        unlet s:bundleconfig[nosufname]
    endif
    " Change 'runtimepath' later.
    call s:plugins.remove('\<' . pattern . '\>')
endfunction

function! s:get_no_suffix_name(path)
    let nosufname = substitute(a:path, '.*[/\\]', '', '')
    let nosufname = substitute(nosufname, '\c[.-]vim$', '', '')
    let nosufname = substitute(nosufname, '\c^vim[.-]', '', '')
    return nosufname
endfunction

command! -nargs=0 LoadBundles
\     call s:cmd_load_plugin(glob('$MYVIMDIR/bundle/*', 1, 1), 0)

command! -nargs=+ LoadLater
\     call s:cmd_load_plugin([<args>], 0)

command! -nargs=+ LoadNow
\     call s:cmd_load_plugin([<args>], 1)

command! -nargs=+ DisablePlugin
\     call s:cmd_disable_plugin([<args>])

function! BundleConfigGet()
    if empty(s:loading_bundleconfig)
        call s:error("'BundleConfigGet()' is only allowed in bundleconfig file.")
        return {}
    endif
    let name = s:loading_bundleconfig.name
    let s:bundleconfig[name].userconf = deepcopy(s:BundleUserConfig)
    return s:bundleconfig[name].userconf
endfunction

let s:BundleUserConfig = {}
function! s:BundleUserConfig.config()
endfunction
function! s:BundleUserConfig.depends()
    return []
endfunction
function! s:BundleUserConfig.depends_commands()
    return []
endfunction
function! s:BundleUserConfig.recommends()
    return []
endfunction


" }}}

" Load fundamental plugins {{{
" TODO: Reduce dependency plugins.
LoadLater '$MYVIMDIR/bundle/tyru'
LoadLater '$MYVIMDIR/bundle/emap.vim'
LoadLater '$MYVIMDIR/bundle/vim-altercmd'
" }}}

if !exists('$VIMRC_LOAD_NO_PLUGINS')
" Load plugins unless $VIMRC_LOAD_NO_PLUGINS is defined {{{

" Load plugins {{{
if !exists('$VIMRC_DEBUG')

    " If vim is already up, send it given files by arguments
    LoadNow '$MYVIMDIR/bundle/vim-singleton'
    " PKGBUILDやinstall.sh
    " let g:singleton#entrust_pattern = {
    " \   'yaourt' : '^/tmp/yaourt-tmp-[^/]\+/',
    " \   'git' : 'GGGGGGGGGGGGGGGGGGGGG',
    " \}
    " let g:singleton#entrust_pattern = {
    " \   'yaourt' : '^/tmp/yaourt-tmp-[^/]\+/.\+/PKGBUILD$',
    " \}
    call singleton#enable()

    LoadBundles

    " Disable unused skk plugin.
    " DisablePlugin 'eskk'
    DisablePlugin 'skk'
else
    " Useful plugins for debug
    LoadLater '$MYVIMDIR/bundle/dutil.vim'
    LoadLater '$MYVIMDIR/bundle/vim-prettyprint'
    LoadLater '$MYVIMDIR/bundle/restart.vim'

    " Load plugins to debug
    " LoadLater '$MYVIMDIR/bundle/open-browser.vim'
    " LoadLater '$MYVIMDIR/bundle/eskk.vim'
    " LoadLater '$MYVIMDIR/bundle/neocomplete'
endif

" }}}

" }}}
endif

" Change 'runtimepath' {{{
filetype off
call s:plugins.apply()
filetype plugin indent on
" }}}

" Import emap.vim & altercmd.vim commands {{{

" Define :Map commands
call emap#load('noprefix')
" call emap#set_sid_from_vimrc()
" call emap#set_sid(s:SID())
call emap#set_sid_from_sfile(expand('<sfile>'))


" Define :MapAlterCommand commands
call altercmd#load()
command!
\   -bar -nargs=+
\   MapAlterCommand
\   CAlterCommand <args> | AlterCommand <cmdwin> <args>

" }}}

" Set up general prefix keys. {{{

DefMacroMap [nxo] orig q
DefMacroMap [ic] orig <C-g><C-o>

Map [n] <orig>q q

DefMacroMap [nxo] excmd <Space>
DefMacroMap [nxo] operator ;
DefMacroMap [n] window <C-w>
DefMacroMap [nxo] prompt ,t

let g:mapleader = ';'
Map [n] <Leader> <Nop>

Map [n] ;; ;
Map [n] ,, ,

let g:maplocalleader = '\'
Map [n] <LocalLeader> <Nop>

DefMacroMap [i] compl <C-g><C-g><C-g><C-g><C-g>
" }}}

" Load vimrc vital. {{{

let s:Vital = vital#of('vimrc')
let s:Prelude = s:Vital.import('Prelude')
let s:List = s:Vital.import('Data.List')
let s:Filepath = s:Vital.import('System.Filepath')
let s:File = s:Vital.import('System.File')
let s:Compat = s:Vital.import('Vim.Compat')
" let s:Mapping = ...   " is used by tyru#util#undo_ftplugin_helper
unlet s:Vital

let g:VIMRC.Compat = s:Compat

" }}}

" Load plugin-specific config (bundleconfig). {{{

function! s:bc_load()
    for bcconf in values(s:bundleconfig)
        call s:bc_do_source(bcconf)
    endfor
    for name in s:get_ordering_keys(s:bundleconfig)
        let bcconf = s:bundleconfig[name]
        if bcconf.done
            continue
        endif
        call s:bc_do_load(bcconf)
    endfor
endfunction
function! s:get_ordering_keys(bundleconfig)
    " Load in order?
    return keys(a:bundleconfig)
endfunction
function! s:bc_do_source(bcconf)
    let s:loading_bundleconfig = a:bcconf
    try
        execute 'runtime! bundleconfig/' . a:bcconf.name . '/**/*.vim'
        execute 'runtime! bundleconfig/' . a:bcconf.name . '*.vim'

        if has_key(a:bcconf.userconf, 'enable_if')
            let a:bcconf.disabled = !a:bcconf.userconf.enable_if()
        endif
        if has_key(a:bcconf.userconf, 'disable_if')
            let a:bcconf.disabled = a:bcconf.userconf.disable_if()
        endif
        if has_key(a:bcconf.userconf, 'depends_commands')
            let commands = a:bcconf.userconf.depends_commands()
            for cmd in type(commands) is type([]) ?
            \               commands : [commands]
                if !executable(cmd)
                    call s:error("[bundleconfig] " .
                    \            "'" . a:bcconf.name . "' requires " .
                    \            "command '" . cmd . "' but not in your PATH!")
                    let a:bcconf.disabled = 1
                    continue
                endif
            endfor
        endif
    catch
        call s:error('--- Sourcing ' . a:bcconf.path . ' ... ---')
        for msg in split(v:exception, '\n')
            call s:error(msg)
        endfor
        for msg in split(v:throwpoint, '\n')
            call s:error(msg)
        endfor
        call s:error('--- Sourcing ' . a:bcconf.path . ' ... ---')
    finally
        let s:loading_bundleconfig = {}
    endtry
endfunction
function! s:bc_do_load(bcconf)
    if a:bcconf.disabled
        return 0
    endif
    try
        if has_key(a:bcconf.userconf, 'depends')
            let depfail = []
            let depends = a:bcconf.userconf.depends()
            for depname in type(depends) is type([]) ? depends : [depends]
                if !s:bc_do_load(s:bundleconfig[depname])
                    let depfail += [depname]
                endif
            endfor
            if !empty(depfail)
                call s:error("Stop loading '" . a:bcconf.name . "' " .
                \            "due to load failed/disabled depending " .
                \            "plugin(s) [" . join(depfail, ', ') . "]")
                return 0
            endif
        endif
        if has_key(a:bcconf.userconf, 'config')
            let s:loading_bundleconfig = a:bcconf
            call a:bcconf.userconf.config()
        endif
    catch
        call s:error('--- Loading ' . a:bcconf.path . ' ... ---')
        for msg in split(v:exception, '\n')
            call s:error(msg)
        endfor
        for msg in split(v:throwpoint, '\n')
            call s:error(msg)
        endfor
        call s:error('--- Loading ' . a:bcconf.path . ' ... ---')
        return 0
    finally
        let s:loading_bundleconfig = {}
    endtry
    let a:bcconf.done = 1
    return 1
endfunction

call s:bc_load()
unlet s:bundleconfig

" }}}

" Open bundleconfig file. {{{

command! -nargs=+ -complete=customlist,CompleteEditBundleConfig
\   EditBundleConfig
\   call s:cmd_editbundleconfig(<q-args>)

function! s:cmd_editbundleconfig(args)
    let filename = expand(
    \   '$MYVIMDIR/bundleconfig/' . a:args
    \   . (a:args !~? '\.vim$' ? '.vim' : ''))
    drop `=filename`
endfunction

function! CompleteEditBundleConfig(arglead, _l, _p)
    let dirs = glob('$MYVIMDIR/bundleconfig/*', 1, 1)
    call map(dirs, 'substitute(v:val, ".*[/\\\\]", "", "")')
    if a:arglead !=# ''
        " wildcard -> regexp pattern
        let pattern = '^' . a:arglead
        let pattern = substitute(pattern, '\*', '.*', 'g')
        let pattern = substitute(pattern, '\\?', '.', 'g')
        call filter(dirs, 'v:val =~# pattern')
    endif
    return dirs
endfunction

" }}}

" Generate helptags. {{{

" TODO: Execute once per a day.
command! -bar -bang HelpTagsAll call rtputil#helptags(<bang>0)
HelpTagsAll

" }}}

" ... {{{
delcommand LoadLater
delcommand LoadNow
delcommand DisablePlugin
unlet s:plugins
" }}}

" }}}
" Options {{{

" indent
set autoindent
set noexpandtab
set smarttab
set shiftround
set copyindent
set preserveindent
if exists('+breakindent')
    set breakindent
endif

" Follow 'tabstop' value.
set tabstop=4
let &shiftwidth = s:Compat.has_version('7.3.629') ? 0 : &ts
let &softtabstop = s:Compat.has_version('7.3.693') ? -1 : &ts

" search
set hlsearch
set incsearch
set smartcase

" Aesthetic options
set list
" Assumption: Trailing spaces are already highlighted and noticeable.
" set listchars=tab:>.,extends:>,precedes:<,eol:$
set listchars=tab:>.,extends:>,precedes:<
set display=lastline

" scroll
set scroll=5
" set scrolloff=15
" set scrolloff=9999
set scrolloff=0
" let g:scrolloff = 15    " see below

let g:scrolloff = 0
if g:scrolloff ># 0
    " Hack for <LeftMouse> not to adjust ('scrolloff') when single-clicking.
    " Implement 'scrolloff' by auto-command to control the fire.
    " cf. http://vim-users.jp/2011/04/hack213/
    VimrcAutocmd CursorMoved * call s:reinventing_scrolloff()
    let s:last_lnum = -1
    function! s:reinventing_scrolloff()
        if g:scrolloff ==# 0 || s:last_lnum > 0 && line('.') ==# s:last_lnum
            return
        endif
        let s:last_lnum = line('.')
        let winline     = winline()
        let winheight   = winheight(0)
        let middle      = winheight / 2
        let upside      = (winheight / winline) >= 2
        " If upside is true, add winlines to above the cursor.
        " If upside is false, add winlines to under the cursor.
        if upside
            let up_num = g:scrolloff - winline + 1
            let up_num = winline + up_num > middle ? middle - winline : up_num
            if up_num > 0
                execute 'normal!' up_num."\<C-y>"
            endif
        else
            let down_num = g:scrolloff - (winheight - winline)
            let down_num = winline - down_num < middle ? winline - middle : down_num
            if down_num > 0
                execute 'normal!' down_num."\<C-e>"
            endif
        endif
    endfunction

    " Do not adjust current scroll position (do not fire 'scrolloff') on single-click.
    Map -silent [n] <LeftMouse>   <Esc>:set eventignore=all<CR><LeftMouse>:set eventignore=<CR>
endif

" mouse
set mouse=a
set mousefocus
set mousehide
set mousemodel=popup

" command-line
set cmdheight=1
set wildmenu

" completion
set complete=.,w,b,u,t,i,d,k,kspell
set pumheight=20

" tags
if has('path_extra')
    set tags+=.;
    set tags+=tags;
endif
set showfulltag
set notagbsearch

" cscope
if 0
    set cscopetag
    set cscopeverbose
endif

" virtualedit
if has('virtualedit')
    set virtualedit=all
endif

" Swapfile
if 0
    " TODO: Use swapfile.
    let &directory = $MYVIMDIR.'/info/swap/'.v:servername
    silent! call mkdir(&directory, 'p', 0700)
    VimrcAutocmd VimLeave * call s:cleanup_swap_files()
    function! s:cleanup_swap_files()
        try
            call s:File.rmdir(&directory)
        catch
            " TODO
            " * Move remaining swap files to swap dir for recovery.
            " * If there are swap files in swap dir for recovery,
            "   Show recovery prompt at Vim startup.
            " * Do recovery!
        endtry
    endfunction

    " Open a file as read-only if swap exists
    " VimrcAutocmd SwapExists * let v:swapchoice = 'o'
else
    " No swapfile.
    set noswapfile
    set updatecount=0
endif

" backup (:help backup-table)
set backup
set backupcopy=yes
set backupdir=$MYVIMDIR/backup
silent! call mkdir(&backupdir, 'p')

function! SandboxCallOptionFn(option_name) "{{{
    try
        return s:{a:option_name}()
    catch
        call setbufvar('%', '&' . a:option_name, '')
        return ''
    endtry
endfunction "}}}

" title
set title
let &titlestring = '%{getcwd()}'

" tab
set showtabline=2

function! MyTabLabel(tabnr) "{{{
    if exists('*gettabvar')
        let title = gettabvar(a:tabnr, 'title')
        if title != ''
            return title
        endif
    endif

    let buflist = tabpagebuflist(a:tabnr)
    let bufname = bufname(buflist[tabpagewinnr(a:tabnr) - 1])
    let bufname = fnamemodify(bufname, ':t')
    " let bufname = pathshorten(bufname)
    let modified = 0
    for bufnr in buflist
        if getbufvar(bufnr, '&modified')
            let modified = 1
            break
        endif
    endfor

    if bufname == ''
        let label = '[No Name]'
    else
        let label = bufname
    endif
    return label . (modified ? '[+]' : '')
endfunction "}}}
function! s:tabline() "{{{
    let s = ''
    for i in range(tabpagenr('$'))
        " select the highlighting
        if i + 1 == tabpagenr()
            let s .= '%#TabLineSel#'
        else
            let s .= '%#TabLine#'
        endif

        " set the tab page number (for mouse clicks)
        let s .= '%' . (i + 1) . 'T'

        " the label is made by MyTabLabel()
        let s .= ' %{MyTabLabel(' . (i + 1) . ')} '
    endfor

    " after the last tab fill with TabLineFill and reset tab page nr
    let s .= '%#TabLineFill#%T'

    " right-align the label to close the current tab page
    if tabpagenr('$') > 1
        let s .= '%=%#TabLine#%999XX'
    endif

    return s
endfunction "}}}
set tabline=%!SandboxCallOptionFn('tabline')

function! s:guitablabel() "{{{
    return MyTabLabel(v:lnum)
endfunction "}}}
set guitablabel=%!SandboxCallOptionFn('guitablabel')

" statusline
set laststatus=2
let s:has_cfi = s:has_plugin('current-func-info')
function! s:statusline() "{{{
    let s = '%f%([%M%R%H%W]%)%(, %{&ft}%), %{&fenc}/%{&ff}'
    let s .= '%('

    if exists('g:loaded_eskk')    " eskk.vim
        " postpone the load of autoload/eskk.vim
        if exists('g:loaded_autoload_eskk')
            let s .= ' %{eskk#statusline("IM:%s", "IM:off")}'
        endif
    elseif exists('g:skk_loaded')    " skk.vim
        let s .= ' %{SkkGetModeStr()}'
    endif

    if !get(g:, 'cfi_disable') && s:has_cfi
        let s .= '%( | %{cfi#format("%s()", "")}%)'
    endif

    " NOTE: calling GetCCharAndHex() destroys also unnamed register. it may be the problem of Vim.
    " let s .= '%( | [%{GetCCharAndHex()}]%)'

    let s .= '%( | %{GetDocumentPosition()}%)'

    let s .= '%)'

    return s
endfunction "}}}
set statusline=%!SandboxCallOptionFn('statusline')

function! GetDocumentPosition()
    return float2nr(str2float(line('.')) / str2float(line('$')) * 100) . "%"
endfunction

function! GetCCharAndHex()
    if mode() !=# 'n'
        return ''
    endif
    if foldclosed(line('.')) isnot -1
        return ''
    endif
    let cchar = s:get_cchar()
    return cchar ==# '' ? '' : cchar . ":" . "0x".char2nr(cchar)
endfunction
function! s:get_cchar()
    let reg     = getreg('z', 1)
    let regtype = getregtype('z')
    try
        if col('.') ==# col('$') || virtcol('.') > virtcol('$')
            return ''
        endif
        normal! "zyl
        return @z
    catch
        return ''
    finally
        call setreg('z', reg, regtype)
    endtry
endfunction

" 'guioptions' flags are set on FocusGained
" because "cmd.exe start /min" doesn't work.
" (always start up as foreground)
augroup vimrc-guioptions
    autocmd!
augroup END
if VimStarting()
    command! -nargs=* AutocmdWhenVimStarting    autocmd vimrc-guioptions FocusGained * <args>
    command! -nargs=* AutocmdWhenVimStartingEnd autocmd vimrc-guioptions FocusGained * autocmd! vimrc-guioptions
else
    command! -nargs=* AutocmdWhenVimStarting    <args>
    command! -nargs=* AutocmdWhenVimStartingEnd :
endif

" Must be set in .vimrc
" set guioptions+=p
AutocmdWhenVimStarting set guioptions-=a
AutocmdWhenVimStarting set guioptions+=A
" Include 'e': tabline
" Otherwise  : guitablabel
" AutocmdWhenVimStarting set guioptions-=e
AutocmdWhenVimStarting set guioptions+=h
AutocmdWhenVimStarting set guioptions+=m
AutocmdWhenVimStarting set guioptions-=L
AutocmdWhenVimStarting set guioptions-=T
AutocmdWhenVimStartingEnd

delcommand AutocmdWhenVimStarting
delcommand AutocmdWhenVimStartingEnd

" clipboard
"
" TODO: hmm... I want normal "y" operation to use unnamed register also...
" (namely, I want to merge the registers, '"', '+', '*')
" Are there another solutions but overwriting mappings 'y', 'd', 'c', etc.
"
" set clipboard+=unnamed
" if has('unnamedplus')
"     set clipboard+=unnamedplus
" endif

" &migemo
if has("migemo")
    set migemo
endif

" convert "\\" to "/" on win32 like environment
if exists('+shellslash')
    set shellslash
endif

" visual bell
set novisualbell
Lazy set t_vb=

" set debug=beep

" restore screen
set norestorescreen
set t_ti=
set t_te=

" timeout
set notimeout

" fillchars
" TODO Change the color of inactive statusline.
set fillchars=stl:\ ,stlnc::,vert:\ ,fold:-,diff:-

" cursor behavior in insertmode
set whichwrap=b,s
set backspace=indent,eol,start
set formatoptions=mMcroqnl2
if s:Compat.has_version('7.3.541')
    set formatoptions+=j
endif

" undo-persistence
if has('persistent_undo')
    set undofile
    let &undodir = $MYVIMDIR . '/info/undo'
    silent! call mkdir(&undodir, 'p')
endif

if has('conceal')
    set concealcursor=nvic
endif

if version >=# 704
    set regexpengine=2
endif

" For screen.
if &term =~ "^screen"
    VimrcAutocmd VimLeave * :set mouse=

    " workaround for freeze when using mouse on GNU screen.
    set ttymouse=xterm2
endif


set browsedir=current

" Font {{{
if has('gui_running')
    if s:is_win
        if exists('+renderoptions')
            " If 'renderoptions' option exists,
            set renderoptions=type:directx,renmode:5
            " ... and if "Ricty_Diminished" font is installed,
            " enable DirectWrite.
            try
            set gfn=Ricty_Diminished_Discord:h14:cSHIFTJIS
            catch | endtry
        endif
    elseif has('mac')    " Mac
        set guifont=Osaka－等幅:h14
        set printfont=Osaka－等幅:h14
    else    " *nix OS
        try
            set guifont=Monospace\ 12
            set printfont=Monospace\ 12
            set linespace=0
        catch
            set guifont=Monospace\ 12
            set printfont=Monospace\ 12
            set linespace=4
        endtry
    endif
endif
" }}}

" misc.
set diffopt=filler,vertical
set history=50
set keywordprg=
" set lazyredraw
set nojoinspaces
set showcmd
set nrformats=hex
set shortmess=aI
set switchbuf=useopen,usetab
set textwidth=78
set colorcolumn=80
set viminfo='50,h,f1,n$HOME/.viminfo
set matchpairs+=<:>
set number
set showbreak=...
set confirm
set updatetime=500
if has('path_extra')
    set path+=.;
endif
" }}}
" ColorScheme {{{

" NOTE: On MS Windows, setting colorscheme in .vimrc does not work.
" Because :Lazy is necessary.
" FIXME: `:Lazy colorscheme tyru` does not throw ColorScheme event,
" what the fxck?
Lazy colorscheme tyru | doautocmd ColorScheme

" }}}
" Mappings, Abbreviations {{{


" TODO
"
" MapOriginal:
"   MapOriginal j
"   MapOriginal k
"
" MapPrefix:
"   MapPrefix [n] prefix_name rhs
"
" MapLeader:
"   MapLeader ;
"
" MapLocalLeader:
"   MapLocalLeader ,
"
" MapOp:
"   " Map [nxo] lhs rhs
"   MapOp lhs rhs
"
" MapMotion:
"   " Map [nxo] lhs rhs
"   MapMotion lhs rhs
"
" MapObject:
"   " Map [xo] lhs rhs
"   MapObject lhs rhs
"
" DisableMap:
"   " Map [n] $ <Nop>
"   " Map [n] % <Nop>
"   " .
"   " .
"   " .
"   DisableMap [n] $ % & ' ( ) ^
"
" MapCount:
"   " Map -expr [n] <C-n> v:count1 . 'gt'
"   MapCount [n] <C-n> gt



" map {{{
" operator {{{

" Copy to clipboard, primary.
Map [nxo] <operator>y     "+y
Map [nxo] <operator>gy    "*y
Map [nxo] <operator>d     "+d
Map [nxo] <operator>gd    "*d


" Do not destroy noname register.
Map [nxo] x "_x


Map [nxo] <operator>e =

" }}}
" motion {{{
Map -expr [nxo] j v:count == 0 ? 'gj' : 'j'
Map -expr [nxo] k v:count == 0 ? 'gk' : 'k'

Map [nxo] <orig>j j
Map [nxo] <orig>k k

" FIXME: Does not work in visual mode.
Map [n] ]k :<C-u>call search('^\S', 'Ws')<CR>
Map [n] [k :<C-u>call search('^\S', 'Wsb')<CR>

Map [nxo] gp %
" }}}
" textobj {{{
let g:textobj_between_no_default_key_mappings = 1
Map -remap [xo] ib <Plug>(textobj-between-i)
Map -remap [xo] ab <Plug>(textobj-between-a)

let g:textobj_entire_no_default_key_mappings = 1
Map -remap [xo] i@ <Plug>(textobj-entire-i)
Map -remap [xo] a@ <Plug>(textobj-entire-a)

Map [xo] aa a>
Map [xo] ia i>
Map [xo] ar a]
Map [xo] ir i]
" }}}
" }}}
" nmap {{{

DefMacroMap [nxo] fold z

" Open only current line's fold.
Map [n] <fold><Space> zMzvzz

" Folding mappings easy to remember.
Map [n] <fold>l zo
Map [n] <fold>h zc

" +virtualedit
if has('virtualedit')
    Map -expr [n] i col('$') is col('.') ? 'A' : 'i'
    Map -expr [n] a col('$') is col('.') ? 'A' : 'a'
    Map       [n] <orig>i i
    Map       [n] <orig>a a
endif

" http://vim-users.jp/2009/08/hack57/
Map [n] d<CR> :<C-u>call append(line('.'), '')<CR>j
Map [n] c<CR> :<C-u>call append(line('.'), '')<CR>jI

Map [n] <excmd>me :<C-u>messages<CR>
Map [n] <excmd>di :<C-u>display<CR>

Map [n] gl :<C-u>cnext<CR>
Map [n] gh :<C-u>cNext<CR>

Map [n] <excmd>ct :<C-u>tabclose<CR>

Map [n] <excmd>tl :<C-u>tabedit<CR>
Map [n] <excmd>th :<C-u>tabedit<CR>:execute 'tabmove' (tabpagenr() isnot 1 ? tabpagenr() - 2 : '')<CR>

if has('gui_running')
    Map -script [i] <C-s> <SID>(gui-save)<Esc>
    Map -script [n] <C-s> <SID>(gui-save)
    Map -script [i] <SID>(gui-save) <C-o><SID>(gui-save)
    Map         [n] <SID>(gui-save) :<C-u>call <SID>gui_save()<CR>
    function! s:gui_save()
        if bufname('%') ==# ''
            browse confirm saveas
        else
            update
        endif
    endfunction
endif

Map -expr -silent [n] f <SID>search_char('/\V%s'."\<CR>:nohlsearch\<CR>")
Map -expr -silent [n] F <SID>search_char('?\V%s'."\<CR>:nohlsearch\<CR>")
Map -expr -silent [n] t <SID>search_char('/.\ze\V%s'."\<CR>:nohlsearch\<CR>")
Map -expr -silent [n] T <SID>search_char('?\V%s\v\zs.'."\<CR>:nohlsearch\<CR>")

function! s:search_char(cmdfmt)
    let char = s:Prelude.getchar_safe()
    return char ==# "\<Esc>" ? '' : printf(a:cmdfmt, char)
endfunction


" Map [n] <C-h> b
" Map [n] <C-l> w
" Map [n] <S-h> ge
" Map [n] <S-l> e

" NOTE: <S-Tab> is GUI only.
Map [x] <Tab> >gv
Map [x] <S-Tab> <gv

Map [o] gv :<C-u>normal! gv<CR>

Map [nxo] H ^
Map [nxo] L $

" See also chdir-proj-root.vim settings.
Map [n] ,cd       :<C-u>cd %:p:h<CR>

" TODO: Smart 'zd': Delete empty line {{{
" }}}
" TODO: Smart '{', '}': Treat folds as one non-empty line. {{{
" }}}

" Execute most used command quickly {{{
Map [n] <excmd>ee     :<C-u>edit<CR>
Map [n] <excmd>w      :<C-u>update<CR>
Map -silent [n] <excmd>q      :<C-u>call <SID>vim_never_die_close()<CR>

function! s:vim_never_die_close()
    try
        close
    catch
        if !&modified
            bwipeout!
        endif
    endtry
endfunction
" }}}
" Edit/Apply .vimrc quickly {{{
Map [n] <excmd>ev     :<C-u>edit $MYVIMRC<CR>
if has('gui_running')
    Map [n] <excmd>sv     :<C-u>source $MYVIMRC<CR>:source $MYGVIMRC<CR>
else
    Map [n] <excmd>sv     :<C-u>source $MYVIMRC<CR>
endif
" }}}
" Cmdwin {{{
set cedit=<C-z>
function! s:cmdwin_enter()
    Map -buffer -force       [ni] <C-z>         <C-c>
    Map -buffer              [n]  <Esc> :<C-u>quit<CR>
    Map -buffer -force       [n]  <window>k        :<C-u>quit<CR>
    Map -buffer -force       [n]  <window><C-k>    :<C-u>quit<CR>
    Map -buffer -force -expr [i]  <BS>       col('.') == 1 ? "\<Esc>:quit\<CR>" : "\<BS>"

    startinsert!
endfunction
VimrcAutocmd CmdwinEnter * call s:cmdwin_enter()

Map [n] <excmd>: q:
Map [n] <excmd>/ q/
Map [n] <excmd>? q?
" }}}
" Moving tabs {{{
Map -silent [n] <Left>    :<C-u>execute 'tabmove' (tabpagenr() == 1 ? tabpagenr('$') : tabpagenr() - 2)<CR>
Map -silent [n] <Right>   :<C-u>execute 'tabmove' (tabpagenr() == tabpagenr('$') ? 0 : tabpagenr())<CR>
" NOTE: Mappings <S-Left>, <S-Right> work only in gVim
Map -silent [n] <S-Left>  :<C-u>execute 'tabmove' 0<CR>
Map -silent [n] <S-Right> :<C-u>execute 'tabmove' tabpagenr('$')<CR>
" }}}
" Toggle options {{{
function! s:toggle_option(option_name) "{{{
    if exists('&' . a:option_name)
        execute 'setlocal' a:option_name . '!'
        execute 'setlocal' a:option_name . '?'
    endif
endfunction "}}}

function! s:advance_state(state, elem) "{{{
    let curidx = index(a:state, a:elem)
    let curidx = curidx is -1 ? 0 : curidx
    return a:state[index(a:state, curidx + 1) isnot -1 ? curidx + 1 : 0]
endfunction "}}}

function! s:advance_option_state(state, optname) "{{{
    let varname = '&' . a:optname
    call setbufvar(
    \   '%',
    \   varname,
    \   s:advance_state(
    \       a:state,
    \       getbufvar('%', varname)))
    execute 'setlocal' a:optname . '?'
endfunction "}}}

function! s:toggle_winfix()
    if &winfixheight || &winfixwidth
        setlocal nowinfixheight nowinfixwidth
        echo 'released.'
    else
        setlocal winfixheight winfixwidth
        echo 'fixed!'
    endif
endfunction

Map [n] <excmd>oh :<C-u>call <SID>toggle_option('hlsearch')<CR>
Map [n] <excmd>oi :<C-u>call <SID>toggle_option('ignorecase')<CR>
Map [n] <excmd>op :<C-u>call <SID>toggle_option('paste')<CR>
Map [n] <excmd>ow :<C-u>call <SID>toggle_option('wrap')<CR>
Map [n] <excmd>oe :<C-u>call <SID>toggle_option('expandtab')<CR>
Map [n] <excmd>ol :<C-u>call <SID>toggle_option('list')<CR>
Map [n] <excmd>on :<C-u>call <SID>toggle_option('number')<CR>
Map [n] <excmd>om :<C-u>call <SID>toggle_option('modeline')<CR>
Map [n] <excmd>ofc :<C-u>call <SID>advance_option_state(['', 'all'], 'foldclose')<CR>
Map [n] <excmd>ofm :<C-u>call <SID>advance_option_state(['manual', 'marker', 'indent'], 'foldmethod')<CR>
Map [n] <excmd>ofw :<C-u>call <SID>toggle_winfix()<CR>

" }}}
" Close help/quickfix window {{{

" s:winutil {{{
unlet! s:winutil
let s:winutil = {}

function! s:winutil.close(winnr) "{{{
    if s:winutil.exists(a:winnr)
        execute a:winnr . 'wincmd w'
        execute 'wincmd c'
        return 1
    else
        return 0
    endif
endfunction "}}}

function! s:winutil.exists(winnr) "{{{
    return winbufnr(a:winnr) !=# -1
endfunction "}}}


function! s:winutil.get_winnr_list_like(expr) "{{{
    let ret = []
    for winnr in range(1, winnr('$'))
        if eval(a:expr)
            call add(ret, winnr)
        endif
    endfor
    return ret
endfunction "}}}

function! s:winutil.has_window_like(expr) "{{{
    return !empty(s:winutil.get_winnr_list_like(a:expr))
endfunction "}}}

function! s:winutil.close_first_like(expr) "{{{
    let winnr_list = s:winutil.get_winnr_list_like(a:expr)
    " Close current window if current matches a:expr.
    let winnr_list = s:move_current_winnr_to_head(winnr_list)
    if empty(winnr_list)
        return
    endif

    let prev_winnr = winnr()
    try
        for winnr in winnr_list
            if s:winutil.close(winnr)
                return 1    " closed.
            endif
        endfor
        return 0
    finally
        " Back to previous window.
        let cur_winnr = winnr()
        if cur_winnr !=# prev_winnr && winbufnr(prev_winnr) !=# -1
            execute prev_winnr . 'wincmd w'
        endif
    endtry
endfunction "}}}

" TODO Simplify
function! s:move_current_winnr_to_head(winnr_list) "{{{
    let winnr = winnr()
    if index(a:winnr_list, winnr) is -1
        return a:winnr_list
    endif
    return [winnr] + filter(a:winnr_list, 'v:val isnot winnr')
endfunction "}}}

lockvar 1 s:winutil
" }}}

" s:window {{{
unlet! s:window
let s:window = {'_group_order': [], '_groups': {}}

function! s:window.register(group_name, functions) "{{{
    call add(s:window._group_order, a:group_name)
    let s:window._groups[a:group_name] = a:functions
endfunction "}}}

function! s:window.get_all_groups() "{{{
    return map(copy(s:window._group_order), 'deepcopy(s:window._groups[v:val])')
endfunction "}}}

lockvar 1 s:window
" }}}

" cmdwin {{{
let s:in_cmdwin = 0
VimrcAutocmd CmdwinEnter * let s:in_cmdwin = 1
VimrcAutocmd CmdwinLeave * let s:in_cmdwin = 0

function! s:close_cmdwin_window() "{{{
    if s:in_cmdwin
        quit
        return 1
    else
        return 0
    endif
endfunction "}}}
function! s:is_cmdwin_window(winnr) "{{{
    return s:in_cmdwin
endfunction "}}}

call s:window.register('cmdwin', {'close': function('s:close_cmdwin_window'), 'detect': function('s:is_cmdwin_window')})
" }}}

" help {{{
function! s:close_help_window() "{{{
    return s:winutil.close_first_like('s:is_help_window(winnr)')
endfunction "}}}
function! s:has_help_window() "{{{
    return s:winutil.has_window_like('s:is_help_window(winnr)')
endfunction "}}}
function! s:is_help_window(winnr) "{{{
    return getbufvar(winbufnr(a:winnr), '&buftype') ==# 'help'
endfunction "}}}

call s:window.register('help', {'close': function('s:close_help_window'), 'detect': function('s:is_help_window')})
" }}}

" quickfix {{{
function! s:close_quickfix_window() "{{{
    " cclose
    return s:winutil.close_first_like('s:is_quickfix_window(winnr)')
endfunction "}}}
function! s:is_quickfix_window(winnr) "{{{
    return getbufvar(winbufnr(a:winnr), '&buftype') ==# 'quickfix'
endfunction "}}}

call s:window.register('quickfix', {'close': function('s:close_quickfix_window'), 'detect': function('s:is_quickfix_window')})
" }}}

" ref {{{
function! s:close_ref_window() "{{{
    return s:winutil.close_first_like('s:is_ref_window(winnr)')
endfunction "}}}
function! s:is_ref_window(winnr) "{{{
    return getbufvar(winbufnr(a:winnr), '&filetype') ==# 'ref'
endfunction "}}}

call s:window.register('ref', {'close': function('s:close_ref_window'), 'detect': function('s:is_ref_window')})
" }}}

" quickrun {{{
function! s:close_quickrun_window() "{{{
    return s:winutil.close_first_like('s:is_quickrun_window(winnr)')
endfunction "}}}
function! s:is_quickrun_window(winnr) "{{{
    return getbufvar(winbufnr(a:winnr), '&filetype') ==# 'quickrun'
endfunction "}}}

call s:window.register('quickrun', {'close': function('s:close_quickrun_window'), 'detect': function('s:is_quickrun_window')})
" }}}

" unlisted {{{
function! s:close_unlisted_window() "{{{
    return s:winutil.close_first_like('s:is_unlisted_window(winnr)')
endfunction "}}}
function! s:is_unlisted_window(winnr) "{{{
    return !getbufvar(winbufnr(a:winnr), '&buflisted')
endfunction "}}}

call s:window.register('unlisted', {'close': function('s:close_unlisted_window'), 'detect': function('s:is_unlisted_window')})
" }}}


function! s:close_certain_window() "{{{
    let curwinnr = winnr()
    let groups = s:window.get_all_groups()

    " Close current.
    for group in groups
        if group.detect(curwinnr)
            call group.close()
            return
        endif
    endfor

    " Or close outside buffer.
    for group in groups
        if group.close()
            return 1
        endif
    endfor
endfunction "}}}


Map -silent [n] <excmd>c: :<C-u>call <SID>close_cmdwin_window()<CR>
Map -silent [n] <excmd>ch :<C-u>call <SID>close_help_window()<CR>
Map -silent [n] <excmd>cQ :<C-u>call <SID>close_quickfix_window()<CR>
Map -silent [n] <excmd>cr :<C-u>call <SID>close_ref_window()<CR>
Map -silent [n] <excmd>cq :<C-u>call <SID>close_quickrun_window()<CR>
Map -silent [n] <excmd>cb :<C-u>call <SID>close_unlisted_window()<CR>

Map -silent [n] <excmd>cc :<C-u>call <SID>close_certain_window()<CR>
" }}}
" 'Y' to yank till the end of line. {{{
Map [n] Y    y$
Map [n] ;Y   "+y$
Map [n] ,Y   "*y$
" }}}
" Back to col '$' when current col is right of col '$'. {{{
"
" 1. move to the last col
" when over the last col ('virtualedit') and getregtype(v:register) ==# 'v'.
" 2. do not insert " " before inserted text
" when characterwise and getregtype(v:register) ==# 'v'.

function! s:virtualedit_enabled()
    return has('virtualedit')
    \   && &virtualedit =~# '\<all\>\|\<onemore\>'
endfunction

if s:virtualedit_enabled()
    function! s:paste_characterwise_nicely()
        let reg = '"' . v:register
        let move_to_last_col =
        \   (s:virtualedit_enabled()
        \       && col('.') >= col('$'))
        \   ? '$' : ''
        let paste =
        \   reg . (getline('.') ==# '' ? 'P' : 'p')
        return getregtype(v:register) ==# 'v' ?
        \   move_to_last_col . paste :
        \   reg . 'p'
    endfunction

    Map -expr [n] p <SID>paste_characterwise_nicely()
endif
" }}}
" <Space>[hjkl] for <C-w>[hjkl] {{{
Map -silent [n] <Space>j <C-w>j
Map -silent [n] <Space>k <C-w>k
Map -silent [n] <Space>h <C-w>h
Map -silent [n] <Space>l <C-w>l
Map -silent [n] <Space>n <C-w>w
Map -silent [n] <Space>p <C-w>W
" }}}
" Moving between tabs {{{
Map -silent [n] <C-n> gt
Map -silent [n] <C-p> gT
" }}}
" Move all windows of current group beyond next group. {{{
" TODO
" }}}
" "Use one tabpage per project" project {{{
" :SetTabName - Set tab's title {{{

Map -silent [n] g<C-t> :<C-u>SetTabName<CR>
command! -bar -nargs=* SetTabName call s:cmd_set_tab_name(<q-args>)
function! s:cmd_set_tab_name(name) "{{{
    let old_title = exists('t:title') ? t:title : ''
    if a:name == ''
        " Hitting <Esc> returns empty string.
        let title = input('tab name?:', old_title)
        let t:title = title != '' ? title : old_title
    else
        let t:title = a:name
    endif
    if t:title !=# old_title
        " :redraw does not update tabline.
        redraw!
    endif
endfunction "}}}
" }}}
" }}}
" }}}
" vmap {{{

" Map [x] <C-g> g<C-g>1gs

Map -silent [x] y y:<C-u>call <SID>remove_trailing_spaces_blockwise()<CR>
function! s:remove_trailing_spaces_blockwise()
    let regname = v:register
    if getregtype(regname)[0] !=# "\<C-v>"
        return ''
    endif
    let value = getreg(regname, 1)
    let expr = 'substitute(v:val, '.string('\v\s+$').', "", "")'
    let value = s:map_lines(value, expr)
    call setreg(regname, value, "\<C-v>")
endfunction


" http://labs.timedia.co.jp/2012/10/vim-more-useful-blockwise-insertion.html
Map -expr [x] I <SID>force_blockwise_visual(<q-lhs>)
Map -expr [x] A <SID>force_blockwise_visual(<q-lhs>)

function! s:force_blockwise_visual(next_key)
    if mode() ==# 'v'
        return "\<C-v>" . a:next_key
    elseif mode() ==# 'V'
        return "\<C-v>0o$" . a:next_key
    else  " mode() ==# "\<C-v>"
        return a:next_key
    endif
endfunction


" Space key to indent (inspired by sakura editor)
Map [x] <Space><Space> <Esc>:call <SID>space_indent(0)<CR>gv
Map [x] <Space><BS> <Esc>:call <SID>space_indent(1)<CR>gv
Map -remap [x] <Space><S-Space> <Space><BS>

function! s:space_indent(leftward)
    let save = [&l:expandtab, &l:shiftwidth]
    setlocal expandtab shiftwidth=1
    execute 'normal!' (a:leftward ? 'gv<<' : 'gv>>')
    let [&l:expandtab, &l:shiftwidth] = save
endfunction

" }}}
" map! {{{
Map [ic] <C-f> <Right>
Map -expr [i] <C-b> col('.') ==# 1 ? "\<C-o>k\<End>" : "\<Left>"
Map [c] <C-b> <Left>
Map [ic] <C-a> <Home>
Map [ic] <C-e> <End>
Map [i] <C-d> <Del>
Map -expr [c] <C-d> getcmdpos()-1<len(getcmdline()) ? "\<Del>" : ""

if 0

    function! s:eclipse_like_autoclose(quote)
        if mode() !~# '^\(i\|R\|Rv\|c\|cv\|ce\)$'
            return a:quote
        endif
        return
        \   col('.') <=# 1 || col('.') >=# col('$') ?
        \       a:quote.a:quote."\<Left>" :
        \   getline('.')[col('.') - 1] ==# a:quote ?
        \       "\<Right>" :
        \   getline('.')[col('.') - 2] ==# a:quote ?
        \       a:quote.a:quote."\<Left>" :
        \       a:quote
    endfunction

    Map -expr [ic] " <SID>eclipse_like_autoclose('"')
    Map -expr [ic] ' <SID>eclipse_like_autoclose("'")

endif

" Excel-like keymapping ;)
Map [ic] <M-;> <C-r>=strftime('%Y/%m/%d')<CR>
Map [ic] <M-:> <C-r>=strftime('%H:%M')<CR>

" }}}
" imap {{{

Map [i] <C-l> <Tab>

" shift left (indent)
Map [i] <C-q>   <C-d>

" make <C-w> and <C-u> undoable.
" NOTE: <C-u> may be already mapped by $VIMRUNTIME/vimrc_example.vim
Map [i] <C-w> <C-g>u<C-w>
Map -force [i] <C-u> <C-g>u<C-u>

Map [i] <S-CR> <C-o>O
Map [i] <C-CR> <C-o>o

" completion {{{

Map [i] <compl><Tab> <C-n>

" Map [i] <compl>n <C-x><C-n>
" Map [i] <compl>p <C-x><C-p>
Map [i] <compl>n <C-n>
Map [i] <compl>p <C-p>

Map [i] <compl>] <C-x><C-]>
Map [i] <compl>d <C-x><C-d>
Map [i] <compl>f <C-x><C-f>
Map [i] <compl>i <C-x><C-i>
Map [i] <compl>k <C-x><C-k>
Map [i] <compl>l <C-x><C-l>
" Map [i] <compl>s <C-x><C-s>
" Map [i] <compl>t <C-x><C-t>

Map -expr [i] <compl>o <SID>omni_or_user_func()

function! s:omni_or_user_func() "{{{
    if &omnifunc != ''
        return "\<C-x>\<C-o>"
    elseif &completefunc != ''
        return "\<C-x>\<C-u>"
    else
        return "\<C-n>"
    endif
endfunction "}}}


" Map [i] <compl>j <C-n>
" Map [i] <compl>k <C-p>
" TODO
" call submode#enter_with('c', 'i', '', emap#compile_map('i', '<compl>j'), '<C-n>')
" call submode#enter_with('c', 'i', '', emap#compile_map('i', '<compl>k'), '<C-p>')
" call submode#leave_with('c', 'i', '', '<CR>')
" call submode#map       ('c', 'i', '', 'j', '<C-n>')
" call submode#map       ('c', 'i', '', 'k', '<C-p>')


" }}}
" }}}
" cmap {{{
if &wildmenu
    Map -force [c] <C-f> <Space><BS><Right>
    Map -force [c] <C-b> <Space><BS><Left>
endif

" paste register
Map [c] <C-r><C-u>  <C-r>+
Map [c] <C-r><C-i>  <C-r>*
Map [c] <C-r><C-o>  <C-r>"

Map [c] <C-n> <Down>
Map [c] <C-p> <Up>

Map [c] <C-l> <C-d>

" Escape /,? {{{
Map -expr [c] /  getcmdtype() == '/' ? '\/' : '/'
Map -expr [c] ?  getcmdtype() == '?' ? '\?' : '?'
" }}}
" }}}
" abbr {{{
Map -abbr -expr [i]  date@ strftime('%Y/%m/%d')
Map -abbr -expr [i]  time@ strftime("%H:%M")
Map -abbr -expr [i]  dt@   strftime("%Y/%m/%d %H:%M")
Map -abbr -expr [ic] mb@   [^\x01-\x7e]

MapAlterCommand th     tab help
MapAlterCommand t      tabedit
MapAlterCommand sf     setf
MapAlterCommand hg     helpgrep
MapAlterCommand ds     diffsplit
MapAlterCommand do     diffoff!

MapAlterCommand ba     breakadd
MapAlterCommand baf    breakadd func
MapAlterCommand bah    breakadd here

" For typo.
MapAlterCommand qw     wq
" }}}


Map [nx] <SID>(centering-display) zvzz

" Mappings with option value. {{{

" Use s:do_excmd() and <expr> mapping to make <C-o> work.
function! s:do_excmd(excmds, ret)
    for cmd in a:excmds
        execute cmd
    endfor
    return a:ret
endfunction

Map -expr [n] / <SID>do_excmd(['setlocal ignorecase hlsearch'], '/')
Map -expr [n] ? <SID>do_excmd(['setlocal ignorecase hlsearch'], '?')

Map -script -expr [n] * <SID>do_excmd(['setlocal noignorecase hlsearch'], '*<SID>(centering-display)')
Map -script -expr [n] # <SID>do_excmd(['setlocal noignorecase hlsearch'], '#<SID>(centering-display)')

Map -expr [n] : <SID>do_excmd(['setlocal hlsearch'], ':')
Map -expr [x] : <SID>do_excmd(['setlocal hlsearch'], ':')

Map -script -expr [n] gd <SID>do_excmd(['setlocal hlsearch'], 'gd<SID>(centering-display)')
Map -script -expr [n] gD <SID>do_excmd(['setlocal hlsearch'], 'gD<SID>(centering-display)')

" }}}
" Emacs like kill-line. {{{
Map -expr [i] <C-k> "\<C-g>u".(col('.') == col('$') ? '<C-o>gJ' : '<C-o>D')
Map [c] <C-k> <C-\>e getcmdpos() == 1 ? '' : getcmdline()[:getcmdpos()-2]<CR>
" }}}
" Make searching directions consistent {{{
" 'zv' is harmful for Operator-pending mode and it should not be included.
" For example, 'cn' is expanded into 'cnzv' so 'zv' will be inserted.

Map -expr [nx] <SID>(always-forward-n) (<SID>search_forward_p() ? 'n' : 'N')
Map -expr [nx] <SID>(always-backward-N) (<SID>search_forward_p() ? 'N' : 'n')
Map -expr [o]  <SID>(always-forward-n) <SID>search_forward_p() ? 'n' : 'N'
Map -expr [o]  <SID>(always-backward-N) <SID>search_forward_p() ? 'N' : 'n'

function! s:search_forward_p()
    return exists('v:searchforward') ? v:searchforward : 1
endfunction

" Mapping -> plugin specific mapping, misc. hacks
Map -remap [nx] n <SID>(always-forward-n)<SID>(centering-display)
Map -remap [nx] N <SID>(always-backward-N)<SID>(centering-display)
Map -remap [o] n <SID>(always-forward-n)
Map -remap [o] N <SID>(always-backward-N)

" }}}
" Disable unused keys. {{{
Map [n] <F1> <Nop>
Map [n] <C-F1> <Nop>
Map [n] <S-F1> <Nop>
Map [n] ZZ <Nop>
Map [n] ZQ <Nop>
Map [n] U  <Nop>
" }}}
" Expand abbreviation {{{
" http://gist.github.com/347852
" http://gist.github.com/350207

DefMap [i] -expr bs-ctrl-] getline('.')[col('.') - 2]    ==# "\<C-]>" ? "\<BS>" : ''
DefMap [c] -expr bs-ctrl-] getcmdline()[getcmdpos() - 2] ==# "\<C-]>" ? "\<BS>" : ''
Map -script [ic] <C-]>     <C-]><bs-ctrl-]>
" }}}
" Add current line to quickfix. {{{
command! -bar -range QFAddLine <line1>,<line2>call s:quickfix_add_range()

" ... {{{

function! s:quickfix_add_range() range
    for lnum in range(a:firstline, a:lastline)
        call s:quickfix_add_line(lnum)
    endfor
endfunction

function! s:quickfix_add_line(lnum)
    let lnum = a:lnum =~# '^\d\+$' ? a:lnum : line(a:lnum)
    let qf = {
    \   'bufnr': bufnr('%'),
    \   'lnum': lnum,
    \   'text': getline(lnum),
    \}
    if s:quickfix_supported_quickfix_title()
        " Set 'qf.col' and 'qf.vcol'.
        call s:quickfix_add_line_set_col(lnum, qf)
    endif
    call setqflist([qf], 'a')
endfunction
function! s:quickfix_add_line_set_col(lnum, qf)
    let lnum = a:lnum
    let qf = a:qf

    let search_word = s:quickfix_get_search_word()
    if search_word !=# ''
        let idx = match(getline(lnum), search_word[1:])
        if idx isnot -1
            let qf.col = idx + 1
            let qf.vcol = 0
        endif
    endif
endfunction
" }}}

" }}}
" :QFSearchAgain {{{
command! -bar QFSearchAgain call s:qf_search_again()

" ... {{{
function! s:qf_search_again()
    let qf_winnr = s:quickfix_get_winnr()
    if !qf_winnr
        copen
    endif
    let search_word = s:quickfix_get_search_word()
    if search_word !=# ''
        let @/ = search_word[1:]
        setlocal hlsearch
        try
            execute 'normal!' "/\<CR>"
        catch
            call s:error(v:exception)
        endtry
    endif
endfunction
" }}}

" }}}
" Map CUA-like keybindings to Alt key {{{
Map [x] <M-x> "+d
Map [x] <M-c> "+y
Map [nx] <M-v> "+p
Map [n] <M-a> ggVG
Map [n] <M-t> :<C-u>tabedit<CR>
Map [n] <M-w> :<C-u>tabclose<CR>
" }}}

" Mouse {{{

" TODO: Add frequently-used-commands to the top level of the menu.
" like MS Windows Office 2007 Ribborn interface.
" Back to normal mode if insert mode.

Map -silent [i] <LeftMouse>   <Esc><LeftMouse>
" Double-click for selecting the word under the cursor
" as same as most editors.
set selectmode=mouse
" Single-click for searching the word selected in visual-mode.
Map -remap [x]  <LeftMouse> <Plug>(visualstar-g*)
" Select lines with <S-LeftMouse>
Map [n]         <S-LeftMouse> V

" }}}
" }}}
" Menus {{{

nnoremenu          PopUp.-VimrcSep- :
nmenu     <silent> PopUp.最近開いたファイル sf
nnoremenu <silent> PopUp.すぐやることリスト :tab drop ~/Dropbox/memo/todo/すぐやること.txt<CR>
nnoremenu <silent> PopUp.ファイルパスをコピー :let [@", @+, @*] = repeat([expand('%:p')], 3)<CR>

" }}}
" FileType & Syntax {{{

" Must be after 'runtimepath' setting!
" http://rbtnn.hateblo.jp/entry/2014/11/30/174749
syntax enable

" FileType {{{

function! s:current_filetypes() "{{{
    return split(&l:filetype, '\.')
endfunction "}}}
function! s:set_dict() "{{{
    let filetype_vs_dictionary = {
    \   'c': ['c', 'cpp'],
    \   'cpp': ['c', 'cpp'],
    \   'html': ['html', 'css', 'scss', 'javascript', 'smarty', 'htmldjango'],
    \   'scala': ['scala', 'java'],
    \}

    let dicts = []
    for ft in s:current_filetypes()
        for ft in get(filetype_vs_dictionary, ft, [ft])
            let dict_path = $MYVIMDIR . '/dict/' . ft . '.dict'
            if filereadable(dict_path)
                call add(dicts, dict_path)
            endif
        endfor
    endfor

    let &l:dictionary = join(s:List.uniq(dicts), ',')
endfunction "}}}
function! s:is_current_filetype(filetypes) "{{{
    if type(a:filetypes) isnot type([])
        return s:is_current_filetype([a:filetypes])
    endif
    let filetypes = copy(a:filetypes)
    for ft in s:current_filetypes()
        if !empty(filter(filetypes, 'v:val ==# ft'))
            return 1
        endif
    endfor
    return 0
endfunction "}}}
function! s:set_tab_width() "{{{
    if s:is_current_filetype(
    \   ['css', 'xml', 'html', 'smarty', 'htmldjango',
    \    'lisp', 'scheme', 'yaml', 'python', 'markdown']
    \)
        CodingStyle Short indent
    else
        CodingStyle My style
    endif
endfunction "}}}
function! s:set_compiler() "{{{
    let filetype_vs_compiler = {
    \   'c': 'gcc',
    \   'cpp': 'gcc',
    \   'html': 'tidy',
    \   'java': 'javac',
    \}
    try
        for ft in s:current_filetypes()
            execute 'compiler' get(filetype_vs_compiler, ft, ft)
        endfor
    catch /E666:/    " compiler not supported: ...
    endtry
endfunction "}}}
function! s:load_filetype() "{{{
    if &omnifunc == ""
        setlocal omnifunc=syntaxcomplete#Complete
    endif

    call s:set_dict()
    call s:set_tab_width()
    call s:set_compiler()
endfunction "}}}

VimrcAutocmd FileType * call s:load_filetype()

" }}}

" Syntax {{{
VimrcAutocmd BufNewFile,BufRead *.as setlocal syntax=actionscript
VimrcAutocmd BufNewFile,BufRead _vimperatorrc,.vimperatorrc setlocal syntax=vimperator
VimrcAutocmd BufNewFile,BufRead *.avs setlocal syntax=avs
" }}}

" }}}
" Commands {{{
" :DiffOrig {{{
" from vimrc_example.vim
"
" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
command! -bar DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
\ | wincmd p | diffthis
" }}}
" :MTest {{{
" convert Perl's regex to Vim's regex

" No -bar
command!
\   -nargs=+
\   MTest
\   call s:MTest(<q-args>)

function! s:MTest(args) "{{{
    let org_search = @/
    let org_hlsearch = &hlsearch

    try
        silent execute "M" . a:args
        let @" = @/
    catch
        return
    finally
        let @/ = org_search
        let &hlsearch = org_hlsearch
    endtry

    echo @"
endfunction "}}}
" }}}
" :EchoPath - Show path-like option in a readable way {{{

MapAlterCommand epa EchoPath
MapAlterCommand rtp EchoPath<Space>&rtp


" TODO Add -complete=option
command!
\   -bar -nargs=+ -complete=expression
\   EchoPath
\   call s:cmd_echo_path(<f-args>)

function! s:cmd_echo_path(optname, ...) "{{{
    let delim = a:0 != 0 ? a:1 : ','
    let val = eval(a:optname)
    for i in split(val, delim)
        echo i
    endfor
endfunction "}}}
" }}}
" :Expand {{{
command!
\   -bar -nargs=?
\   Expand
\   call s:cmd_expand(<q-args>)

function! s:cmd_expand(args) "{{{
    if a:args != ''
        let str = expand(a:args)
    else
        if getbufvar('%', '&buftype') == ''
            let str = expand('%:p')
        else
            let str = expand('%')
        endif
    endif
    if s:is_win
        let str = tr(str, '/', '\')
    endif
    echo str
    let [@", @+, @*] = [str, str, str]
endfunction "}}}

MapAlterCommand ep Expand
" }}}
" :Has {{{
MapAlterCommand has Has

command!
\   -bar -nargs=1 -complete=customlist,feature_list_excomplete#complete
\   Has
\   echo has(<q-args>)
" }}}
" :Glob, :GlobPath {{{
command!
\   -bar -nargs=+ -complete=file
\   Glob
\   echo glob(<q-args>, 1)

MapAlterCommand gl[ob] Glob

command!
\   -bar -nargs=+ -complete=file
\   GlobPath
\   echo globpath(&rtp, <q-args>, 1)

MapAlterCommand gp GlobPath
" }}}
" :SynNames {{{
" :help synstack()

command!
\   -bar
\   SynNames
\
\     for s:id in synstack(line("."), col("."))
\   |     echo printf('%s (%s)', synIDattr(s:id, "name"), synIDattr(synIDtrans(s:id), "name"))
\   | endfor
\   | unlet! s:id
" }}}
" :SplitNicely {{{
" originally from kana's .vimrc, but now outragely different one :)
" https://github.com/kana/config

command! -bar -bang -nargs=+ SplitNicely
\   call s:cmd_split_nicely(<q-args>, <bang>0)

function! s:cmd_split_nicely(q_args, bang)
    let vertical = 1
    let winnum = winnr('$')
    let save_winwidth = winwidth(0)
    let save_winheight = winheight(0)
    execute 'belowright' (vertical ? 'vertical' : '') a:q_args
    if winnr('$') is winnum
        " if no new window is opened
        return
    endif
    " Adjust split window.
    if vertical && !&l:winfixwidth
        execute save_winwidth / 3 'wincmd |'
    endif
    if !vertical && !&l:winfixheight
        execute save_winheight / 2 'wincmd _'
    endif
    " Fix width and height.
    if a:bang
        setlocal winfixwidth winfixheight
    endif
endfunction

" }}}
" :Help {{{
MapAlterCommand h[elp]     Help

" No -bar
command!
\   -bang -nargs=* -complete=help
\   Help
\   SplitNicely help<bang> <args>
" }}}
" :NonSortUniq {{{
"
" http://lingr.com/room/vim/archives/2010/11/18#message-1023619
" > :let d={}|g/./let l=getline('.')|if has_key(d,l)|d|else|let d[l]=1

command!
\   -bar
\   NonSortUniq
\   let d={}|g/./let l=getline('.')|if has_key(d,l)|d|el|let d[l]=1

" E147: Cannot do :global recursive
" command!
" \   -bar
" \   NonSortUniq
" \   g/./let l=getline('.')|g/./if l==getline('.')|d

" }}}
" :Ctags {{{
MapAlterCommand ctags Ctags

Map -script [n] <C-]> <SID>(gen-tags-if-not-present)<C-]>
Map [n] <SID>(gen-tags-if-not-present) :<C-u>if empty(tagfiles()) | Ctags | endif<CR>

command!
\   -bar -nargs=*
\   Ctags
\   call s:cmd_ctags(<q-args>)

function! s:cmd_ctags(q_args) "{{{
    if !executable('ctags')
        call s:error("Ctags: No 'ctags' command in PATH")
        return
    endif
    execute '!ctags' (filereadable('.ctags') ? '' : '-R') a:q_args
endfunction "}}}
" }}}
" :WatchAutocmd {{{

" Create watch-autocmd augroup.
augroup watch-autocmd
    autocmd!
augroup END

command! -bar -nargs=1 -complete=event WatchAutocmd
\   call s:cmd_{<bang>0 ? "un" : ""}watch_autocmd(<q-args>)


let s:watching_events = {}

function! s:cmd_unwatch_autocmd(event)
    if !exists('#'.a:event)
        call s:error("Invalid event name: ".a:event)
        return
    endif
    if !has_key(s:watching_events, a:event)
        call s:error("Not watching ".a:event." event yet...")
        return
    endif

    unlet s:watching_events[a:event]
    echomsg 'Removed watch for '.a:event.' event.'
endfunction
function! s:cmd_watch_autocmd(event)
    if !exists('#'.a:event)
        call s:error("Invalid event name: ".a:event)
        return
    endif
    if has_key(s:watching_events, a:event)
        echomsg "Already watching ".a:event." event."
        return
    endif

    execute 'autocmd watch-autocmd' a:event
    \       '* call s:echomsg("Executing '.string(a:event).' event...")'
    let s:watching_events[a:event] = 1
    echomsg 'Added watch for '.a:event.' event.'
endfunction
" }}}
" :Alias {{{

" TODO
" - |:command-bang|
" - |:command-bar|
" - |:command-register|
" - |:command-buffer|
" - |:command-complete|
" - etc.

command!
\   -nargs=+ -bar
\   Alias
\   call s:cmd_alias('<bang>', [<f-args>], <q-args>)

function! s:cmd_alias(bang, args, q_args)
    if len(a:args) is 1 && a:args[0] =~# '^[A-Z][A-Za-z0-9]*$'
        execute 'command '.a:args[0]
    elseif len(a:args) is 2
        execute 'command! -bang -nargs=* '.a:args[0].' '.a:args[1].a:bang.' '.a:q_args
    endif
endfunction
" }}}
" :Kwbd {{{
" http://nanasi.jp/articles/vim/kwbd_vim.html
command! -bar Kwbd execute "enew | bw ".bufnr("%")
MapAlterCommand clo[se] Kwbd
" }}}
" :ScrollbindEnable, :ScrollbindDisable, :ScrollbindToggle {{{

" Enable/Disable 'scrollbind', 'cursorbind' options.
command! -bar ScrollbindEnable  call s:cmd_scrollbind(1)
command! -bar ScrollbindDisable call s:cmd_scrollbind(0)
command! -bar ScrollbindToggle  call s:cmd_scrollbind_toggle()

function! s:cmd_scrollbind_toggle()
    if get(t:, 'vimrc_scrollbind', 0)
        ScrollbindDisable
    else
        ScrollbindEnable
    endif
endfunction

function! s:cmd_scrollbind(enable)
    let winnr = winnr()
    try
        call s:scrollbind_specific_mappings(a:enable)
        windo let &l:scrollbind = a:enable
        if exists('+cursorbind')
            windo let &l:cursorbind = a:enable
        endif
        let t:vimrc_scrollbind = a:enable
    finally
        execute winnr . 'wincmd w'
    endtry
endfunction

function! s:scrollbind_specific_mappings(enable)
    if a:enable
        " Check either buffer-local those mappings are mapped already or not.
        if get(maparg('<C-e>', 'n', 0, 1), 'buffer', 0)
            nnoremap <buffer> <C-e> :<C-u>call <SID>no_scrollbind('<C-e>')<CR>
        endif
        if get(maparg('<C-y>', 'n', 0, 1), 'buffer', 0)
            nnoremap <buffer> <C-y> :<C-u>call <SID>no_scrollbind('<C-y>')<CR>
        endif
    else
        " Check either those mappings are above one or not.
        let map = maparg('<C-e>', 'n', 0, 1)
        if get(map, 'buffer', 0)
        \   || get(map, 'rhs', '') =~# 'no_scrollbind('
            nunmap <buffer> <C-e>
        endif
        let map = maparg('<C-y>', 'n', 0, 1)
        if get(map, 'buffer', 0)
        \   || get(map, 'rhs', '') =~# 'no_scrollbind('
            nunmap <buffer> <C-y>
        endif
    endif
endfunction

function! s:no_scrollbind(key)
    let scrollbind = &l:scrollbind
    try
        execute 'normal!' a:key
    finally
        let &l:scrollbind = scrollbind
    endtry
endfunction

" }}}
" :EditLast (like Firefox's Ctrl-Shift-T) {{{
command! -bar EditLast split #
" }}}
" }}}
" Quickfix {{{
VimrcAutocmd QuickfixCmdPost [l]*  lopen
VimrcAutocmd QuickfixCmdPost [^l]* copen
" }}}
" Plugins Settings {{{
let s:HAS_SKK_VIM  = s:has_plugin('skk')
let s:HAS_ESKK_VIM = s:has_plugin('eskk')
if s:HAS_SKK_VIM || s:HAS_ESKK_VIM " {{{

    " skkdict
    let s:skk_user_dict = '~/.skkdict/user-dict'
    let s:skk_user_dict_encoding = 'utf-8'
    let s:skk_system_dict = '~/.skkdict/system-dict'
    let s:skk_system_dict_encoding = 'euc-jp'

    " Use skk.vim and eskk together.
    if s:HAS_ESKK_VIM
        " Map <C-j> to eskk, Map <C-g><C-j> to skk.vim
        " Map -remap [ic] <C-j> <Plug>(eskk:toggle)    " default
        let skk_control_j_key = '<C-g><C-j>'
    elseif s:HAS_SKK_VIM
        " Map <C-j> to skk.vim, Map <C-g><C-j> to eskk    " default
        " let skk_control_j_key = '<C-j>'
        Map -remap [ic] <C-g><C-j> <Plug>(eskk:toggle)
    endif

endif " }}}
if s:has_plugin('skk') " {{{

    " skkdict
    let skk_jisyo = s:skk_user_dict
    let skk_jisyo_encoding = s:skk_user_dict_encoding
    let skk_large_jisyo = s:skk_system_dict
    let skk_large_jisyo_encoding = s:skk_system_dict_encoding

    " let skk_control_j_key = ''
    " Map -remap [lic] <C-j> <Plug>(skk-enable-im)

    let skk_manual_save_jisyo_keys = ''

    let skk_egg_like_newline = 1
    let skk_auto_save_jisyo = 1
    let skk_imdisable_state = -1
    let skk_keep_state = 0
    let skk_show_candidates_count = 2
    let skk_show_annotation = 0
    let skk_sticky_key = ';'
    let skk_use_color_cursor = 1
    let skk_remap_lang_mode = 0


    if 0
        " g:skk_enable_hook test {{{
        " Do not map `<Plug>(skk-toggle-im)`.
        let skk_control_j_key = ''

        " `<C-j><C-e>` to enable, `<C-j><C-d>` to disable.
        Map -remap [ic] <C-j><C-e> <Plug>(skk-enable-im)
        Map -remap [ic] <C-j><C-d> <Nop>
        function! MySkkMap()
            lunmap <buffer> <C-j>
            lmap <buffer> <C-j><C-d> <Plug>(skk-disable-im)
        endfunction
        function! HelloWorld()
            echomsg 'Hello.'
        endfunction
        function! Hogera()
            echomsg 'hogera'
        endfunction
        let skk_enable_hook = 'MySkkMap,HelloWorld,Hogera'
        " }}}
    endif

endif " }}}
if s:has_plugin('eskk') " {{{

    " skkdict
    if !exists('g:eskk#dictionary')
        let g:eskk#dictionary = {
        \   'path': s:skk_user_dict,
        \   'encoding': s:skk_user_dict_encoding,
        \}
    endif
    if !exists('g:eskk#large_dictionary')
        let g:eskk#large_dictionary = {
        \   'path': s:skk_system_dict,
        \   'encoding': s:skk_system_dict_encoding,
        \}
    endif

    " let g:eskk#server = {
    " \   'host': 'localhost',
    " \   'port': 55100,
    " \}

    let g:eskk#log_cmdline_level = 2
    let g:eskk#log_file_level = 4

    if 1    " for debugging default behavior.
        let g:eskk#egg_like_newline = 1
        let g:eskk#egg_like_newline_completion = 1
        let g:eskk#show_candidates_count = 2
        let g:eskk#show_annotation = 1
        let g:eskk#rom_input_style = 'msime'
        let g:eskk#keep_state = 0
        let g:eskk#keep_state_beyond_buffer = 0
        " let g:eskk#marker_henkan = '$'
        " let g:eskk#marker_okuri = '*'
        " let g:eskk#marker_henkan_select = '@'
        " let g:eskk#marker_jisyo_touroku = '?'
        let g:eskk#dictionary_save_count = 5
        let g:eskk#start_completion_length = 1

        if VimStarting()
            VimrcAutocmd User eskk-initialize-pre call s:eskk_initial_pre()
            function! s:eskk_initial_pre() "{{{
                " User can be allowed to modify
                " eskk global variables (`g:eskk#...`)
                " until `User eskk-initialize-pre` event.
                " So user can do something heavy process here.
                " (I'm a paranoia, eskk#table#new() is not so heavy.
                " But it loads autoload/vice.vim recursively)

                let hira = eskk#table#new('rom_to_hira*', 'rom_to_hira')
                let kata = eskk#table#new('rom_to_kata*', 'rom_to_kata')

                for t in [hira, kata]
                    call t.add_map('~', '～')
                    call t.add_map('vc', '©')
                    call t.add_map('vr', '®')
                    call t.add_map('vh', '☜')
                    call t.add_map('vj', '☟')
                    call t.add_map('vk', '☝')
                    call t.add_map('vl', '☞')
                    call t.add_map('z ', '　')
                    " Input hankaku characters.
                    call t.add_map('(', '(')
                    call t.add_map(')', ')')
                    " It is better to register the word "Exposé" than to register this map :)
                    call t.add_map('qe', 'é')
                    if g:eskk#rom_input_style ==# 'skk'
                        call t.add_map('zw', 'w', 'z')
                    endif
                endfor

                call hira.add_map('jva', 'ゔぁ')
                call hira.add_map('jvi', 'ゔぃ')
                call hira.add_map('jvu', 'ゔ')
                call hira.add_map('jve', 'ゔぇ')
                call hira.add_map('jvo', 'ゔぉ')
                call hira.add_map('wyi', 'ゐ', '')
                call hira.add_map('wye', 'ゑ', '')
                call hira.add_map('&', '＆', '')
                call eskk#register_mode_table('hira', hira)

                " call kata.add_map('jva', 'ヴァ')
                " call kata.add_map('jvi', 'ヴィ')
                " call kata.add_map('jvu', 'ヴ')
                " call kata.add_map('jve', 'ヴェ')
                " call kata.add_map('jvo', 'ヴォ')
                call kata.add_map('wyi', 'ヰ', '')
                call kata.add_map('wye', 'ヱ', '')
                call kata.add_map('&', '＆', '')
                call eskk#register_mode_table('kata', kata)
            endfunction "}}}
        endif

        " Debug
        command! -bar          EskkDumpBuftable PP! eskk#get_buftable().dump()
        command! -bar -nargs=1 EskkDumpTable    PP! eskk#table#<args>#load()
        " EskkMap lhs rhs
        " EskkMap -silent lhs2 rhs
        " EskkMap lhs2 foo
        " EskkMap -expr lhs3 {'foo': 'hoge'}.foo
        " EskkMap -noremap lhs4 rhs

        " by @_atton
        " Map -remap [icl] <C-j> <Plug>(eskk:enable)

        " by @hinagishi
        " VimrcAutocmd User eskk-initialize-pre call s:eskk_initial_pre()
        " function! s:eskk_initial_pre() "{{{
        "     let t = eskk#table#new('rom_to_hira*', 'rom_to_hira')
        "     call t.add_map(',', ', ')
        "     call t.add_map('.', '.')
        "     call eskk#register_mode_table('hira', t)
        "     let t = eskk#table#new('rom_to_kata*', 'rom_to_kata')
        "     call t.add_map(',', ', ')
        "     call t.add_map('.', '.')
        "     call eskk#register_mode_table('kata', t)
        " endfunction "}}}

        " VimrcAutocmd User eskk-initialize-post call s:eskk_initial_post()
        function! s:eskk_initial_post() "{{{
            " Disable "qkatakana", but ";katakanaq" works.
            " NOTE: This makes some eskk tests fail!
            " EskkMap -type=mode:hira:toggle-kata <Nop>

            map! <C-j> <Plug>(eskk:enable)
            EskkMap <C-j> <Nop>

            EskkMap U <Plug>(eskk:undo-kakutei)

            EskkMap jj <Esc>
            EskkMap -force jj hoge
        endfunction "}}}

    endif
endif " }}}
if s:has_plugin('vixim') "{{{
    let g:vixim#debug = 1

    " skkdict
    if !exists('g:vixim#engine#skk#user_dict')
        let g:vixim#engine#skk#user_dict = {
        \   'path': s:skk_user_dict,
        \   'encoding': s:skk_user_dict_encoding,
        \}
    endif
    if !exists('g:vixim#engine#skk#large_dict')
        let g:vixim#engine#skk#large_dict = {
        \   'path': s:skk_system_dict,
        \   'encoding': s:skk_system_dict_encoding,
        \}
    endif

endif "}}}

" runtime
if s:has_plugin('syntax/vim.vim') "{{{
    " augroup: a
    " function: f
    " lua: l
    " perl: p
    " ruby: r
    " python: P
    " tcl: t
    " mzscheme: m
    let g:vimsyn_folding = 'af'
endif "}}}
if s:has_plugin('netrw') " {{{
    function! s:filetype_netrw() "{{{
        Map -remap -buffer [n] h -
        Map -remap -buffer [n] l <CR>
        Map -remap -buffer [n] e <CR>
    endfunction "}}}

    VimrcAutocmd FileType netrw call s:filetype_netrw()
endif " }}}
if s:has_plugin('indent/vim.vim') " {{{
    let g:vim_indent_cont = 0
endif " }}}
if s:has_plugin('changelog') " {{{
    let changelog_username = "tyru"
endif " }}}
if s:has_plugin('syntax/sh.vim') " {{{
    let g:is_bash = 1
endif " }}}
if s:has_plugin('syntax/scheme.vim') " {{{
    let g:is_gauche = 1
endif " }}}
if s:has_plugin('syntax/perl.vim') " {{{

    " POD highlighting
    let g:perl_include_pod = 1
    " Fold only sub, __END__, <<HEREDOC
    let g:perl_fold = 1
    let g:perl_nofold_packages = 1

endif " }}}

" }}}
" Backup {{{
" TODO Rotate backup files like writebackupversioncontrol.vim
" (I didn't use it, though)

" Delete old files in &backupdir {{{
function! s:delete_backup()
    if s:is_win
        if exists('$TMP')
            let stamp_file = $TMP . '/.vimbackup_deleted'
        elseif exists('$TEMP')
            let stamp_file = $TEMP . '/.vimbackup_deleted'
        else
            return
        endif
    else
        let stamp_file = expand('~/.vimbackup_deleted')
    endif

    if !filereadable(stamp_file)
        call writefile([localtime()], stamp_file)
        return
    endif

    let [line] = readfile(stamp_file)
    let one_day_sec = 60 * 60 * 24    " Won't delete old files many times within one day.

    if localtime() - str2nr(line) > one_day_sec
        let backup_files = split(expand(&backupdir . '/*'), "\n")
        let thirty_days_sec = one_day_sec * 30
        call filter(backup_files, 'localtime() - getftime(v:val) > thirty_days_sec')
        for i in backup_files
            if delete(i) != 0
                call s:warn("can't delete " . i)
            endif
        endfor
        call writefile([localtime()], stamp_file)
    endif
endfunction

call s:delete_backup()
" }}}
" }}}
" Misc. (bundled with kaoriya vim's .vimrc & etc.) {{{

" Checking typo. {{{
VimrcAutocmd BufWriteCmd *[,*] call s:write_check_typo(expand('<afile>'))
function! s:write_check_typo(file)
    let writecmd = 'write'.(v:cmdbang ? '!' : '').' '.a:file
    if exists('b:write_check_typo_nocheck')
        execute writecmd
        return
    endif
    let prompt = "possible typo: really want to write to '" . a:file . "'?(y/n):"
    let input = input(prompt)
    if input ==# 'YES'
        execute writecmd
        let b:write_check_typo_nocheck = 1
    elseif input =~? '^y\(es\)\=$'
        execute writecmd
    endif
endfunction
" }}}

" Jump to the last known cursor position {{{
" This setting was from $VIM/vimrc_example.vim

" When editing a file, always jump to the last known cursor position.
" Don't do it when the position is invalid or when inside an event handler
" (happens when dropping a file on gvim).
" Also don't do it when the mark is in the first line, that is the default
" position when opening a file.
VimrcAutocmd BufReadPost *
\ if line("'\"") > 1 && line("'\"") <= line("$") |
\   exe "normal! g`\"" |
\ endif
" }}}

" About japanese input method {{{
if has('multi_byte_ime') || has('xim')
    " Cursor color when IME is on.
    highlight CursorIM guibg=Purple guifg=NONE
    set iminsert=0 imsearch=0
endif
" }}}

" GNU Screen, Tmux {{{
"
" from thinca's .vimrc
" http://soralabo.net/s/vrcb/s/thinca

if $WINDOW != '' || $TMUX != ''
    let s:screen_is_running = 1

    " Use a mouse in screen.
    if has('mouse')
        set ttymouse=xterm2
    endif

    function! s:screen_set_window_name(name)
        let esc = "\<ESC>"
        silent! execute '!echo -n "' . esc . 'k' . escape(a:name, '%#!')
        \ . esc . '\\"'
        redraw!
    endfunction
    command! -bar -nargs=? WindowName call s:screen_set_window_name(<q-args>)

    function! s:screen_auto_window_name()
        let varname = 'window_name'
        for scope in [w:, b:, t:, g:]
            if has_key(scope, varname)
                call s:screen_set_window_name(scope[varname])
                return
            endif
        endfor
        if bufname('%') !~ '^\[A-Za-z0-9\]*:/'
            call s:screen_set_window_name('vim:' . expand('%:t'))
        endif
    endfunction
    if 0
        augroup vimrc-screen
            autocmd!
            autocmd VimEnter * call s:screen_set_window_name(0 < argc() ?
            \ 'vim:' . fnamemodify(argv(0), ':t') : 'vim')
            autocmd BufEnter,BufFilePost * call s:screen_auto_window_name()
            autocmd VimLeave * call s:screen_set_window_name(len($SHELL) ?
            \ fnamemodify($SHELL, ':t') : 'shell')
        augroup END
    endif
endif
" }}}

" own-highlight {{{
" TODO: Plugin-ize

augroup own-highlight
    autocmd!
augroup END

function! s:register_highlight(hi, hiarg, pat)
    execute 'highlight' a:hiarg
    call s:add_pattern(a:hi, a:pat)
endfunction
function! s:add_pattern(hi, pat)
    " matchadd() will throw an error
    " when a:hi is not defined.
    if !hlexists(a:hi)
        return
    endif
    if !exists('w:did_pattern')
        let w:did_pattern = {}
    endif
    if !has_key(w:did_pattern, a:hi)
        call matchadd(a:hi, a:pat)
        let w:did_pattern[a:hi] = 1
    endif
endfunction

function! s:register_own_highlight()
    " I found that I'm very nervous about whitespaces.
    " so I'd better think about this.
    " This settings just notice its presence.
    for [hi, hiarg, pat] in [
    \   ['IdeographicSpace',
    \    'IdeographicSpace term=underline cterm=underline gui=underline ctermfg=4 guifg=Cyan',
    \    '　'],
    \   ['WhitespaceEOL',
    \    'WhitespaceEOL term=underline cterm=underline gui=underline ctermfg=4 guifg=Cyan',
    \    ' \+$'],
    \]
        " TODO: filetype
        execute
        \   'autocmd own-highlight Colorscheme *'
        \   'call s:register_highlight('
        \       string(hi) ',' string(hiarg) ',' string(pat)
        \   ')'
        execute
        \   'autocmd own-highlight VimEnter,WinEnter *'
        \   'call s:add_pattern('
        \       string(hi) ',' string(pat)
        \   ')'
    endfor
endfunction
call s:register_own_highlight()
" }}}

" Make <M-Space> same as ordinal applications on MS Windows {{{
if has('gui_running') && s:is_win
    nnoremap <M-Space> :<C-u>simalt ~<CR>
endif
" }}}

" Use meta keys in console {{{
if has('unix') && !has('gui_running')
  " Use meta keys in console.
  function! s:use_meta_keys()  " {{{
    for i in map(
    \   range(char2nr('a'), char2nr('z'))
    \ + range(char2nr('A'), char2nr('Z'))
    \ + range(char2nr('0'), char2nr('9'))
    \ , 'nr2char(v:val)')
      " <ESC>O do not map because used by arrow keys.
      if i != 'O'
        execute 'nmap <ESC>' . i '<M-' . i . '>'
      endif
    endfor
  endfunction  " }}}

  call s:use_meta_keys()
  map <NUL> <C-Space>
  map! <NUL> <C-Space>
endif
" }}}

" }}}
" End. {{{

let $MYVIMRC = expand('<sfile>')

set secure
" }}}
