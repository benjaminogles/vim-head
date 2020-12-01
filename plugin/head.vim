
augroup HeadPlugin
  au!
  autocmd BufHidden \*Capture\* call head#capture#close()
augroup End

command! HeadCapture :call head#capture#edit('split', head#menu#template())
command! HeadAgenda :call head#agenda#report('edit', head#menu#agenda())
command! HeadVsAgenda :call head#agenda#report('vsplit', head#menu#agenda())
command! HeadSpAgenda :call head#agenda#report('split', head#menu#agenda())
command! HeadPrAgenda :call head#agenda#report('pedit', head#menu#agenda())
command! HeadHeading :call head#menu#target(head#config#refile_files(), {h -> h.goto('edit')})
command! HeadVsHeading :call head#menu#target(head#config#refile_files(), {h -> h.goto('vsplit')})
command! HeadSpHeading :call head#menu#target(head#config#refile_files(), {h -> h.goto('split')})
command! HeadPrHeading :call head#menu#target(head#config#refile_files(), {h -> h.goto('pedit')})
command! -range HeadPromote <line1>,<line2>:call head#promote()
command! -range HeadDemote <line1>,<line2>:call head#demote()
command! -range -nargs=? HeadChangeKeyword <line1>,<line2>:call head#change_keyword(head#menu#keyword(<f-args>))
command! -range -nargs=? HeadChangeDate <line1>,<line2>:call head#change_prop('date', head#menu#date(<f-args>))
command! -range HeadRefile <line1>,<line2>:call head#refile()
command! -range HeadArchive <line1>,<line2>:call head#archive()
command! HeadClockIn :call head#clock_in()
command! HeadClockOut :call head#clock_out()

