syntax on          
filetype plugin indent on

set hidden             " Allow switching buffers without saving
set mouse=a            " Enable mouse support (useful for resizing splits)
set splitbelow         " Horizontal splits open below
set splitright         " Vertical splits open to the right
set confirm            " Ask to save instead of failing a :q command

" Search only starting from the directory of the current file and downward
set path=.,**

" Display all matching files when we tab complete
set wildmenu

" Ignore certain folders
set wildignore+=**/.git/**,**/build/**

" --- colour ---
set termguicolors
set background=dark
colorscheme gruvbox

" --- Line numbers ---
set relativenumber
set number
augroup NetrwSettings
    autocmd!
    autocmd FileType netrw setlocal number relativenumber
augroup END

" Change cursor shape for different modes
let &t_SI = "\e[6 q" " SI = Start Insert (Vertical bar)
let &t_SR = "\e[4 q" " SR = Start Replace (Underline)
let &t_EI = "\e[2 q" " EI = End Insert/Replace (Block)
set timeoutlen=500    " Timeout for mapping sequences
set ttimeoutlen=10    " Timeout for terminal key codes (this fixes the Esc delay)

" --- Remove border and end-of-file tildes ---
set fillchars+=vert:\ 
set fillchars+=eob:\ 

" --- Tab settings ---
set tabstop=4
set expandtab
set softtabstop=4
set shiftwidth=4

" Case-specific tab settings
augroup TabSettings
    autocmd!
    autocmd FileType csv,tsv,txt setlocal noexpandtab tabstop=4
augroup END

" --- Dynamic colorcolumn ---
augroup ColumnLine
    autocmd!
    autocmd FileType,VimResized,WinEnter,BufWinEnter * call s:UpdateColorColumn()
augroup END

function! s:UpdateColorColumn()
    " Local variables for the logic
    let l:is_modifiable = &modifiable
    let l:is_readonly   = &readonly
    let l:buftype       = &buftype
    let l:columns       = winwidth(0)
    let l:ftype         = &filetype

    let l:code_width = 80
    let l:md_width   = 50

    " Check if the file is editable and is a normal file
    if !l:is_modifiable || l:is_readonly || l:buftype != ""
        setlocal colorcolumn=
        return
    endif

    " Logic for Markdown
    if l:ftype ==# "markdown" && l:columns > l:md_width
        let &l:colorcolumn = string(l:md_width + 1)

        " Logic for Code
    elseif l:columns > l:code_width && index(['csv', 'tsv'], l:ftype) == -1
        let &l:colorcolumn = string(l:code_width + 1)

        " Clear if no conditions met
    else
        setlocal colorcolumn=
    endif
endfunction

" --- Language / Keymap ---
set keymap=greek
set iminsert=0

" --- Grep with Ripgrep ---
if executable('rg')
    set grepprg=rg\ -S\ --vimgrep
    set grepformat=%f:%l:%c:%m
else
    set grepprg=grep\ -nH\ $*
    set grepformat=%f:%l:%m
endif

" Abbreviations for command line
cnoreabbrev <expr> g (getcmdtype() == ':' && getcmdline() == 'g') ? 'silent grep' : 'g'

" --- Search and UI ---
set nohlsearch
set incsearch
set scrolloff=1
set sidescrolloff=2
let g:netrw_banner = 0
" set clipboard=unnamedplus

" --- Writing / Spellcheck ---
augroup SpellCheckForSpecificFiletypes
    autocmd!
    autocmd FileType markdown,tex,txt,typst 
        \ setlocal spelllang=en_gb,el |
        \ setlocal spell |
        \ setlocal textwidth=50
augroup END

" --- General behavior ---
set nowrap
set undofile
set ignorecase
set smartcase

" --- Terminal settings (Vim-specific) ---
augroup custom-term-open
    autocmd!
    autocmd TerminalOpen * setlocal signcolumn=no nonumber norelativenumber
augroup END
