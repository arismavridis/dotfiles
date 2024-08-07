" Call plugins
call plug#begin()
Plug 'JuliaEditorSupport/julia-vim'
Plug 'hanschen/vim-ipython-cell', {'for':['python','julia']} 
Plug 'jpalardy/vim-slime', {'for':['python','julia']} 
call plug#end()

" Julia thing
runtime macros/matchit.vim

" Slime configuration
let g:slime_target = "vimterminal"

" Customizations
colorscheme desert
set number 
set relativenumber
set showcmd
highlight VertSplit cterm=NONE
highlight StatusLine cterm=NONE
nnoremap <Space> :noh<cr>
let &t_SI = "\e[6 q"
let &t_EI = "\e[2 q"
