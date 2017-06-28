"""
" This file contains functions related to namespace.
""

"""
" Append a use statement of the given class to the current buffer.
"
" If the buffer has other `use` statements, the new statement will be appended
" below the last one. If not, the statement is appended below the `require`,
" `require_once`, `include`, `include_once`, or `namespace` statements,
" whichever comes first, with an additional blank line. If none of those found,
" the `use` statement is appended below the php tag (`<?` or `<?php`) also with
" a blank line. Otherwise, an exception is thrown for an invalid PHP buffer.
"
" @param  string a:fullClass
" @param  string a:alias
" @throws "Current buffer is not a valid PHP file."
"
func! vphpw#namespace#AppendUseStatement(fullClass, alias) abort
  " Find the line to append the use stmt.
  let lnum = search('\v^<use>', 'bn')
  let newBlankLine = 0
  if !lnum
    " No use statement found. Try require, namespace, or PHP tag.
    let lnum = search('\v^<require>|<require_once>|<include>|<include_once>|<namespace>|\<\?(php)?', 'bn')
    if lnum
      " Append an additional blank line.
      let newBlankLine = 1
    else
      throw "Current buffer is not a valid PHP file."
    endif
  endif

  let stmt = 'use ' . a:fullClass . (!empty(a:alias) ? ' as ' . a:alias : '') . ';'
  if newBlankLine
    call append(lnum, ['', stmt])
  else
    call append(lnum, stmt)
  endif
endfunc

"""
" Check if the current buffer already has the given class name imported.
"
" @param  string  a:class
" @return boolean
"
func! vphpw#namespace#IsClassImported(class)
  let classPat1 = a:class . '\s*;'
  let classPat2 = '\w+\s+as\s+' . a:class . '\s*;'
  let usePat = '\v\c^use\s+\\?(\w+\\)*(' . classPat1 . '|' . classPat2 . ')'
  return search(usePat, 'bn')
endfunc

"""
" Get the namespace of the current buffer.
"
" @return string Empty string for namespace not found.
"
func! vphpw#namespace#GetNamespaceOfCurrentBuffer()
  let nsLine = search('\v^namespace\s+', 'n')
  if !nsLine
    return ''
  endif
  let matches = matchlist(getline(nsLine), '\v^\s*namespace\s+\\?((\w|\\)+)\s*;')
  return get(matches, 1, '')
endfunc

"""
" Extract the namespace from the file of the given class
" name. The file is found using Vim's tag.
"
" @param  string a:className
" @return string Empty string for namespace not found.
" @throws Vim tags exception.
" @throws "Tag selection canceled."
"
func! vphpw#namespace#GetNamespaceFromClassFile(className) abort
  " Keep the current win number to go back.
  let bufNum = bufnr('%')
  let maxNum = bufnr('$')
  let curView = winsaveview()

  " Try to open the class file from tag in preview window. Also
  " disable filetype detection for PHP plugins not activated.
  filetype off
  try
    exec 'tjump' a:className
  catch /.*/
    echoerr v:exception
  finally
    filetype on
  endtry

  " Tag selection canceled.
  if bufNum == bufnr('%')
    throw 'Tag selection canceled.'
  endif

  let ns = vphpw#namespace#GetNamespaceOfCurrentBuffer()

  " Go back and clean up.
  let tmpBufNum = bufnr('%')
  exec 'buffer #'

  " If the temp buffer > the previous max one, it's new; can wipe out.
  if tmpBufNum > maxNum
    exec 'bwipe! #'
  endif
  call winrestview(curView)
  return ns
endfunc

"""
" Sort continuous `use` lines.
"
" @return boolean 0 if no sort is done.
"
func! vphpw#namespace#SortUses()
  let curView = winsaveview()
  normal! gg
  let pat = '\v\c^use\s+\\?[a-z0-9_\\]+(\s+as.+)?\s*;'
  let firstLineNum = search(pat, 'W')
  if firstLineNum < 0
    call winrestview(curView)
    return 0
  endif
  let lastLineNum = search(pat, '', firstLineNum + 1)
  let tmpLineNum  = lastLineNum
  while tmpLineNum > firstLineNum
    let lastLineNum = tmpLineNum
    let tmpLineNum = search(pat, '', lastLineNum + 1)
  endwhile
  if lastLineNum <= firstLineNum
    call winrestview(curView)
    return 0
  endif
  exec firstLineNum . ',' . lastLineNum . 'sort'
  call winrestview(curView)
  return 1
endfunc
