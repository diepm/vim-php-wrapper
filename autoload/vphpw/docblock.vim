"""
" Docblock related functions that will modify the current buffer.
""

"""
" Regex patterns for different tag types.
"   - Tags having 4 parts (tag, type, var, description)
"   - Tags having 3 parts (tag, type, description)
let s:pat4PartTag = '\@param|\@property|\@property-read|\@property-write'
let s:pat3PartTag = '\@return|\@throws'

"""
" Generate docblock for the closest method.
"
" @see vphpw#class#GetClosestMethod() For method info.
"
" @param dict a:methodInfo
" @param dict a:config
"   Valid keys:
"     'typePlaceholder' string Used for undetermined variable type.
" @return list [Docblock start line, Docblock end line]
"
func! vphpw#docblock#GenerateDocblock(methodInfo, config)
  let [lnNum, colNum] = a:methodInfo.startPos

  " Extract method's params.
  let params = vphpw#class#GetMethodParams(a:methodInfo.decl)
  let returnType = vphpw#class#GetMethodReturnType(a:methodInfo.decl)

  " Generate docblock.
  let indent  = repeat(' ', colNum - 1)
  let lnStart = lnNum - 1
  call append(lnStart, indent     . '/**')
  call append(lnStart + 1, indent . ' *')
  let offset = 2

  " Add @param tags.
  for [var, type] in params
    if empty(type)
      let type = get(a:config, 'typePlaceholder', "'...'")
    endif
    let txtOut = ' * @param ' . printf('%s %s', type, var)
    call append(lnStart + offset, indent . txtOut)
    let offset += 1
  endfor

  " Add @return tag if there is returnType.
  if !empty(returnType)
    let txtOut = ' * @return ' . (strpart(returnType, 0, 1) == '?'
                                  \ ? strpart(returnType, 1) . '|null'
                                  \ : returnType)
    call append(lnStart + offset, indent . txtOut)
    let offset += 1
  endif

  " Close docblock.
  let lnEnd = lnStart + offset
  call append(lnEnd, indent . ' */')

  return [lnStart + 1, lnEnd + 1]
endfunc

"""
" Reset a docblock to no line-up.
"
" @param int a:fromLine
" @param int a:toLine
"
func! vphpw#docblock#ResetDocblock(fromLine, endLine)
  let docLines  = s:ParseDocblockLines(a:fromLine, a:endLine)
  let paramFmt  = '%s %s %s %s'
  let returnFmt = '%s %s %s'
  for dict in docLines
    let txtOut = dict.prefix . ' ' . (
      \ dict['tag'] =~? '\v' . s:pat4PartTag
      \ ? printf(paramFmt, dict.tag, dict.type, dict.var, dict.desc)
      \ : printf(returnFmt, dict.tag, dict.type, dict.desc)
    \)
    call setline(dict.line, vphpw#util#StrTrimR(txtOut))
  endfor
endfunc

"""
" Align a docblock.
"
" @param int a:fromLine
" @param int a:toLine
"
func! vphpw#docblock#AlignDocblock(fromLine, toLine)
  let docLines = s:ParseDocblockLines(a:fromLine, a:toLine)
  let [lstTag, lstType, lstVar] = values(
    \ vphpw#util#GroupDictsByKeys(docLines, ['tag', 'type', 'var'])
  \)

  let maxTagLen  = vphpw#util#MaxStrLen(lstTag)
  let maxTypeLen = vphpw#util#MaxStrLen(lstType)
  let maxVarLen  = vphpw#util#MaxStrLen(lstVar)

  let paramFmt  = '%-' . maxTagLen . 'S '
              \ . '%-' . maxTypeLen . 'S '
              \ . '%-' . maxVarLen . 'S %s'
  let returnFmt = '%-' . maxTagLen . 'S '
              \ .  '%-' . maxTypeLen . 'S %s'

  for dict in docLines
    let txtOut = dict.prefix . ' ' . (
      \ dict['tag'] =~? '\v' . s:pat4PartTag
      \ ? printf(paramFmt, dict.tag, dict.type, dict.var, dict.desc)
      \ : printf(returnFmt, dict.tag, dict.type, dict.desc)
    \)
    call setline(dict.line, vphpw#util#StrTrimR(txtOut))
  endfor
endfunc

"""
" Extract docblock's tags, types, and variable names.
"
" @param  int  a:fromLine
" @param  int  a:toLine
" @return list [
"                {
"                  line: 10,
"                  prefix: '    * ',
"                  tag: '@param',
"                  type: '\Some\Model',
"                  var: '$var',
"                  desc: 'some description',
"                },
"                ...
"              ]
"
func! s:ParseDocblockLines(fromLine, toLine)
  " let paramPat  = '\c\v^(\s*\*)\s*(' . s:pat4PartTag . ')\s+([^$[:space:]]+)\s+(\$\w+)(\s+.*)?$'
  let paramPat  = '\c\v^(\s*\*)\s*(' . s:pat4PartTag . ')\s+([^[:space:]]+)\s+(\$\w+)(\s+.*)?$'
  let retPat  = '\c\v^(\s*\*)\s*(' . s:pat3PartTag . ')\s+([^$[:space:]]+)(\s+.*)?$'

  let lstDicts  = []
  for lnNum in range(a:fromLine, a:toLine)
    let line   = getline(lnNum)
    let tokens = matchlist(line, paramPat)
    if !empty(tokens)
      let [type, var, desc] = tokens[3:5]
    else
      let tokens = matchlist(line, retPat)
      if !empty(tokens)
        let [type, desc] = tokens[3:4]
        let var = ''
      else
        continue
      endif
    endif
    call add(lstDicts, {
      \ 'line': lnNum,
      \ 'prefix': tokens[1],
      \ 'tag': tokens[2],
      \ 'type': type,
      \ 'var': var,
      \ 'desc': vphpw#util#StrTrimL(desc),
    \})
  endfor
  return lstDicts
endfunc
