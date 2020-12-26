
if exists("g:autoloaded_head")
  finish
endif
let g:autoloaded_head = 1

function! s:in_agenda()
  return getbufvar('', '&filetype') == 'agenda'
endfunction

function! s:in_head()
  return getbufvar('', '&filetype') == 'head'
endfunction

function! s:refresh(lnum)
  wall " TODO find better way to save all head buffers
  if s:in_agenda() && head#agenda#refresh()
    exe a:lnum
  endif
endfunction

function! s:sort_lnum_desc(a, b)
  if a:a.filename != a:b.filename
    return a:a.filename < a:b.filename ? -1 : 1
  elseif a:a.lnum < a:b.lnum
    return 1
  elseif a:a.lnum > a:b.lnum
    return -1
  else
    return 0
  endif
endfunction

function! head#valid_headings(startline, endline)
  let headings = []
  if s:in_agenda()
    exe a:startline.','.a:endline.'call add(headings, head#heading#from_agenda().check())'
  elseif s:in_head() && a:startline == a:endline
    call add(headings, head#heading#from_content())
  elseif s:in_head()
    call extend(headings, head#heading#from_range(expand('%:p'), a:startline, a:endline, v:false))
  endif
  return sort(filter(headings, {_, val -> val.valid()}), function('s:sort_lnum_desc'))
endfunction

function! head#valid_unnested_headings(startline, endline)
  let headings = reverse(head#valid_headings(a:startline, a:endline))
  let unnested = []
  let stack = []
  for heading in headings
    while len(stack) && (stack[-1].filename != heading.filename || stack[-1].level >= heading.level)
      call remove(stack, -1)
    endwhile
    call add(stack, heading)
    if len(stack) == 1
      call add(unnested, heading)
    endif
  endfor
  return reverse(unnested)
endfunction

function! head#promote() range
  let lnum = line('.')
  for heading in head#valid_unnested_headings(a:firstline, a:lastline)
    call heading.load_bottom().load_lines(v:false).promote(1).write()
  endfor
  call s:refresh(lnum)
endfunction

function! head#demote() range
  let lnum = line('.')
  for heading in head#valid_unnested_headings(a:firstline, a:lastline)
    call heading.load_bottom().load_lines(v:false).demote(1).write()
  endfor
  call s:refresh(lnum)
endfunction

function! head#change_keyword(word) range
  let lnum = line('.')
  for heading in head#valid_headings(a:firstline, a:lastline)
    call heading.load_bottom().change_keyword(a:word)
  endfor
  call s:refresh(lnum)
endfunction

function! head#change_prop(prop, val) range
  let lnum = line('.')
  for heading in head#valid_headings(a:firstline, a:lastline)
    call heading.change_prop(a:prop, a:val)
  endfor
  call s:refresh(lnum)
endfunction

function! head#refile() range
  let lnum = line('.')
  let headings = head#valid_unnested_headings(a:firstline, a:lastline)
  function! s:refile_and_refresh_clo(target) closure
    for heading in headings
      if heading.filename != a:target.filename
        call heading.load_bottom().refile(a:target)
      endif
    endfor
    call s:refresh(lnum)
  endfunction
  call head#menu#target(head#config#refile_files(), function('s:refile_and_refresh_clo'))
endfunction

function! head#archive() range
  let lnum = line('.')
  for heading in head#valid_unnested_headings(a:firstline, a:lastline)
    call heading.load_bottom().archive()
  endfor
  call s:refresh(lnum)
endfunction

function! head#clock_in()
  for heading in head#valid_headings(line('.'), line('.'))
    return head#config#clock_in()(heading.load_path())
  endfor
endfunction

function! head#clock_out()
  for heading in head#valid_headings(line('.'), line('.'))
    return head#config#clock_out()(heading.load_path())
  endfor
endfunction

