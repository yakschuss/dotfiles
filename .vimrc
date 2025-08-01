"Source Location {{{
packadd minpac
call minpac#init()

if filereadable(expand("~/.vimrc.bundles"))
  source ~/.vimrc.bundles
endif

" Local config
if filereadable($HOME . "/.vimrc.local")
  source ~/.vimrc.local
endif
"}}}

" Initial Settings {{{

let mapleader = " "

nnoremap <leader>RL :source ~/.vimrc<CR>
set backspace=2   " Backspace deletes like most programs in insert mode
set nobackup
set nowritebackup
set noswapfile    " http://robots.thoughtbot.com/post/18739402579/global-gitignore#comment-458413287
set history=50
set ruler         " show the cursor position all the time
set showcmd       " display incomplete commands
set incsearch     " do incremental searching
set nohlsearch
" set hlsearch     " do incremental searching
set ignorecase
set smartcase
set laststatus=2  " Always display the status line
set autowrite     " Automatically :write before running commands

" Open new split panes to right and bottom, which feels more natural
set splitbelow
set splitright

"code folding
set modelines=1
set foldenable
set foldmethod=indent
set foldnestmax=10
set foldlevelstart=20
nnoremap <leader><tab> za

" Softtabs, 2 spaces
set tabstop=2
set shiftwidth=2
set shiftround
set expandtab

"persistent undo
set undodir=~/.vim/undodir

" display extra whitespace
set list listchars=tab:»·,trail:·,nbsp:·

" Use one space, not two, after punctuation.
set nojoinspaces

"colorscheme
colorscheme dracula
" set background=dark
syntax on

filetype plugin indent on

" Make it obvious where 80 characters is

set textwidth=80
set colorcolumn=+1

"line numbers
set number
set numberwidth=5
"}}}

"AutoCmd {{{
" automatically rebalance windows on vim resize
autocmd VimResized * :wincmd =

"" zoom a vim pane, <C-w>= to re-balance
nnoremap <leader>- :wincmd _<cr>:wincmd \|<cr>
nnoremap <leader>= :wincmd =<cr>

" disable automatic comment extension after newline
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

autocmd VimLeave * :exec "mksession!" "~/.vim/sessions/".fnamemodify("getcwd()", ":p:h:t").".vim"

" Load matchit.vim, but only if the user hasn't installed a newer version.
if !exists('g:loaded_matchit') && findfile('plugin/matchit.vim', &rtp) ==# ''
  runtime! macros/matchit.vim
endif

augroup vimrcEx
  autocmd!

  " When editing a file, always jump to the last known cursor position.
  " Don't do it for commit messages, when the position is invalid, or when
  " inside an event handler (happens when dropping a file on gvim).
  autocmd BufReadPost *
        \ if &ft != 'gitcommit' && line("'\"") > 0 && line("'\"") <= line("$") |
        \   exe "normal g`\"" |
        \ endif

  " Set syntax highlighting for specific file types
  autocmd BufRead,BufNewFile Appraisals set filetype=ruby
  autocmd BufRead,BufNewFile *.md set filetype=markdown
  autocmd BufRead,BufNewFile .{jscs,jshint,eslint}rc set filetype=json
augroup END

"Open images inside vim buffer in iterm (tmux?)
autocmd BufEnter *.png,*.jpg,*gif exec "!imgcat ".expand("%") | :bw

let g:syntastic_html_tidy_ignore_errors=[" proprietary attribute \"ng-"]
let g:syntastic_eruby_ruby_quiet_messages =
      \ {"regex": "possibly useless use of a variable in void context"}

"

" --column: Show column number
" --line-number: Show line number
" --no-heading: Do not show file headings in results
" --fixed-strings: Search term as a literal string
" --ignore-case: Case insensitive search
" --no-ignore: Do not respect .gitignore, etc...
" --hidden: Search hidden files and folders
" --follow: Follow symlinks
" --glob: Additional conditions for search (in this case ignore everything in the .git/ folder)
" --color: Search color options

if executable('rg')
  command! -bang -nargs=* Find call fzf#vim#grep('rg --column --line-number --no-heading --fixed-strings --ignore-case --no-ignore --hidden --follow --glob "!.git/*" --color "always" '.shellescape(<q-args>).'| tr -d "\017"', 1, <bang>0)

  set grepprg=rg\ --vimgrep
endif
"}}}

"HTML {{{
let g:jsx_ext_required = 0
" Treat <li> and <p> tags like the block tags they are
let g:html_indent_tags = 'li\|p'
"}}}

" Tab completion {{{
" will insert tab at beginning of line,
" will use completion if not at beginning
set wildmode=list:longest,list:full
function! InsertTabWrapper()
  let col = col('.') - 1
  if !col || getline('.')[col - 1] !~ '\k'
    return "\<tab>"
  else
    return "\<c-p>"
  endif
endfunction

inoremap <Tab> <c-r>=InsertTabWrapper()<cr>
inoremap <S-Tab> <c-n>
"}}}

"Movement {{{
imap jk <esc>
imap kj <esc>
"
nnoremap k gk
nnoremap j gj

nnoremap J mzJ'z

" move to beginning/end of line
nnoremap B ^
nnoremap E $

"highlight last inserted text
nnoremap gV `[v`]

" $/^ doesn't do anything
nnoremap $ <nop>
nnoremap ^ <nop>

"new line without insert
nmap <CR><CR> o<ESC>

"Move lines in mac (instead of Alt+k/j)

nnoremap ∆ :m .+1<CR>==
nnoremap ˚ :m .-2<CR>==

inoremap ∆ <Esc>:m .+1<CR>==gi
inoremap ˚ <Esc>:m .-2<CR>==gi

vnoremap ∆ :m '>+1<CR>gv=gv
vnoremap ˚ :m '<-2<CR>gv=gv

"Quicker window movement vim-tmux disallows vim -> tmux

nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l

command! Q q " Bind :Q to :q
command! Qall qall
command! QA qall
command! E e
command! W w
command! Wq wq
command! WQ wq
command! Wqall wqall
command! Vsplit vsplit

set winwidth=84
set winheight=5
set winminwidth=5
set winheight=999

" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

"Create more word objects
for char in [ '_', '.', ':', ',', ';', '<bar>', '/', '<bslash>', '*', '+', '%', '-', '#' ]
  execute 'xnoremap i' . char . ' :<C-u>normal! T' . char . 'vt' . char . '<CR>'
  execute 'onoremap i' . char . ' :normal vi' . char . '<CR>'
  execute 'xnoremap a' . char . ' :<C-u>normal! F' . char . 'vf' . char . '<CR>'
  execute 'onoremap a' . char . ' :normal va' . char . '<CR>'
endfor
"}}}

"Plugins {{{
" Use FZF as a fuzzy finder
"use ag, which respects .gitignore
let g:airline#extensions#tabline#enabled = 0
" let $FZF_DEFAULT_COMMAND= 'ag -g ""'
nmap <c-p> :FZF<return>
nmap <c-a> :FZF<return>

nnoremap <silent> <Leader>s :call fzf#run(fzf#vim#with_preview({
      \   'down': '40%',
      \   'sink': 'botright split' }))<CR>

" Open files in vertical horizontal split
nnoremap <silent> <Leader>v :call fzf#run(fzf#vim#with_preview({
      \   'right': winwidth('.') / 2,
      \   'sink':  'vertical botright split' }))<CR>

"Open Dash d for Globally, D for specific docset
nmap <Leader>d :Dash!<CR>
nmap <Leader>D :Dash<CR>

"use fzf for word under cursor
nmap <Leader>f "zyiw:exe "Ag ".@z.""<CR>
" nmap <Leader>f "zyiw:exe "Find ".@z.""<CR>

nnoremap <leader>rr :VtrSendLinesToRunner!<CR>

nnoremap <Leader>g "zyiw:exe "Googlef ".@z.""<CR>

let g:EditorConfig_exclude_patterns = ['fugitive://.*', 'scp://.*']

" minpac commands:
command! PackUpdate call minpac#update()
command! PackClean call minpac#clean()
"}}}
"

"Leader Remap {{{
"explore mode
nnoremap <leader>e :Explore <CR>
let g:netrw_banner=0        " disable annoying banner
let g:netrw_liststyle=3     " tree view

" Switch between the last two files
nnoremap <leader> <c-^>

" highlight whole file
nnoremap <leader>1 ggvG$
nnoremap <leader>2 :set paste!<CR>i
nnoremap <leader>3 :set paste!<CR>
" paste and indent the pasted system clipboard stuff
nnoremap <leader>p :set paste<CR>mmo<esc>"*]p:set nopaste<cr>`]=`m

" copy current file relative path to clipboard
nnoremap <leader>cf :let @*=expand("%")<CR>

" Run commands that require an interactive shell
nnoremap <Leader>r :RunInInteractiveShell<space>

"Testing {{{
nnoremap <silent> <Leader>T :TestFile<CR>
nnoremap <silent> <Leader>t :TestNearest<CR>
nnoremap <silent> <Leader>l :TestLast<CR>
nnoremap <silent> <Leader>a :TestSuite<CR>
nnoremap <silent> <leader>gt :TestVisit<CR>

let test#neovim#term_position = "vertical"

"}}}
"}}}

"Copilot {{{
imap <leader><Right> <Plug>(copilot-next)
"}}}

"Random {{{
autocmd FileType text,markdown let b:vcm_tab_complete = 'dict'
"" Set spellfile to location that is guaranteed to exist, can be symlinked to
"" Dropbox or kept in Git and managed outside of thoughtbot/dotfiles using rcm.
set spellfile=$HOME/.vim-spell-en.utf-8.add
" Autocomplete with dictionary words when spell check is on
set complete+=kspell
" Always use vertical diffs
set diffopt+=vertical


" When the type of shell script is /bin/sh, assume a POSIX-compatible
" shell for syntax highlighting purposes.
let g:is_posix = 1
let g:netrw_dirhistmax = 0
"}}}

"vim: set foldmethod=marker:set foldlevel=0

"
" function! MarkDuplicates()
"   :syn clear Repeat | g/^\(.*\)\n\ze\%(.*\n\)*\1$/exe 'syn match Repeat "^' . escape(getline('.'), '".\^$*[]') . '$"' | nohlsearch
" endfunction

nnoremap <leader> md :call MarkDuplicates()<CR>


function! GoToLocaleFile(locale)
  let current_file = expand('%:p')
  let locale_file = ""

  if current_file =~ '/app/components/.*\.rb'
    let locale_file = substitute(current_file, '/app/components/\(.*\)\.rb', '/config/locales/components/\1/' . a:locale . '.yml', '')
  elseif current_file =~ '/app/views/.*\.html.erb'
    let locale_file = substitute(current_file, '/app/views/\(.*\)\.html.erb', '/config/locales/views/\1/' . a:locale . '.yml', '')
  elseif current_file =~ '/app/components/.*\.html.erb'
    let locale_file = substitute(current_file, '/app/components/\(.*\)\.html.erb', '/config/locales/components/\1/' . a:locale . '.yml', '')
  elseif current_file =~ '/spec/components/.*_spec\.rb'
    let locale_file = substitute(current_file, '/spec/components/\(.*\)_spec\.rb', '/config/locales/components/\1/' . a:locale . '.yml', '')
  endif

  if filereadable(locale_file)
    execute "edit " . fnameescape(locale_file)
  else
    echom "No corresponding locale file exists for " . a:locale
  endif
endfunction

function! GoToCorrespondingFile(locale)
  let current_file = expand('%:p')
  let file = ""

  if current_file =~ '/config/locales/components/.*' . a:locale . '.yml'
    " account for possible nested directories under components"
    let file = substitute(current_file, '/config/locales/components/\(.*\)/'. a:locale . '\.yml', '/app/components/\1.rb', '')
  elseif current_file =~ '/config/locales/views/.*' . a:locale . '.yml'
    " account for possible nested directories under views"
    let file = substitute(current_file, '/config/locales/views/\(.*\)/'. a:locale . '\.yml', '/app/views/\1.html.erb', '')  
  endif

  if filereadable(file)
    execute "edit " . fnameescape(file)
  else
    echom "No corresponding component/view file exists"
  endif
endfunction

command! -nargs=0 Component call GoToCorrespondingFile('en')
command! -nargs=0 View call GoToCorrespondingFile('en')

nnoremap <leader>lo :call GoToLocaleFile('en')<CR>
command! -nargs=0 Locale call GoToLocaleFile('en')
