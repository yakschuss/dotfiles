"Source Location {{{
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
  nnoremap <leader>clrs :colorscheme github<CR>
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

" " zoom a vim pane, <C-w>= to re-balance
 nnoremap <leader>- :wincmd _<cr>:wincmd \|<cr>
 nnoremap <leader>= :wincmd =<cr>



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

  "" Use The Silver Searcher https://github.com/ggreer/the_silver_searcher
  if executable('ag')
    " Use Ag over Grep
    set grepprg=ag\ --nogroup\ --nocolor

    " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
    let g:ctrlp_user_command = 'ag -Q -l --nocolor --hidden -g "" %s'

    " ag is fast enough that CtrlP doesn't need to cache
    let g:ctrlp_use_caching = 0
  endif
"}}}

"HTML {{{
  let g:jsx_ext_required = 0

  nnoremap ,html :-1read $HOME/.vim/skeleton.html<CR>3jwf>a
  nnoremap ,rcomponent :-1read $HOME/.vim/component.js<CR>e
  nnoremap ,rstateless :-1read $HOME/.vim/stateless.js<CR>e

  " Treat <li> and <p> tags like the block tags they are
  let g:html_indent_tags = 'li\|p'

  " prettier cli integration
  

  " set filetypes for auto html closing (include js for React work?)
  let g:closetag_filenames = "*.html,*.jsx,*.js,*.eex"

  let g:syntastic_javascript_checkers=['standard']
  let g:syntastic_javascript_standard_exec = 'semistandard'

  "prettier-standard
  " autocmd FileType javascript set formatprg=prettier.sh
  " autocmd BufWritePre *.js :normal gggqG

  "automatic semistandard fix on save
  "autocmd bufwritepost *.js silent !semistandard % --fix
  "set autoread
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

  "Quicker window movement Doesn't work with Tmux
  
  nnoremap <C-j> <C-w>j
  nnoremap <C-k> <C-w>k
  nnoremap <C-h> <C-w>h
  nnoremap <C-l> <C-w>l

 set winwidth=84
 set winheight=5
 set winminwidth=5
 set winheight=999

  "Create more word objects
  for char in [ '_', '.', ':', ',', ';', '<bar>', '/', '<bslash>', '*', '+', '%', '-', '#' ]
    execute 'xnoremap i' . char . ' :<C-u>normal! T' . char . 'vt' . char . '<CR>'
    execute 'onoremap i' . char . ' :normal vi' . char . '<CR>'
    execute 'xnoremap a' . char . ' :<C-u>normal! F' . char . 'vf' . char . '<CR>'
    execute 'onoremap a' . char . ' :normal va' . char . '<CR>'
endfor

"turn json into ruby hash in file
nnoremap <leader>h :%s/"\(.*\)"=>/\1\: /g<CR>
nnoremap <leader>j :%s/\(.*\)\:/"\1" => /g<CR>

"}}}

"Plugins {{{
  " Use FZF as a fuzzy finder
  "use ag, which respects .gitignore
  let $FZF_DEFAULT_COMMAND= 'ag -g ""'
  nmap <c-p> :FZF<return>
  nmap <c-a> :FZF<return>

  nnoremap <silent> <Leader>s :call fzf#run({
        \   'down': '40%',
        \   'sink': 'botright split' })<CR>

  " Open files in vertical horizontal split
  nnoremap <silent> <Leader>v :call fzf#run({
        \   'right': winwidth('.') / 2,
        \   'sink':  'vertical botright split' })<CR>

  "Open Dash d for Globally, D for specific docset
  nmap <Leader>d :Dash!<CR>
  nmap <Leader>D :Dash<CR>

  "use fzf for word under cursor
  nmap <Leader>f "zyiw:exe "Ag ".@z.""<CR>

  "show diff in statusline
  set stl+=%{ConflictedVersion()}

  nnoremap <leader>rr :VtrSendLinesToRunner!<CR>

  nnoremap <Leader>g "zyiw:exe "Googlef ".@z.""<CR>
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
  nnoremap <leader>p :set paste<CR>mmo<esc>"*]p:set nopaste<cr>`]=`m

  " Run commands that require an interactive shell
  nnoremap <Leader>r :RunInInteractiveShell<space>

  "Testing {{{
    nnoremap <silent> <Leader>T :TestFile<CR>
    nnoremap <silent> <Leader>t :TestNearest<CR>
    nnoremap <silent> <Leader>l :TestLast<CR>
    nnoremap <silent> <Leader>a :TestSuite<CR>
    nnoremap <silent> <leader>gt :TestVisit<CR>
  "}}}
"}}}

"Random {{{
  "fix pbcopy on MacOS Sierra
  " set clipboard=unnamed

  function! s:tagbar_integration()
    "tells you what function you're in in airline
  endfunction
  "" Set spellfile to location that is guaranteed to exist, can be symlinked to
  "" Dropbox or kept in Git and managed outside of thoughtbot/dotfiles using rcm.
  set spellfile=$HOME/.vim-spell-en.utf-8.add
  "
  "" Autocomplete with dictionary words when spell check is on
  set complete+=kspell
  "
  "" Always use vertical diffs
  set diffopt+=vertical
  
  
  " When the type of shell script is /bin/sh, assume a POSIX-compatible
  " shell for syntax highlighting purposes.
  let g:is_posix = 1
  let g:netrw_dirhistmax = 0
"}}}

"vim: set foldmethod=marker:set foldlevel=0
