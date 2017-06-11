"""
" Functions to deal with run/test options.
""

"""
" Show the current global/buffer default run options.
"
func! vphpw#opt#ShowRunOptions()
  echom string(vphpw#util#GetOpt('vphpw_php_opts', []))
endfunc

"""
" Clear the buffer default run options.
"
func! vphpw#opt#ClearBufferRunOptions()
  unlet b:vphpw_php_opts
endfunc

"""
" Show the current global/buffer default test options.
"
func! vphpw#opt#ShowTestOptions()
  echom string(vphpw#util#GetOpt('vphpw_test_opts', []))
endfunc

"""
" Clear the buffer default test options.
"
func! vphpw#opt#ClearTestOptions()
  unlet b:vphpw_test_opts
endfunc
