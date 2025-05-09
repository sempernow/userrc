" $VIMRUNTIME/defaults.vim
" /etc/vim/vimrc
" /etc/vim/vimrc.local
" ~/.vimrc
"
" $HOME/.vimrc    @ Cygwin.
" /etc/vimrc      @ Git for Windows.
" :set OPTION     @ Set any option while in the vim editor.
" :help OPTION    @ Get option info while in the vim editor.
"
" set nocompatible  " Disable vi compatibility mode. SET FIRST
"
" :set ts=6 sw=2 sts=0 et ai smarttab

function! Tabs()    " 4 whitespaces equivalent
  set tabstop=4     " Size of a hard tabstop (ts).
  set shiftwidth=4  " Size of an indentation (sw).
  set noexpandtab   " Always uses tabs instead of space characters (noet).
  set autoindent    " Copy indent from current line when starting a new line (ai).
endfunction

function! Spaces(n = 4)           " N whitespaces (default: 4)
  set expandtab                   " Always insert spaces on TAB keypress
  " Insert N spaces per TAB keypress if at start of line
  execute 'set shiftwidth=' . a:n . ' smarttab'
  set tabstop=6 softtabstop=0     " TAB width differs to distinguish from whitespace indent
  set autoindent                  " indent line per preceeding line
endfunction

function! Yaml()                  " 2 whitespaces
  set expandtab                   " Always insert spaces on TAB keypress
  set shiftwidth=2 smarttab       " Insert N spaces per TAB keypress if at start of line
  set tabstop=6 softtabstop=0     " TAB width differs to distinguish from whitespace indent
  set autoindent                  " indent line per preceeding line
endfunction

function! List()
  set list                               " List (show) control chars TAB and SPACE
  set listchars=tab:▸\ ,space:·,trail:•,eol:¶  " TAB as '▸    ' (U+25b8), SPACE as '·' (U+00b7), traling SPACE as '•' (U+2022)
endfunction

function! Nolist()
  set nolist
endfunction

call Yaml()
"call List()

set smartindent
set clipboard=unnamed           " Set clipboard to unnamed to access system clipboard @ Windows
set noswapfile                  " Prevent vim's zombie swap-file clusterfuck
set ignorecase                  " Case insensitive search
set smartcase                   " Case insensitive search if capital letters
set nowrap                      " Don't wrap text
set number                      " Display line numbers
"set nonumber                    " Do not display line numbers
set wildmenu                    " Better command-line completion
set nocompatible                " Required for vim (iMprovements), else is just vi
set showmatch                   " Automatically show matching brackets, like bbedit.
set vb                          " Turn on the 'visual bell'; much quieter than 'audio blink'
set ruler                       " Show the cursor position all the time
set laststatus=2                " Make last line (status) two lines deep, so always visible
set backspace=indent,eol,start  " Make the backspace key work the way it should
"set background=dark            " Default to colours that work well on dark background
colo darkblue                   " Color scheme
set showmode                    " Show the current mode
syntax on                       " Turn syntax highlighting on by default
xnoremap p pgvy                 " Paste repeatedly

" Show EOL type and last modified timestamp, right after the filename
set statusline=%<%F%h%m%r\ [%{&ff}]\ (%{strftime(\"%H:%M\ %d/%m/%Y\",getftime(expand(\"%:p\")))})%=%l,%c%V\ %P

"@ fatah/vim-go
filetype plugin indent on

" YAML untested:
" autocmd FileType yaml setlocal ai ts=2 sw=2 et

" Reveal Windows line endings 
set fileformat=unix
set fileformats=unix
