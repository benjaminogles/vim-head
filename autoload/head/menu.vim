
if exists("g:autoloaded_head_menu")
  finish
endif
let g:autoloaded_head_menu = 1

function! head#menu#getchar(prompt, accept)
  let old_cmdheight = &cmdheight
  let &cmdheight = len(split(a:prompt, "\n"))
  echon a:prompt
  let char = nr2char(getchar())
  let &cmdheight = old_cmdheight
  redraw!
  if char =~? a:accept | return char | endif
  return ''
endfunction

function! head#menu#menu(menu_prompt, menu_items, ...)
  let idx = a:0 ? a:1 : 0
  let acceptable_input = '[' . join(map(copy(a:menu_items), {_, val -> tolower(val[idx])}), '') . ']'
  let options = map(copy(a:menu_items), {_, val -> '(' . tolower(val[idx]) . ') ' . val})
  call add(options, a:menu_prompt)
  let selection = head#menu#getchar(join(options, "\n"), acceptable_input)
  if len(selection)
    let selections = filter(copy(a:menu_items), {_, val -> tolower(val[idx]) == selection})
    if len(selections) == 1
      return selections[0]
    elseif len(selections) > 1
      let remaining = filter(copy(selections), {_, val -> len(val) > idx + 1})
      if len(remaining) == 1
        return remaining[0]
      elseif len(remaining) > 1
        return head#menu#menu(a:menu_prompt, remaining, idx + 1)
      else
        return selections[0]
      endif
    endif
  else
    return ''
  endif
endfunction

function! head#menu#dict_menu(menu_prompt, menu_dict, default)
  let selection = head#menu#menu(a:menu_prompt, keys(a:menu_dict))
  if len(selection)
    return a:menu_dict[selection]
  endif
  return a:default
endfunction

function! head#menu#keyword(...)
  return a:0 ? a:1 : head#menu#menu('Select todo state: ', head#config#keywords_nosep())
endfunction

function! head#menu#template()
  return head#menu#dict_menu('Select template: ', head#config#capture_templates(), [])
endfunction

function! head#menu#agenda()
  return head#menu#dict_menu('Agenda command: ', head#config#agenda_reports(), '')
endfunction

function! head#menu#date(...)
  let date_prompt = a:0 ? a:1 : input({'prompt': 'Date prompt: '})
  return head#datetime#from_str(date_prompt)
endfunction

function! head#menu#headings(files)
  let headings = map(head#heading#script(a:files, [], ''), {_, val -> head#heading#from_fields(val)})
  let title_to_heading = {}
  for heading in headings
    let title_to_heading[(len(heading.path) ? heading.path . head#config#title_sep() : '') . heading.title] = heading
  endfor
  return title_to_heading
endfunction

if head#config#use_fzf()
  function! head#menu#target(files, CB)
    let title_to_heading = head#menu#headings(a:files)
    function! s:refile_save_selection(selection) closure
      if has_key(title_to_heading, a:selection)
        let selection = trim(a:selection, head#config#title_sep())
        let g:head_prev_target = selection
        call a:CB(title_to_heading[selection])
      endif
    endfunction
    call fzf#run({'source': keys(title_to_heading), 'sink': function('s:refile_save_selection'), 'options': ['-q', head#config#prev_target()]})
  endfunction
else
  function! head#menu#target(files, CB)
    let title_to_heading = head#menu#headings(a:files)
    let titles = keys(title_to_heading)
    let title_comp = join(titles, "\n")
    function! RefileMenuComp(A, C, P) closure
      return title_comp
    endfunction
    let selection = trim(input('Target: ', head#config#prev_target(), 'custom,RefileMenuComp'), head#config#title_sep())
    if len(selection) && has_key(title_to_heading, selection)
      let g:head_prev_target = selection
      call a:CB(title_to_heading[selection])
    endif
  endfunction
endif

