
if exists("g:autoloaded_head_clock")
  finish
endif
let g:autoloaded_head_clock = 1

let s:default_account = 'Unassigned'
function! s:account(heading)
  if has_key(a:heading, 'path') && len('path')
    return substitute(a:heading.path, head#config#title_sep(), ':', 'g')
  endif
  return s:default_account
endfunction

function! s:timelog_entry(action, account)
  let current_time = head#datetime#from_str('now', '+%Y/%m/%d %H:%M:%S')
  if len(current_time)
    return a:action . ' ' . current_time . ' ' . a:account
  endif
  return ''
endfunction

function! head#clock#in(heading)
  if !a:heading.valid()
    return v:false
  endif
  return head#clock#record(s:timelog_entry('i', s:account(a:heading)))
endfunction

function! head#clock#out(heading)
  if !a:heading.valid()
    return v:false
  endif
  return head#clock#record(s:timelog_entry('o', s:account(a:heading)))
endfunction

function! head#clock#record(entry)
  if a:entry =~ '[io] \d\d\d\d/\d\d/\d\d \d\d:\d\d:\d\d \(\S:\?\)\+'
    call appendbufline(head#utils#bufload(head#config#clock_file()), '$', a:entry)
    return v:true
  endif
  return v:false
endfunction

