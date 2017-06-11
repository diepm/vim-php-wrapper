"""
" This file contains functions related to the current class file such as
" searching for methods, docblocks, or test cases.
"
" For functions based on the cursor, if the method is on the same line as
" the cursor, it's considered below the cursor.
""

"""
" Get the class name under the cursor.
"
" Empty string is returned for class name not found
" or invalid.
"
" @return string
"
func! vphpw#class#GetClassAtCursor()
  let class = expand('<cword>')
  return match(class, '\v^\h\w*') == 0 ? class : ''
endfunc

"""
" Search the closest method to the cursor.
"
" @param  boolean a:afterCursor
" @return dict    { startPos: [int, int], decl: string }
"
func! vphpw#class#GetClosestMethod(afterCursor)
  let info = {
    \ 'startPos': [0, 0],
    \ 'decl': '',
  \}

  let searchFlags = a:afterCursor ? 'W' : 'bW'
  let methodPat   = '\v\c(public|private|protected)\s+(static\s+)?function\s+\_[^{]+'

  " Keep the current position.
  let curPos = getpos('.')

  " Search from column 1.
  normal! 0
  let startPos = searchpos(methodPat, searchFlags)
  if !startPos[0]
    return info
  endif

  let endLine = search('\v\{', 'nW')
  echom endLine
  call cursor(curPos[1:])

  if !endLine
      return info
  endif

  let info.startPos = startPos
  let info.decl     = join(getline(startPos[0], endLine), '')
  return info
endfunc

"""
" Search the closest test case name to the cursor.
"
" @param  boolean a:afterCursor
" @return string
"
func! vphpw#class#GetClosestTestCaseName(afterCursor)
  let lineNo = vphpw#class#GetClosestTestCase(a:afterCursor)
  if !lineNo
    return ''
  endif
  return s:GetTestCaseName(getline(lineNo))
endfunc

"""
" Search the closest test case to the cursor.
"
" @param  boolean a:afterCursor
" @return int     Line number
" @throws "Unsupported test framework (framework)"
"
func! vphpw#class#GetClosestTestCase(afterCursor)
  " This will throw exception for unsupported test framework.
  let namePat = s:GetTestCaseNamePattern()

  if a:afterCursor
    let flags = 'ncW'
  else
    let flags = 'bncW'
  endif

  let curPos = getpos('.')
  normal! 0
  let lnNum  = search('\v\c^\s*public\s+function\s+(' . namePat . ')\s*\(.*$', flags)
  call cursor(curPos[1:])
  return lnNum
endfunc

"""
" Determine the test case name pattern based on the test framework.
"
" @return string Regex pattern.
" @throws "Unsupported test framework (framework)"
"
func! s:GetTestCaseNamePattern()
  let framework = vphpw#util#GetOpt('vphpw_test_framework', 'phpunit')
  let style = vphpw#util#GetOpt('vphpw_test_style', '')
  if framework ==? 'phpunit' || style ==? 'phpunit'
    return 'test\w+'
  elseif framework ==? 'codeception'
    return '\w+'
  endif
  throw 'Unsupported test framework (' . framework . ')'
endfunc

"""
" Extract the test case name from the given line.
"
" @param  string a:line
" @return string
"
func! s:GetTestCaseName(line)
  return substitute(a:line, '\v\c<public>|<function>|\s+|(\(.*$)', '', 'g')
endfunc

"""
" Extract the parameters of the given method declaration.
"
" @param  string a:methodDecl The method declaration.
" @return list   [[var, type], ...]
"
func! vphpw#class#GetMethodParams(methodDecl)
  " Method decl: public function someName(...) : SomeType
  let strParams = get(matchlist(a:methodDecl, '\v\((.*)\)'), 1, '')
  let lstParams = split(strParams, ',')
  let retList   = []
  for param in lstParams
    let [xx, type, var; rest] = matchlist(
      \ param,
      \ '\v\s*([^$[:space:]]+\s)?\s*\&?(\$\w+).*$'
    \)
    let type = vphpw#util#StrTrim(type)
    call add(retList, [vphpw#util#StrTrim(var), vphpw#util#StrTrim(type)])
  endfor
  return retList
endfunc

"""
" Extract the return type of the given method declaration.
"
" @param  string a:methodDecl The method declaration.
" @return string The return type or empty.
"
func! vphpw#class#GetMethodReturnType(methodDecl)
  " Method decl: public function someName(...) : Ns\SomeType
  let pat = '\v\c\)\s*\:\s*([a-z0-9_\\]*)'
  return get(matchlist(a:methodDecl, pat, 0, 1), 1, '')
endfunc

"""
" Get line numbers of the docblock enclosing the cursor.
"
" @return [int, int] Return [0, 0] if no docblock is found.
"
func! vphpw#class#GetEnclosingDocblockLineNumbers()
  " For some reason, searchpair() works if the cursor is
  " at column 2 of the same line for some edge cases.
  let curPos = getpos('.')
  call cursor(0, 2)

  let startPat = '\v\s*/\*\*'
  let endPat   = '\v\s*\*/\s*'

  " Search for the docblock open `/**`.
  let openLine = searchpair(startPat, '', endPat, 'bnW')
  if openLine <= 0
    call cursor(curPos[1:])
    return [0, 0]
  end

  " Search for the docblock close `*/`.
  let closeLine = searchpair(startPat, '', endPat, 'nW')
  if closeLine <= 0
    call cursor(curPos[1:])
    return [0, 0]
  end

  " Restore the cursor and return.
  call cursor(curPos[1:])
  return [openLine, closeLine]
endfunc
