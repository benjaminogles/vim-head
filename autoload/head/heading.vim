
if exists("g:autoloaded_head_heading")
  finish
endif
let g:autoloaded_head_heading = 1

" helpers

let s:script_name = head#config#script_dir() . '/headings'

function! s:heading(parts)
  let heading = {}
  let heading.filename = len(a:parts) >= 1 ? trim(a:parts[0]) : ''
  let heading.lnum = len(a:parts) >= 2 ? str2nr(trim(a:parts[1])) : 0
  let heading.level = len(a:parts) == 9 ? str2nr(trim(a:parts[2])) : 0
  let heading.keyword = len(a:parts) == 9 ? trim(a:parts[3]) : ''
  let heading.date = len(a:parts) == 9 ? trim(a:parts[4]) : ''
  let heading.warning = len(a:parts) == 9 ? trim(a:parts[5]) : ''
  let heading.repeat = len(a:parts) == 9 ? trim(a:parts[6]) : ''
  let heading.title = len(a:parts) == 9 ? trim(a:parts[7]) : ''
  let heading.tags = len(a:parts) == 9 ? split(trim(a:parts[8]), head#config#tag_sep()) : []
  return extend(heading, s:heading_methods)
endfunction

function! s:parse(filename, lnum, content)
  let parts = [a:filename, a:lnum]
  let star_pat = '^\(\*\+\)\s\+'
  let keyword_pat = '\(' . join(head#config#keywords_nosep(), '\s\+\|') . '\s\+\)\?'
  let date_pat = '\(<\(\d\d\d\d-\d\d-\d\d\)\( \d\d:\d\d\)\?\( -\d\+[mdyhM]\)\?\( +\d\+[mdyhM]\)\?>\)\?\s*'
  let title_pat = '\([^:]*\)\?\s*'
  let tags_pat = '\(:.*:\)\?\s*$'
  let matches = matchlist(a:content, star_pat . keyword_pat . date_pat . title_pat . tags_pat)
  if !len(matches)
    return s:heading(parts)
  endif
  call extend(parts, [len(matches[1]), matches[2], matches[4] . matches[5]] + matches[6:8])
  call add(parts, trim(matches[9], head#config#tag_sep()))
  return s:heading(parts)
endfunction

function! s:stack_path(stack)
  return join(map(copy(a:stack), 'v:val.title'), head#config#title_sep())
endfunction

function! s:stack_tags(stack)
  let all_tags = []
  for heading in a:stack
    call extend(all_tags, heading.tags)
  endfor
  return uniq(sort(all_tags))
endfunction

function! s:update_stack(stack, heading)
  while len(a:stack) && a:stack[-1].level >= a:heading.level
    let parent = remove(a:stack, -1)
    let parent.bottom = a:heading.lnum - 1
  endwhile
  return a:stack
endfunction

" heading methods

let s:heading_methods = {}

" load file and check state

function! s:heading_methods.bufload() dict
  return head#utils#bufload(self.filename)
endfunction

function! s:heading_methods.same(other) dict
  return self.filename == a:other.filename && self.lnum == a:other.lnum && self.title == a:other.title
endfunction

function! s:heading_methods.valid() dict
  if empty(self.filename)
    return v:false
  endif
  if self.level <= 0
    return v:false
  endif
  if self.lnum <= 0
    return v:false
  endif
  if has_key(self, 'bottom') && self.bottom != '$' && (self.bottom <= 0 || self.bottom < self.lnum)
    return v:false
  endif
  let content = getbufline(self.bufload(), self.lnum)[0]
  let heading = s:parse(self.filename, self.lnum, content)
  return self.same(heading)
endfunction

function! s:heading_methods.focused() dict
  return expand('%:p') == self.filename
endfunction

" load state from file

function! s:heading_methods.load_lines(with_path) dict
  let self.lines = getbufline(self.bufload(), self.lnum, self.bottom)
  let self.lines[0] = self.source_text({'path': a:with_path})
  return self
endfunction

function! s:heading_methods.load_line(with_path) dict
  let self.lines = getbufline(self.bufload(), self.lnum)
  let self.lines[0] = self.source_text({'path': a:with_path})
  return self
endfunction

function! s:heading_methods.load_path() dict
  let self.path = ''
  if self.level > 1
    let ancestors = []
    let lines = reverse(getbufline(self.bufload(), 1, self.lnum - 1))
    let level = self.level - 1
    while level
      let i = match(lines, '^' . repeat('\*', level) . ' ')
      let level -= 1
      if i < 0
        continue
      endif
      call add(ancestors, s:parse(self.filename, self.lnum - (i + 1), lines[i]))
    endwhile
    let self.path = s:stack_path(reverse(ancestors))
  endif
  return self
endfunction

function! s:heading_methods.load_bottom(...)
  if !has_key(self, 'bottom') || a:0
    let bot_pat = '^\*' . repeat('\*\?', self.level - 1) . ' '
    let pat_lnum = search(bot_pat, 'Wn')
    let self.bottom = pat_lnum ? pat_lnum - 1 : line('$')
  endif
  return self
endfunction

function! s:heading_methods.load_meta()
  let self.meta = {}
  let lines = getbufline(self.bufload(), self.lnum + 1, self.bottom)
  for line in lines
    let matches = matchlist(line, '^\s*:\(\S\+\):\s*\(.*\)$')
    if len(matches)
      let [key, val] = matches[1:2]
      if !has_key(self.meta, key)
        let self.meta[key] = []
      endif
      call add(self.meta[key], val)
    endif
  endfor
  return self
endfunction

function! s:heading_methods.get_children() dict
  return head#heading#from_range(self.filename, self.lnum + 1, self.bottom)
endfunction

" in memory actions

function! s:heading_methods.demote(amt) dict
  let self.level += a:amt
  call map(self.lines, {idx, val -> val =~ '^\*' ? (repeat('*', a:amt) . val) : (repeat(' ', a:amt) . val)})
  return self
endfunction

function! s:heading_methods.promote(amt) dict
  if self.level > 1
    let adjust = min([self.level - 1, a:amt])
    let self.level -= adjust
    call map(self.lines, {idx, val -> val =~ '^\(' . repeat('\s', adjust) . '\|' . repeat('\*', adjust) . '\)' ? val[adjust:] : val})
  endif
  return self
endfunction

function! s:heading_methods.adjust(level)
  if self.level < a:level
    call self.demote(a:level - self.level)
  elseif self.level > a:level
    call self.promote(self.level - a:level)
  endif
  let self.level = a:level
  return self
endfunction

function! s:heading_methods.store_line(with_path)
  if !has_key(self, 'lines') || !len(self.lines)
    let self.lines = ['']
  endif
  let self.lines[0] = self.source_text(a:with_path ? {'path': 1} : {})
  return self
endfunction

function! s:heading_methods.setloc(filename, lnum)
  let self.filename = a:filename
  let self.lnum = a:lnum
  return self
endfunction

function! s:heading_methods.add_tag(tagname)
  if index(self.tags, a:tagname) < 0
    call add(self.tags, a:tagname)
  endif
  return self
endfunction

function! s:heading_methods.remove_tag(tagname)
  let idx = index(self.tags, a:tagname)
  if idx >= 0
    call remove(self.tags, idx)
  endif
  return self
endfunction

" external actions

function! s:heading_methods.goto(cmd, ...) dict
  let restore = head#utils#focus_file(self.filename, a:cmd, self.lnum)
  if len(restore)
    silent! normal! zv
    if a:0
      call function(a:1)(self)
    endif
  endif
  return restore
endfunction

function! s:heading_methods.write(...) dict
  if has_key(self, 'lines') && len(self.lines)
    let doappend = a:0 ? a:1 : v:false
    if doappend
      call appendbufline(self.bufload(), self.lnum == '$' ? self.lnum : self.lnum - 1, self.lines)
    else
      call setbufline(self.bufload(), self.lnum, self.lines)
    endif
    return v:true
  endif
  return v:false
endfunction

function! s:heading_methods.delete() dict
  if self.valid()
    call deletebufline(self.bufload(), self.lnum, self.bottom)
    return v:true
  endif
  return v:false
endfunction

function! s:heading_methods.archive() dict
  if self.load_path().load_lines(v:true).delete()
    return self.adjust(1).setloc(head#config#archive_file(), '$').write(v:true)
  endif
  return v:false
endfunction

function! s:heading_methods.refile(other) dict
  if self.load_lines(v:false).delete()
    return self.adjust(a:other.level + 1).setloc(a:other.filename, a:other.bottom == '$' ? '$' : a:other.bottom + 1).write(v:true)
  endif
  return v:false
endfunction

function! s:heading_methods.with(opts) dict
  let c = copy(self)
  for k in keys(a:opts)
    let c[k] = a:opts[k]
  endfor
  return c
endfunction

function! s:heading_methods.change_keyword(val) dict
  let keywords = head#config#keywords()
  let done = index(keywords, a:val) > index(keywords, '|')
  if done && len(self.date) && len(self.repeat)
    let lnum = self.bottom == '$' ? self.bottom : self.bottom + 1
    let child = self.with({'keyword': a:val, 'lnum': lnum, 'tags': []})
    if self.change_prop('date', head#datetime#next(self.date, self.repeat))
      return child.store_line(v:false).adjust(self.level + 1).write(v:true)
    endif
    return v:false
  else
    return self.change_prop('keyword', a:val)
  endif
endfunction

function! s:heading_methods.change_prop(prop, val) dict
  if self.valid() && has_key(self, a:prop)
    let self[a:prop] = a:val
    return self.store_line(v:false).write()
  endif
  return v:false
endfunction

function! s:heading_methods.select_all() dict
  if self.level > 0 && self.focused()
    exe "normal!" self.lnum . "GV" . self.bottom . "G"
  endif
endfunction

function! s:heading_methods.select_in() dict
  if self.level > 0 && self.focused() && self.lnum < self.bottom
    exe "normal!" (self.lnum + 1) . "GV" . self.bottom . "G"
  endif
endfunction

" printing

function! s:heading_methods.source_text(...) dict
  let opts = a:0 ? a:1 : {}
  let str = repeat('*', self.level)
  let str .= len(self.keyword) ? ' ' . self.keyword : ''
  let str .= len(self.date) ? ' <' . self.date : ''
  let str .= len(self.date) && len(self.warning) ? ' ' . self.warning : ''
  let str .= len(self.date) && len(self.repeat) ? ' ' . self.repeat : ''
  let str .= len(self.date) ? '>' : ''
  let str .= ' ' . (has_key(opts, 'path') && opts.path && len(self.path) ? self.path . head#config#title_sep() : '') . self.title
  let tagstr = join(self.tags, head#config#tag_sep())
  let str .= len(tagstr) && len(str) < 79 ? repeat(' ', 79 - len(str)) : len(tagstr) ? ' ' : ''
  let str .= len(tagstr) ? head#config#tag_sep() . tagstr . head#config#tag_sep() : ''
  return str
endfunction

function! s:heading_methods.agenda_text() dict
  return join([self.filename, self.lnum, self.bottom, self.source_text()], head#config#field_sep())
endfunction

function! s:heading_methods.field_text() dict
  return join([self.filename, self.lnum, self.bottom, self.level, self.keyword, self.date, self.warning, self.repeat, self.title, join(self.tags, head#config#tag_sep())], head#config#field_sep())
endfunction

" public

function! head#heading#from_range(filename, startline, endline)
  let headings = []
  let lines = getbufline(head#utils#bufload(a:filename), a:startline, a:endline)
  let stack = []
  for idx in range(len(lines))
    if lines[idx] !~ '^\*\+ '
      continue
    endif
    let heading = s:parse(a:filename, a:startline + idx, lines[idx])
    call s:update_stack(stack, heading)
    let heading.path = s:stack_path(stack)
    call extend(heading.tags, s:stack_tags(stack))
    call add(stack, heading)
    call add(headings, heading)
  endfor
  for heading in stack
    let heading.bottom = a:startline + (len(lines) - 1)
  endfor
  return headings
endfunction

function! head#heading#script(files, filters, pipe)
  let cmd = join([s:script_name] + a:files + a:filters)
  if len(a:pipe)
    let cmd .= join(['|', a:pipe])
  endif
  return systemlist(cmd)
endfunction

function! head#heading#from_source()
  return s:parse(expand('%:p'), line('.'), getline(line('.')))
endfunction

function! head#heading#from_content()
  call search('^\*', 'Wbc')
  return head#heading#from_source()
endfunction

function! head#heading#from_agenda()
  let parts = split(getline(line('.')), head#config#field_sep())
  if len(parts) == 4
    let heading = s:parse(parts[0], parts[1], parts[3])
    let heading.bottom = parts[2] == '$' ? '$' : str2nr(parts[2])
    return heading
  endif
  return s:heading([])
endfunction

function! head#heading#from_fields(content)
  let parts = split(a:content, head#config#field_sep(), 1)
  let heading = s:heading(parts[0:1] + parts[3:7] + parts[9:])
  let heading.bottom = parts[2] == '$' ? '$' : str2nr(parts[2])
  let heading.path = parts[8]
  return heading
endfunction

function! head#heading#insert_sibling(keyword, title)
  let heading = head#heading#from_content().load_bottom()
  let level = heading.level > 0 ? heading.level : 1
  let lnum = heading.bottom == '$' ? heading.bottom : heading.bottom + 1
  let sibling = s:heading([heading.filename, lnum, level, a:keyword, '', '', '', a:title, ''])
  if sibling.store_line(v:false).write(v:true)
    let lnum = sibling.lnum
    exe lnum
  endif
endfunction

function! head#heading#goto_first_link(heading)
  call a:heading.load_meta()
  if has_key(a:heading.meta, 'file')
    exe 'vs' a:heading.meta['file'][0]
  endif
endfunction

