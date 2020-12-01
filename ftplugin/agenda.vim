
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

nnoremap <buffer> <tab> :call head#heading#from_agenda().goto('vsplit')<cr>
nnoremap <buffer> <cr> :call head#heading#from_agenda().goto('edit', 'head#heading#goto_first_link')<cr>
nnoremap <buffer> <c-d> :HeadChangeDate<cr>
vnoremap <buffer> <c-d> :HeadChangeDate<cr>
nnoremap <buffer> q :q<cr>
nnoremap <buffer> r :call head#agenda#refresh()<cr>
nnoremap <buffer> s :wall<cr>

