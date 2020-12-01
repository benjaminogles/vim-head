
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

function! s:num_stars(content)
  let cur_length = len(a:content)
  let level = 0
  while level < cur_length && a:content[level] == "*"
    let level += 1
  endwhile
  return level
endfunction

function! HeadFold(lnum)
  let heading = s:num_stars(getline(a:lnum))
  if heading
    return ">" . heading
  endif
  return "="
endfunction

function! HeadIndent(lnum)
  let num_stars = s:num_stars(getline(a:lnum))
  if num_stars
    return 0
  endif
  let prev_star_lnum = search('^\*\+ ', 'Wbn')
  if prev_star_lnum
    return s:num_stars(getline(prev_star_lnum)) + 1
  endif
  return 0
endfunction

function! HeadFormatHeader()
  call head#heading#from_source().store_line(v:false).write()
endfunction

function! HeadFormat(lnum, count)
  normal! zR
  exe a:lnum
  exe "normal! =" . a:count . "j"
  exe a:lnum
  exe ".,.+" . min([a:count, line('$') - a:lnum]) . "g/^\\*/call HeadFormatHeader()"
endfunction

setlocal foldmethod=expr
setlocal foldexpr=HeadFold(v:lnum)
setlocal foldtext=getline(v:foldstart)
setlocal nolisp
setlocal autoindent
setlocal indentexpr=HeadIndent(v:lnum)
setlocal formatexpr=HeadFormat(v:lnum,v:count)

vnoremap <buffer> at :<c-u>call head#heading#from_content().load_bottom().select_all()<cr>
omap <buffer> at :normal Vat<cr>
vnoremap <buffer> it :<c-u>call head#heading#from_content().load_bottom().select_in()<cr>
omap <buffer> it :normal Vit<cr>
nnoremap <buffer> [[ 0?^\*<cr>
nnoremap <buffer> ]] 0/^\*<cr>
nnoremap <buffer> <m-cr> :call head#heading#insert_sibling(head#config#auto_keyword(), ' ')<cr>A
inoremap <buffer> <m-cr> <esc>:call head#heading#insert_sibling(head#config#auto_keyword(), ' ')<cr>A
inoremap <buffer> <c-x> <esc>mq:call head#heading#from_content().load_bottom().load_lines(v:false).promote(1).write()<cr>`qa
inoremap <buffer> <c-a> <esc>mq:call head#heading#from_content().load_bottom().load_lines(v:false).demote(1).write()<cr>`qla
nnoremap <buffer> <c-x> mq:call head#heading#from_content().load_bottom().load_lines(v:false).promote(1).write()<cr>`q
nnoremap <buffer> <c-a> mq:call head#heading#from_content().load_bottom().load_lines(v:false).demote(1).write()<cr>`q
inoremap <buffer> <c-d> <esc>:HeadChangeDate<cr>
nnoremap <buffer> <c-d> :HeadChangeDate<cr>

