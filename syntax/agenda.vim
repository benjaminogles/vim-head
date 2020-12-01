
runtime! syntax/head.vim
unlet b:current_syntax

syn match HeadAgendaHeading /^.*|.*|.*|.*$/ contains=HeadTodoKeywords,HeadDoneKeywords,HeadTimestamps,HeadTags,HeadAgendaFilename,HeadAgendaLineNumber
syn match HeadAgendaFilename /^\(.*\/\?\)\+\.hd/ contained
syn match HeadAgendaLineNumber /|\d\+|\d\+|/ contained

syn match HeadAgendaSectionLine /^=.*$/
syn match HeadAgendaContextLine /^-.*$/
syn match HeadAgendaWarningLine /^!.*$/
syn match HeadAgendaFilterLine /^#.*$/

let b:current_syntax = "agenda"

hi def link HeadAgendaFilename Directory
hi def link HeadAgendaLineNumber Directory
hi def link HeadAgendaHeading Identifier
hi def HeadAgendaSectionLine ctermfg=224 cterm=underline
hi def HeadAgendaContextLine ctermfg=224 cterm=bold
hi def HeadAgendaWarningLine ctermfg=13 cterm=bold,underline
hi def link HeadAgendaFilterLine Comment

