"""
" This file contains utility functions shared among other APIs.
""

"""
" Report an error message.
"
" @param string a:msg
"
func! vphpw#util#Error(msg)
  echohl ErrorMsg | echo a:msg | echohl None
endfunc

"""
" Read a value of the given option.
"
" @param  string a:opt    Option name to get.
" @param  mixed  a:defVal Default value for option not found.
" @return mixed
"
func! vphpw#util#GetOpt(opt, defVal)
  if exists('b:' . a:opt)
    return eval('b:' . a:opt)
  elseif exists('g:' . a:opt)
    return eval('g:' . a:opt)
  else
    return a:defVal
  endif
endfunc

"""
" Trim trailing spaces.
"
" @param  string a:str
" @return string
"
func! vphpw#util#StrTrimR(str)
  return substitute(a:str, '\v^(.*[^[:space:]])\s+$', '\1', 'g')
endfunc

"""
" Trim leading spaces.
"
" @param  string a:str
" @return string
"
func! vphpw#util#StrTrimL(str)
  return substitute(a:str, '\v^\s+([^[:space:]].*)$', '\1', 'g')
endfunc

"""
" Trim leading and trailing spaces.
"
" @param  string a:str
" @return string
"
func! vphpw#util#StrTrim(str)
  return substitute(a:str, '\v^\s*([^[:space:]].*[^[:space:]])\s*$', '\1', 'g')
endfunc

"""
" Find the max string length in the list.
"
" @param  string[] a:lstStr List of strings.
" @return int
"
func! vphpw#util#MaxStrLen(lstStr)
  return max(map(copy(a:lstStr), 'strlen(v:val)'))
endfunc

"""
" Replace the word under the cursor by the given text.
"
" @param string a:txt
"
func! vphpw#util#ReplaceWordAtCursor(txt)
  call feedkeys('ciw' . a:txt . "\<esc>", 'n')
endfunc

"""
" Group values of list of dicts by a list of keys.
"
" @param  list a:lstDict List of dicts.
" @param  list a:lstKeys List of keys.
" @return dict { k1: [v11, v12...], k2: [v21, v22...]... }
"
func! vphpw#util#GroupDictsByKeys(lstDict, lstKeys)
  let retDict = {}
  for key in a:lstKeys
    let retDict[key] = []
    for dict in a:lstDict
      call add(retDict[key], dict[key])
    endfor
  endfor
  return retDict
endfunc
