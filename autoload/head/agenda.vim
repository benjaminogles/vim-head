
if exists("g:autoloaded_head_agenda")
  finish
endif
let g:autoloaded_head_agenda = 1

let s:fields_pat = '.*' . join(repeat([head#config#field_sep()], 10), '.*') . '.*' 
function! s:format_script_output(idx, content)
  if a:content =~ s:fields_pat
    return head#heading#from_fields(a:content).agenda_text()
  endif
  return a:content
endfunction

function! head#agenda#report(cmd, report)
  let file = head#config#agenda_tmp()
  let lines = map(a:report, {_, val -> '# ' . val})
  for idx in range(len(lines) - 1)
    call insert(lines, '', idx + 1)
  endfor
  if len(head#utils#overwrite_nofile(file, a:cmd, lines))
    return head#agenda#refresh()
  endif
  return v:false
endfunction

function! s:next_config(lines, start, filenames, scripts, filters, contents)
  let done = v:false
  let has_next = v:false
  for idx in range(a:start, len(a:lines) - 1)
    let line = a:lines[idx]
    if line =~ '^#'
      if done
        let has_next = v:true
        break
      else
        call add(a:contents, line)
        if line =~ '.*\.hd'
          call add(a:filenames, trim(line[1:]))
        elseif line =~ '^#\s*!.*'
          call add(a:scripts, trim(line[stridx(line, '!')+1:]))
        elseif line !~ 'vim:' && line =~ '^#\s*\S'
          call add(a:filters, trim(line[1:]))
        endif
      endif
    elseif len(a:contents)
      let done = v:true
    endif
  endfor
  if empty(a:filenames)
    call extend(a:filenames, head#config#agenda_files())
  endif
  if empty(a:scripts)
    call add(a:scripts, head#config#default_list_report())
  endif
  return has_next ? idx : len(a:lines)
endfunction

function! s:do_config(filenames, scripts, filters)
  return map(head#heading#script(a:filenames, a:filters, a:scripts[0]), function('s:format_script_output'))
endfunction

function! head#agenda#refresh()
  if getbufvar('', '&filetype') == 'agenda'
    let lines = getline(1, '$')
    :%delete
    let idx = 0
    while idx < len(lines)
      let filenames = []
      let scripts = []
      let filters = []
      let content = []
      let idx = s:next_config(lines, idx, filenames, scripts, filters, content)
      call extend(content, s:do_config(filenames, scripts, filters))
      call append(line('$'), content + [''])
    endwhile
    silent! write
    return v:true
  endif
  return v:false
endfunction

