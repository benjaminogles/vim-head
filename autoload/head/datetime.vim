
if exists("g:autoloaded_head_datetime")
  finish
endif
let g:autoloaded_head_datetime = 1

function! s:includes_time(datestr)
  return a:datestr =~  'am\|pm\|\d\d\?:\d\d'
endfunction

function! s:head_format(datestr)
  return s:includes_time(a:datestr) ? '+%Y-%m-%d %H:%M' : '+%Y-%m-%d'
endfunction

function! head#datetime#from_str(str, ...)
  if len(a:str)
    let format = a:0 ? a:1 : s:head_format(a:str)
    let result = substitute(system('date -d "' . a:str . '" "' . format .'"'), "\n", "", "")
    if len(trim(result)) && !v:shell_error
      return trim(result)
    else
      echomsg "Shell error:" v:shell_error "Result:" result
      return ''
    endif
  else
    return ''
  endif
endfunction

function! head#datetime#next(date, repeat)
  " it seems that the date command only adjusts time correctly if AM and PM are included
  let format = s:includes_time(a:date) ? '+%Y-%m-%d %l:%M %p' : '+%Y-%m-%d'
  let date = head#datetime#from_str(a:date, format)
  let adjust = ''
  let matches = matchlist(a:repeat, '\s*\(+\d\+\)\([dmyhM]\)')
  if len(matches)
    let expand_prefix = {'y': 'years', 'm': 'months', 'd': 'days', 'h': 'hours', 'M': 'minutes'}
    let adjust .= ' ' . matches[1] . ' ' . expand_prefix[matches[2]]
  endif
  return head#datetime#from_str(date . adjust)
endfunction

