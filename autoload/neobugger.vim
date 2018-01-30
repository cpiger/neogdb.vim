if !exists("s:init")
    let s:init = 1
    silent! let s:log = logger#getLogger(expand('<sfile>:t'))

    " Every module must derive from tlib#Object
    let s:modules = {}
    let s:current_module = ""
endif


function! neobugger#New(module, ...)
    let l:__func__ = "neobugger#New"
    try
        if neobugger#Exists(a:module)
            if g:restart_app_if_gdb_running
                call neobugger#Handle(a:module, "Restart", a:000)
                return
            endif
            echomsg l:__func__. 'neobugger['.a:module.' already running!'
        else
            let l:new = 'neobugger#'.a:module.'#New'

            silent! call s:log.info(l:new. "(): args=", string(a:000))
            let l:obj = call(l:new, a:000)
            call extend(s:modules, {a:module: l:obj})
            let s:current_module = a:module
        endif
    catch
        echomsg l:__func__. ' error:' . v:exception
    endtry
endfunction


function! neobugger#Exists(module)
    return has_key(s:modules, a:module)
endfunction


function! neobugger#Remove(module)
    return remove(s:modules, a:module)
endfunction

function! neobugger#Handle(module, handle, ...)
    let l:__func__ = "neobugger#Handle"
    let l:module = a:module
    if a:module ==# 'current'
        let l:module = s:current_module
    endif

    try
        if !empty(l:module) && neobugger#Exists(l:module)
            if s:modules[l:module].RespondTo(a:handle)
                silent! call s:log.info(l:__func__, ': call ', l:module, '.', a:handle, '(args=', a:000,') ')
                "s:modules[l:module].Call(s:modules[l:module], a:handle, a:000)
                "call call(a:handle, a:000, s:modules[l:module])

                let l:args = a:000
                if len(a:000) > 0
                    if type(a:000[0]) == type([])
                        let l:args = a:000[0]
                    endif
                endif
                call call(s:modules[l:module][a:handle], l:args, s:modules[l:module])
                return
            endif
            echomsg l:__func__. ': module['. l:module. "] function '".a:handle. "' not exist, please report a bug if possible."
        else
            echomsg l:__func__. ': module['. l:module. "] not exist, please call it's start firstly."
        endif
    catch
        echomsg l:__func__. ' module['. l:module. "].".a:handle. "() error:". v:exception
    endtry
endfunction
