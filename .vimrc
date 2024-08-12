call plug#begin()
Plug 'JuliaEditorSupport/julia-vim'
Plug 'jpalardy/vim-slime', {'for':['python','julia']} 
call plug#end()

runtime macros/matchit.vim
let g:slime_target = "vimterminal"

set clipboard=unnamedplus
set clipboard=unnamed

set tabstop=4
nnoremap <Space> :noh<cr>

colorscheme desert
set number 
set relativenumber
set showcmd
highlight VertSplit cterm=NONE
highlight VertSplit ctermbg=NONE

let &t_SI = "\e[6 q"
let &t_EI = "\e[2 q"
