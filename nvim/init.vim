filetype plugin on
se nu
" ugly fix. searching python interpreters makes long startup time
let g:loaded_python_provider = 1
if has('macunix')
  let g:python3_host_prog = '/usr/local/bin/python3'
elseif has('unix')
  " source /usr/share/doc/fzf/examples/fzf.vim
endif

let g:plug_window = ''

" Please declare this variable before polyglot is loaded (at the top of .vimrc)
" vim-polyglot via https://github.com/vim-python/python-syntax improves nothing
" not working with vim-markdown
let g:polyglot_disabled = ['python', 'sensible']

call plug#begin(stdpath('data') . '/plugged')
Plug 'glacambre/firenvim', { 'do': { _ -> firenvim#install(0) } }
Plug 'sheerun/vim-polyglot'
Plug 'Yggdroot/indentLine'
Plug 'joshdick/onedark.vim'
Plug 'ryanoasis/vim-devicons'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-commentary'
Plug 'machakann/vim-sandwich'
Plug 'junegunn/vim-easy-align'
Plug 'junegunn/vim-peekaboo'
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}
Plug 'ryvnf/readline.vim'
Plug 'kana/vim-fakeclip'
Plug 'chrisbra/unicode.vim'
Plug 'tpope/vim-liquid'
Plug 'tpope/vim-dadbod'  " for SQL. TODO: help exrc
Plug 'kristijanhusak/vim-dadbod-ui'

Plug 'cohama/agit.vim'
Plug 'rhysd/git-messenger.vim'  ", {'on': ['<Plug>(git-messenger)', 'GitMessenger']}
" https://github.com/rhysd/conflict-marker.vim
" https://github.com/christoomey/vim-conflicted
Plug 'tpope/vim-fugitive'
Plug 'rbong/vim-flog'
Plug 'airblade/vim-gitgutter'
Plug 'mhinz/vim-signify'
Plug 'wellle/tmux-complete.vim'
Plug 'chiedo/vim-case-convert'
Plug 'gyim/vim-boxdraw'
Plug 'monkoose/fzf-hoogle.vim'

Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'fisadev/vim-isort', {'for': 'python'}
Plug 'tell-k/vim-autopep8'
Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'
Plug 'neomake/neomake', {'for': ['python', 'cpp', 'typescript', 'rust']}
Plug 'skywind3000/asyncrun.vim'
Plug 'mattn/emmet-vim', {'for': ['html', 'hbs', 'typescript']}
Plug 'Rykka/colorv.vim', {'for': ['less', 'sass', 'css']}
Plug 'rhysd/vim-grammarous'
Plug 'norcalli/nvim-colorizer.lua', {'for': ['css', 'javascript', 'html', 'less']}
Plug 'liuchengxu/vista.vim'
Plug 'itchyny/lightline.vim'
Plug 'ap/vim-buftabline'
" Plug 'heavenshell/vim-pydocstring', {'for': 'python'}
Plug 'numirias/semshi', {'do': ':UpdateRemotePlugins', 'for': 'python'}
Plug 'jackguo380/vim-lsp-cxx-highlight', {'for': 'cpp'}
Plug 'alfredodeza/pytest.vim', {'for': ['python']}
" Plug 'nvim-treesitter/nvim-treesitter'
call plug#end()

set rtp+=~/.vim

set termguicolors
set background=dark
let g:quantum_black=1
let g:quantum_italics=1
highlight MatchParen cterm=bold ctermbg=none ctermfg=magenta guibg=NONE guifg=Magenta
let g:onedark_terminal_italics = 1
" onedark.vim override: Don't set a background color when running in a terminal;
" just use the terminal's background color
" `gui` is the hex color code used in GUI mode/nvim true-color mode
" `cterm` is the color code used in 256-color mode
" `cterm16` is the color code used in 16-color mode
if (has("autocmd") && !has("gui_running"))
  augroup colorset
    autocmd!
    let s:white = { "gui": "#ABB2BF", "cterm": "145", "cterm16" : "7" }
    " `bg` will not be styled since there is no `bg` setting
    autocmd ColorScheme * call onedark#set_highlight("Normal", { "fg": s:white })
  augroup END
endif
colorscheme onedark

if has("mac")
  lua require'colorizer'.setup()
endif

set mouse=a
set colorcolumn=80
highlight CursorLine guibg=#303030
highlight VertSplit  guibg=#303030
if has("mac") | hi Normal guibg=None | endif
set shiftwidth=4
set softtabstop=4
set expandtab
set display+=lastline
set incsearch
set updatetime=300
let mapleader = ","
cnoreabbrev W w
nnoremap <silent> <C-N> :nohlsearch<cr>
nnoremap Q <Nop>
nnoremap vv $v^
nnoremap / /\v

let g:mkdp_open_ip = 'localhost'
" wsl2
" function! g:OpenBrowser(url)
"   silent exe '!lemonade open ' a:url
" endfunction
" let g:mkdp_browserfunc = 'g:OpenBrowser'

autocmd FileType scheme let b:AutoPairs = {"(": ")"}


xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

vnoremap <silent> <M-/> :Commentary<cr>gv
nnoremap <silent> <M-/> :Commentary<cr>

set pastetoggle=<Leader>p
" Bufferline
nnoremap <silent> <M-n> :bnext<CR>
nnoremap <silent> <M-p> :bprev<CR>

nmap <M-1> <Plug>BufTabLine.Go(1)
nmap <M-2> <Plug>BufTabLine.Go(2)
nmap <M-3> <Plug>BufTabLine.Go(3)
nmap <M-4> <Plug>BufTabLine.Go(4)
nmap <M-5> <Plug>BufTabLine.Go(5)
nmap <M-6> <Plug>BufTabLine.Go(6)
nmap <M-7> <Plug>BufTabLine.Go(7)
nmap <M-8> <Plug>BufTabLine.Go(8)
nmap <M-9> <Plug>BufTabLine.Go(9)
nmap <M-0> <Plug>BufTabLine.Go(10)

let g:buftabline_show = 1
let g:buftabline_numbers = 2

function! Bufferline()
  call bufferline#refresh_status()
  return [
        \ g:bufferline_status_info.before,
        \ g:bufferline_status_info.current,
        \ g:bufferline_status_info.after
        \]
endfunction

function! NearestMethodOrFunction() abort
  return get(b:, 'vista_nearest_method_or_function', '')
endfunction

let g:autopep8_disable_show_diff=1
let g:ale_linters = {
      \ 'python': ['flake8'],
      \ }
let g:ale_python_flake8_options = '--extended-ignore=F841'  " unused local variables

let g:node_client_debug = 0

let CocCurrentFunction = {-> get(b:, 'coc_current_function', '')}
let CocGitStatus = {-> get(g:, 'coc_git_status', '')}
let LightlineReadony = {-> &readonly ? '' : ''}

let g:lightline = {
      \ 'colorscheme': 'onedark',
      \ 'tabline': {'left': [['bufferline']], 'right': [['close']]},
      \ 'component_expand': {'buffers': 'Bufferline'},
      \ 'component_type': {'buffers': 'tabsel'},
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'cocstatus', 'readonly', 'filename', 'currentfunction', 'modified', 'gitbranch' ] ]
      \ },
      \ 'component_function': {
      \   'readonly': 'LightlineReadony',
      \   'cocstatus': 'coc#status',
      \   'currentfunction': 'CocCurrentFunction',
      \   'gitbranch': 'CocGitStatus',
      \ },
      \ }
let g:lightline.separator = {'left': '', 'right': ''}
let g:lightline.subseparator = {'left': '', 'right': ''}

" separator.left  ''    '' (\ue0b0)    '⮀' (\u2b80)
" separator.right ''    '' (\ue0b2)    '⮂' (\u2b82)
" subseparator.left '|'   '' (\ue0b1)    '⮁' (\u2b81)
" subseparator.right  '|'   '' (\ue0b3)    '⮃' (\u2b83)
" branch symbol   --    '' (\ue0a0)    '⭠' (\u2b60)
" readonly symbol --    '' (\ue0a2)    '⭤' (\u2b64)
" linecolumn symbol --    '' (\ue0a1)    '⭡' (\u2b61)

" nnoremap <leader>m :CocList<cr>
nmap <leader>ac <Plug>(coc-codeaction)
nmap <leader>dg <Plug>(coc-diagnostic-info)
" nmap <leader>gt <Plug>(coc-action-doHover)
nmap <leader>sn <Plug>(coc-action-showSignatureHelp)
nmap <leader>cl <Plug>(coc-codelens-action)
nmap <leader>ji <Plug>(coc-implementation)
nmap <leader>jd <Plug>(coc-definition)
nmap <leader>jr <Plug>(coc-references)
nmap <leader>fx <Plug>(coc-fix-current)
nmap <leader>ft <Plug>(coc-format-selected)
vmap <leader>ft <Plug>(coc-format-selected)
nmap <silent>[w <Plug>(coc-diagnostic-prev)
nmap <silent>]w <Plug>(coc-diagnostic-next)
nmap <silent>[e <Plug>(coc-diagnostic-prev-error)
nmap <silent>]e <Plug>(coc-diagnostic-next-error)
nmap <leader>rn <Plug>(coc-rename)
inoremap <silent><expr> <C-X><C-O> coc#refresh()
nnoremap <silent><space> :call CocActionAsync('doHover')<cr>
command! -nargs=0 Format :call CocAction('format')  " format the whole buffer

nnoremap <unique> <silent> <LocalLeader>l :<C-u>CocFzfList<CR>
nnoremap <unique> <silent> <LocalLeader>c :<C-u>CocFzfList commands<CR>
nnoremap <unique> <silent> <LocalLeader>d :<C-u>CocFzfList diagnostics --current-buf<CR>
nnoremap <unique> <silent> <LocalLeader>o :<C-u>CocFzfList outline<CR>
nnoremap <unique> <silent> <LocalLeader>s :<C-u>CocFzfList symbols<CR>

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')

  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction


syntax keyword pythonTodo contained NOTE NOTES
syntax keyword schemeSyntax λ

cnoreabbrev Fix ALEFix

augroup file_type
  au!
  " Alternative: au FileType python AutoFormatBuffer autopep8
  " au FileType c,cpp,proto AutoFormatBuffer clang-format

  " au Filetype python nmap <LocalLeader>rn :Semshi rename
  au BufRead *.rkt se ft=racket
  " au FileType python set equalprg=autopep8\ -
  au Filetype python set keywordprg=pydoc3
  au FileType python hi semshiImported ctermfg=214 guifg=#aaaaaa cterm=bold gui=bold
  au FileType python setlocal foldmethod=marker
  au FileType python,java setlocal shiftwidth=4 tabstop=4
  au FileType haskell hi Structure guifg=#00ffaf
  au FileType haskell hi Type      guifg=#61afef
  au FileType rust hi CocHintSign      guifg=Gray
  au FileType nasm,applescript,cmake,make set omnifunc=syntaxcomplete#Complete
  au FileType cpp set makeprg="cmake --build build"
  au FileType markdown set textwidth=80
  au FileType scheme inoreabbrev lambda λ

  au FileType typescript,typescript.jsx,javascript,cpp,haskell,go,cabal setlocal shiftwidth=2 tabstop=2
  "au FileType typescript :syn clear jsxAttrib
augroup END

let g:firenvim_config = {
  \ 'localSettings': {
    \ '.*': {
      \ 'selector': 'textarea'
    \ }
  \ }
\ }


" lua <<EOF
" require'nvim-treesitter.configs'.setup {
"   highlight = {
"     enable = true,
"     disable = {"cpp", "bash", "python", "typescript", "go"}
"   },
"   indent = {
"     enable = true
"   },
"   incremental_selection = { enable = true },
"   refactor = {
"     highlight_current_scope = { enable = false },
"     highlight_definitions = { enable = true },
"     smart_rename = {
"       enable = true,
"       keymaps = {
"         smart_rename = "<LocalLeader>rn",
"       },
"     },
"   },
"   textobjects = {
"     select = {
"       enable = true,
"       keymaps = {
"         ["af"] = "@function.outer",
"         ["if"] = "@function.inner",
"         ["ac"] = "@class.outer",
"         ["ic"] = "@class.inner",
"       },
"     },
"   },
" }
" EOF
"
" very slow
" au FileType python se foldmethod=expr | se foldexpr=nvim_treesitter#foldexpr()

let g:neomake_cmake_maker = {
      \ 'name': 'cmake',
      \ 'exe': 'cmake',
      \ 'args': ['--build'],
      \ 'append_file': 0,
      \}
" let g:neomake_cpp_enabled_makers = ['cmake', 'makeprg']
let g:neomake_typescript_tsc_args = [
      \ '--watch',
      \ 'true',
      \ '--pretty',
      \ 'false',
      \ '--project',
      \ '/Users/CC/src/magic/lighthouse/tsconfig.json'
      \]

nnoremap <Leader>e :CocCommand explorer <CR>

let g:indentLine_fileTypeExclude = ['coc-explorer']
" clear italic
hi CocExplorerIndentLine cterm=NONE guifg=#303030

""" Tags
let g:vista_default_executive = 'coc'
let g:vista#renderer#enable_icon = 1
nnoremap <silent> <leader>vt :Vista!!<CR>
nnoremap <silent> <leader>q  :bp\|bd #<CR>
" 'haskell': 'fast-tags -R -o - .',
let g:vista_ctags_cmd = { 'haskell': 'hasktags -x -o - -c' }

nnoremap <C-P> :FZF<CR>


" Required for operations modifying multiple buffers like rename.
set hidden
set noshowmode  " Don't show INSERT/NORMAL... mode in cmdline
set completeopt-=preview


let g:qs_lazy_highlight = 1  " QuickScope
" let g:signify_vcs_list = ['git']  " spped up; prevent checking other vcs
" let g:signify_realtime = 1
let g:git_messenger_include_diff = "current"
let g:gitgutter_signs = 0
autocmd CursorHold * CocCommand git.refresh  " in case gutters may not update

" navigate chunks of current buffer
" don't lie vim-fugitive
nmap [c <Plug>(coc-git-prevchunk)
nmap ]c <Plug>(coc-git-nextchunk)
" show chunk diff at current position
nmap <Leader>d <Plug>(coc-git-chunkinfo)
nnoremap <Leader>a :CocCommand git.chunkStage<CR>
nnoremap <Leader>u :CocCommand git.chunkUndo<CR>

omap ig <Plug>(coc-git-chunk-inner)
xmap ig <Plug>(coc-git-chunk-inner)
omap ag <Plug>(coc-git-chunk-outer)
xmap ag <Plug>(coc-git-chunk-outer)

" highlighting
" let g:haskell_enable_quantification   = 1  " `forall`
" let g:haskell_enable_recursivedo      = 1  " `mdo` and `rec`
" let g:haskell_enable_arrowsyntax      = 1  " `proc`
" let g:haskell_enable_pattern_synonyms = 1  " `pattern`
" let g:haskell_enable_typeroles        = 1  " type roles
" let g:haskell_enable_static_pointers  = 1  " `static`
" let g:haskell_backpack                = 1  " backpack keywords


""" UltiSnips
let g:UltiSnipsListSnippets        = "<c-tab>"
let g:UltiSnipsJumpForwardTrigger  = "<tab>"
let g:UltiSnipsJumpBackwardTrigger = "<s-tab>"
let g:snips_author                 = "Congee"


function! s:delete_trailing_white_spaces()
  %s/\s\+$//ge
endfunction
command! DeleteTrailingWhiteSpaces call s:delete_trailing_white_spaces()

function! s:syntax_query() abort
  for id in synstack(line("."), col("."))
    echo synIDattr(id, "name")
  endfor
endfunction
command! SyntaxQuery call s:syntax_query()


" bracketed paste
if &term =~ '\(alacritty\|xterm.*\)'
    let &t_ti = &t_ti . "\e[?2004h"
    let &t_te = "\e[?2004l" . &t_te
    function! XTermPasteBegin(ret)
        set pastetoggle=<Esc>[201~
        set paste
        return a:ret
    endfunction
    map <expr> <Esc>[200~ XTermPasteBegin("i")
    imap <expr> <Esc>[200~ XTermPasteBegin("")
    vmap <expr> <Esc>[200~ XTermPasteBegin("c")
    cmap <Esc>[200~ <nop>
    cmap <Esc>[201~ <nop>
endif

function! s:convert__snake_case__to_camelCase()
  s#_\(\l\)#\u\1#g
endfunction
command! SnakecamelCase call s:convert__snake_case__to_camelCase()

function! s:convert__snake_case__to_CamelCase()
  s#_\(\l\)#\u\1#g
endfunction
command! SnakeCamelCase call s:convert__snake_case__to_camelCase()

" vim: ts=2 sw=2
