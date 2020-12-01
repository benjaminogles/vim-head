
if exists("b:current_syntax")
  finish
endif

let s:keyword_group = "HeadTodoKeywords"
for word in head#config#keywords()
  if word == '|'
    let s:keyword_group = "HeadDoneKeywords"
    continue
  endif
  exe "syn keyword" s:keyword_group word "contained"
endfor

syn match HeadTitles "^\*\+ .*$" contains=HeadTodoKeywords,HeadDoneKeywords,HeadTags,HeadTimestamps
syn match HeadTags ":\S\+:" contained

"<2003-09-16 14:00 -3d +7d>
syn match HeadTimestamps /\(<\d\d\d\d-\d\d-\d\d\( \d\d:\d\d\)\?\( -\d\+[mdyhM]\)\?\( +\d\+[mdyhM]\)\?>\)/ contained

let b:current_syntax = "head"

hi def link HeadTodoKeywords Constant
hi def link HeadDoneKeywords Type
hi def link HeadTitles Identifier
hi def link HeadTags Special
hi def link HeadTimestamps PreProc

