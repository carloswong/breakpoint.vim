if exists('g:loaded_breakpoint_vim')
    finish
endif

let g:loaded_breakpoint_vim = 1

sign define Breakpoint text=  texthl=DiagnosticSignOk

command! BreakpointToggle call breakpoint#Toggle()
command! BreakpointCreateByName call breakpoint#CreateByName()
command! BreakpointList call breakpoint#GetAllBreakpoints()
