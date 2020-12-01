
if exists("g:autoloaded_head_capture")
  finish
endif
let g:autoloaded_head_capture = 1

function! head#capture#edit(cmd, content)
  if len(a:content)
    let capture_subs = copy(head#config#capture_subs())
    for sub_key in keys(capture_subs)
      let capture_subs[sub_key] = capture_subs[sub_key]()
    endfor
    let content = []
    for line in a:content
      for sub_key in keys(capture_subs)
        let line = substitute(line, sub_key, capture_subs[sub_key], 'g')
      endfor
      call add(content, line)
    endfor
    if len(head#utils#overwrite_nofile(head#config#capture_tmp(), a:cmd, content))
      setf head
      startinsert!
    endif
  endif
endfunction

function! head#capture#close()
  let lines = getline(1, '$')
  let restore = head#utils#focus_file(head#config#capture_file(), 'split', 1)
  if len(restore)
    call append('$', lines)
    write
  endif
  exe restore
endfunction

