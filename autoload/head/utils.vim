
if exists("g:autoloaded_head_utils")
  finish
endif
let g:autoloaded_head_utils = 1

function! head#utils#bufload(filename)
  if !bufexists(a:filename)
    call bufload(bufadd(a:filename))
  endif
  return bufnr(a:filename)
endfunction

function! head#utils#focus_file(filename, cmd, lnum)
  let nr = bufwinnr(a:filename)
  if nr >= 0
    let restore = winnr() . 'wincmd w'
    exe nr . 'wincmd w'
    exe a:lnum
  else
    let restore = a:cmd == 'edit' ? 'buf ' . bufnr() : 'close'
    exe 'keepalt' a:cmd '+' . a:lnum a:filename 
    if a:cmd =~ 'pedit'
      wincmd P
    endif
  endif
  return restore
endfunction

function! head#utils#focus_nofile(filename, cmd, lnum)
  let restore = head#utils#focus_file(a:filename, a:cmd, a:lnum)
  if len(restore)
    setl buftype=nofile nobuflisted
  endif
  return restore
endfunction

function! head#utils#overwrite_file(filename, cmd, content)
  let restore = head#utils#focus_file(a:filename, a:cmd, 1)
  if len(restore)
    :%delete
    call setline(1, a:content)
  endif
  return restore
endfunction

function! head#utils#overwrite_nofile(filename, cmd, content)
  let restore = head#utils#focus_nofile(a:filename, a:cmd, 1)
  if len(restore)
    :%delete
    call setline(1, a:content)
  endif
  return restore
endfunction

