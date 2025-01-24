let s:filename = '.bpt'
let s:breakpoint_list = []
let s:group_name = '__BREAKPOINTS__'
" example:
" [{'type': 'location', 'destination': '/path/to/file', 'linenum': 1}]
" [{'type': 'symbol', 'destination': 'symbol_name', 'linenum': 0}]

function! s:find_project_root()
    let mask = get(g:, 'breakpoint_project_root', '.git')
    let project_file = findfile(mask, '.;')

    let target = getcwd()
    if !empty(project_file)
        let target = fnamemodify(project_file, ':h')
    endif

    return target
endfunction

function! s:get_breakpoint_list_file()
    let root = s:find_project_root()
    let file = findfile(s:filename, root)

    if empty(file)
        let file = root . '/' . s:filename
    endif

    return file
endfunction

function! s:load_from_file()
    let file = s:get_breakpoint_list_file()
    let lines = readfile(file)

    for line in lines
        let items = split(line)
        if len(items) != 2
            continue
        endif
    
        let location = split(item[1], ':')
    
        let linenum = 0
        if len(location) == 2
            let linenum = location[1]
        endif
    
        let entry = {'type': items[0], 'destination': location[0], 'linenum': linenum}
        call add(s:breakpoint_list, entry)
    endfor
endfunction

function! s:write_to_file()
    let lines = []
    for bp in s:breakpoint_list
        let line = bp['type'] . ' ' . bp['destination']
        if bp['type'] == 'location'
            let line = line .':' . string(bp['linenum'])
        endif

        call add(lines, line)
    endfor

    let file = s:get_breakpoint_list_file()
    call writefile(lines, file)
endfunction

function! s:update_file(timer)
    call s:write_to_file()
endfunction

function! breakpoint#Toggle()
    let linenum = line('.')
    let buf = bufnr()
    let placed = sign_getplaced(buf, {'lnum': linenum, 'group': s:group_name})
    let signs = placed[0]['signs']

    let filename = expand('%:p')
    if len(signs) == 0 
        call sign_place(0, s:group_name, 'Breakpoint', buf, {'lnum': linenum})
        let entry = {'type': 'location', 'destination': filename, 'linenum': linenum}
        call add(s:breakpoint_list, entry)
    else
        call sign_unplace(s:group_name, {'buffer': buf, 'id': signs[0]['id']})

        for entry in s:breakpoint_list
            if entry['type'] == 'location' && entry['destination'] == filename && entry['linenum'] == linenum
                let idx = index(s:breakpoint_list, entry)
                call remove(s:breakpoint_list, idx)
            endif
        endfor
    endif
    call timer_start(100, function('s:update_file'))
endfunction

function! breakpoint#CreateByName()
    let symbol = input('Create breakpoint by symbol: ')
    if !empty(symbol)
        let entry = {'type': 'symbol', 'destination': symbol, 'linenum': 0}
        call add(s:breakpoint_list, entry)
        call timer_start(100, function('s:update_file'))
        redraw
        echom 'breakpoint added by name: ' . symbol
    endif
endfunction

function! breakpoint#GetAllBreakpoints()
    let lines = []
    for entry in s:breakpoint_list
        if entry['type'] == 'location'
            let buf = bufnr(entry['destination'])
            let text = getbufoneline(buf, entry['linenum'])
            call add(lines, {'bufnr': buf, 'text': text, 'lnum': entry['linenum']})
        elseif entry['type'] == 'symbol'
            let text = entry['destination']
            call add(lines, {'filename': 'SYMBOL', 'text': text})
        endif
    endfor

    call setqflist(lines , ' ')
    call setqflist([] , 'a', {'title': 'Breakpoints'})
    copen
endfunction
