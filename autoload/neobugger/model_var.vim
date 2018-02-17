if !exists("s:script")
    let s:script = expand('<sfile>:t')
    " exists("*logger#getLogger")
    silent! let s:log = logger#getLogger(s:script)

    let s:prototype = tlib#Object#New({
                \ '_class': ['ModelVariable'],
                \ })
endif


" Constructor
function! neobugger#model_var#New()
    "{
    let l:__func__ = substitute(expand('<sfile>'), '.*\(\.\.\|\s\)', '', '')

    let l:model = s:prototype.New(a:0 >= 1 ? a:1 : {})
    let l:model.vars = {}
    let l:abstract = neobugger#model#New()
    call l:model.Inherit(l:abstract)

    return l:model
    "}
endfunction


function! s:prototype.Append(var_name, var_value)
    let l:model.vars[a:var_name] = a:var_value
endfunction


" @return -1 file-not-exist
"          0 succ
"          1 wait-end
function! s:prototype.ParseVar(srcfile, dstfile)
    let l:__func__ = "model_Var.ParseVar"
    silent! call s:log.info(l:__func__, '()')

    let self.vars = {}
    if !filereadable(a:srcfile)
        return -1
    endif
    let l:check_parse = 0
    let l:lines = readfile(a:srcfile)
    for l:line in l:lines
        let matches = matchlist(l:line, '\(.*\) = \(.*\)')
        if len(matches) < 2
            continue
        endif

        let l:key = matches[1]
        let l:val = matches[2]
        if match(l:val, '0x') != -1
            let l:check_parse = 1
        endif

        if match(l:key, '__FUNCTION__') != -1
            continue
        endif

        if match(l:val, '<optimized out>') != -1
            continue
        endif

        "echomsg 'ParseVar '. l:key . ' = '. l:val
        let self.vars[l:key] = l:val
    endfor

    if !l:check_parse
        return 0
    endif

    " Write command backto /tmp/gdb.cmd
    let l:lines = []
    let l:cmdstr = ""
    for [key, val] in items(self.vars)
        if match(val, '^0x') != -1
            let l:cmdstr = printf('whatis %s', key)
            call add(l:lines, "echo ". l:cmdstr. '\n')
            call add(l:lines, l:cmdstr)
        endif
    endfor
    call writefile(l:lines, a:dstfile)
    return 1
endfunction


" Output Sample:
"
"> (gdb) whatis clt
"> type = struct wad_http_client *
"
function! s:prototype.ParseVarEnd(filename)
    let l:__func__ = "model_Var.ParseVarEnd"

    if !filereadable(a:filename)
        return
    endif

    let l:lines = readfile(a:filename)

    let next_is_key = 1
    for l:line in l:lines
        if next_is_key
            let next_is_key = 0

            let matches = matchlist(l:line, 'whatis \(.*\)')
            "silent! call s:log.info(l:__func__, ' line=', l:line, ' key=', string(matches))
            if len(matches) > 0
                let l:key = matches[1]
            endif
        else
            let next_is_key = 1

            let matches = matchlist(l:line, 'type = \(.*\)')
            "silent! call s:log.info(l:__func__, ' line=', l:line, ' val=', string(matches))
            if len(matches) > 0
                let l:val = matches[1]
                if has_key(self.vars, l:key)
                    let self.vars[l:key] = l:val
                endif
            endif
        endif
    endfor

    " view2window
    silent! call s:log.info(l:__func__, ' vars=', string(self.vars))
endfunction



" Get variable under cursor
function! s:prototype.get_selected()
  let line = getline(".")
  " Get its id - it is last in the string
  let match = matchlist(line, '.*\t\(\d\+\)$')
  let id = get(match, 1)
  if id
    let variable = g:RubyDebugger.variables.find_variable({'id' : id})
    return variable
  else
    return {}
  endif
endfunction

