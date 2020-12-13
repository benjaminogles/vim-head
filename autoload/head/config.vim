
if exists("g:autoloaded_head_config")
  finish
endif
let g:autoloaded_head_config = 1

let s:project_root = expand('<sfile>:p:h:h:h')

function! head#config#keywords()
  if !exists('g:head_keywords')
    let g:head_keywords = ['TODO', 'NEXT', 'STARTED', 'WAITING', '|', 'DONE', 'MISSED', 'CANCELLED', 'MEETING']
  endif
  return g:head_keywords
endfunction

function! head#config#keywords_nosep()
  return filter(copy(head#config#keywords()), 'v:val != "|"')
endfunction

function! head#config#capture_tmp()
  return '*Capture*'
endfunction

function! head#config#capture_templates()
  if !exists('g:head_capture_templates')
    let g:head_capture_templates = {
          \'Task': ['* TODO '],
          \'Linked Task': ['* TODO ', '  :file: %f'],
          \'Journal': ['* %d '],
          \'Meeting': ['* %t MEETING ']
          \}
  endif
  return g:head_capture_templates
endfunction

function! head#config#capture_file()
  if !exists('g:head_capture_file')
    let g:head_capture_file = expand('~/Documents/notes/refile.hd')
  endif
  return g:head_capture_file
endfunction

function! head#config#capture_subs()
  if !exists('g:head_capture_subs')
    let g:head_capture_subs = {
          \'%f': {-> expand('%:p')},
          \'%d': {-> '<' . strftime('%Y-%m-%d') . '>'},
          \'%t': {-> '<' . strftime('%Y-%m-%d %H:%M') . '>'}
          \}
  endif
  return g:head_capture_subs
endfunction

function! head#config#agenda_files()
  if !exists('g:head_agenda_files')
    let g:head_agenda_files = [expand('~/Documents/notes/tasks.hd'), head#config#capture_file()]
  endif
  return g:head_agenda_files
endfunction

function! head#config#script_dir()
  return s:project_root . '/scripts'
endfunction

function! head#config#default_agenda_report()
  if !exists('g:head_default_agenda_report')
    let g:head_default_agenda_report = s:project_root . '/scripts/agenda'
  endif
  return g:head_default_agenda_report
endfunction

function! head#config#default_list_report()
  if !exists('g:head_default_list_report')
    let g:head_default_list_report = s:project_root . '/scripts/priority'
  endif
  return g:head_default_list_report
endfunction

function! head#config#agenda_reports()
  if !exists('g:head_agenda_reports')
    let agenda = '!'.head#config#default_agenda_report()
    let refile = head#config#capture_file()
    let g:head_agenda_reports = {'Agenda': [agenda], 'Refile': [refile]}
  endif
  return g:head_agenda_reports
endfunction

function! head#config#agenda_tmp()
  return '*Agenda*'
endfunction

function! head#config#refile_files()
  if !exists('g:head_refile_files')
    let g:head_refile_files = copy(head#config#agenda_files())
  endif
  return g:head_refile_files
endfunction

function! head#config#prev_target()
  if !exists('g:head_prev_target')
    let g:head_prev_target = ''
  endif
  return g:head_prev_target
endfunction

function! head#config#archive_file()
  if !exists('g:head_archive_file')
    let g:head_archive_file = expand('~/Documents/notes/archive.hd')
  endif
  return g:head_archive_file
endfunction

function! head#config#auto_keyword()
  if !exists('g:head_auto_keyword')
    let g:head_auto_keyword = 'TODO'
  endif
  return g:head_auto_keyword
endfunction

function! head#config#clock_in()
  if !exists('g:HeadClockIn')
    let g:HeadClockIn = function('head#clock#in')
  endif
  return g:HeadClockIn
endfunction

function! head#config#clock_out()
  if !exists('g:HeadClockOut')
    let g:HeadClockOut = function('head#clock#out')
  endif
  return g:HeadClockOut
endfunction

function! head#config#clock_file()
  if !exists('g:head_clock_file')
    let g:head_clock_file = expand('~/Documents/notes/time.log')
  endif
  return g:head_clock_file
endfunction

function! head#config#use_fzf()
  return exists('g:head_use_fzf')
endfunction

function! head#config#field_sep()
  return '|'
endfunction

function! head#config#title_sep()
  return '/'
endfunction

function! head#config#tag_sep()
  return ':'
endfunction

