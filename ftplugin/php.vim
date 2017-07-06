"""
" Syntax-check the current file.
"
func! VphpwCheckSyntax()
  call vphpw#cmd#Execute('vphpw#cmd#BuildPhpCommand', {
    \ 'params': ['-l'],
    \ 'target': expand('%')
  \})
endfunc

"""
" Run the current file.
"
func! VphpwRunPhp()
  call vphpw#cmd#Execute('vphpw#cmd#BuildPhpCommand', {
    \ 'target': expand('%'),
    \ 'asLast': 1
  \})
endfunc

"""
" Run the last command on the last target.
"
func! VphpwRunLastCommand()
  if -1 == vphpw#cmd#RunLastCommand('')
    echom 'No last command'
  endif
endfunc

"""
" Run the last command on the current buffer.
"
func! VphpwRunLastCommandCurrentBuffer()
  if -1 == vphpw#cmd#RunLastCommand(expand('%'))
    echom 'No last command'
  endif
endfunc

"""
" Import a `use` statement of the class name under the cursor.
"
" @param dict a:config
"    {
"      'inline': inline or not. Default: 0
"      'importAs': should alias the imported class? Default: 0
"      'modeAfter': i (insert) or n (normal). Default: n
"      'prefixSlash': should prefix class with a backslash? Default: 1
"      'sort': should sort after import? Default: 1
"    }
"
func! VphpwImportClass(config)
  let class = vphpw#class#GetClassAtCursor()
  if empty(class)
    echo 'No class name found at the cursor.'
    return
  endif

  let alias = class
  if get(a:config, 'importAs', 0)
    let alias = input('Import `' . class . '` as: ', class)
    if empty(alias)
      echo 'Import canceled.'
      return
    endif
  endif

  let hasAlias = alias != class
  let inline   = !hasAlias && get(a:config, 'inline', 0)

  " Check if class is already imported.
  if !inline && vphpw#namespace#IsClassImported(alias)
    echo 'Name `' . alias . '` already imported.'
    return
  endif

  " Get the namespace of the class.
  try
    let classNs = vphpw#namespace#GetNamespaceFromClassFile(class)
  catch /^Tag selection canceled/
    return
  catch /.*/
    call vphpw#util#Error(v:exception)
    return
  endtry

  " For no alias, do nothing if class has the same namespace.
  let currentNs = vphpw#namespace#GetNamespaceOfCurrentBuffer()
  if !hasAlias && classNs == currentNs
    echo 'Same namespace. Nothing to import.'
    return
  endif

  " Construct the full class name to import.
  let fullClass = empty(classNs) ? class : classNs . '\' . class

  " Try to append the use statement (no alias for inline).
  try
    if inline
      let classToReplace = fullClass
      if get(a:config, 'prefixSlash', 1)
        let classToReplace = '\' . classToReplace
      endif
      call vphpw#util#ReplaceWordAtCursor(classToReplace)
    else
      call vphpw#namespace#AppendUseStatement(fullClass, (hasAlias ? alias : ''))
    endif
  catch /.*/
    call vphpw#util#Error(v:exception)
    return
  endtry

  " Sort for statement appending.
  if !inline && get(a:config, 'sort', 1)
    call vphpw#namespace#SortUses(vphpw#util#GetOpt('vphpw_sort_import_ignore_case', 1))
  endif

  " Change the class at the cursor to the alias if any.
  if hasAlias
    call vphpw#util#ReplaceWordAtCursor(alias)
  endif

  " Go to the specified vi mode after the changes.
  if get(a:config, 'modeAfter', 'n') == 'i'
    call feedkeys('a', 'n')
  endif
endfunc

"""
" Sort the continues imports.
"
func! VphpwSortImports()
  if vphpw#namespace#SortUses(vphpw#util#GetOpt('vphpw_sort_import_ignore_case', 1))
    echo '`use` statements sorted.'
  else
    echo 'No sorting performed.'
  endif
endfunc

"""
" Generate docblock for the closest method to the cursor.
"
" @param boolean a:afterCursor After the cursor?
"
func! VphpwDocClosestMethod(afterCursor)
  " Search the closest method.
  let methodInfo = vphpw#class#GetClosestMethod(a:afterCursor)
  if !methodInfo.startPos[0]
    echom 'No method found'
    return
  endif

  " Generate docblock.
  let [lnStart, lnEnd] = vphpw#docblock#GenerateDocblock(methodInfo, {
    \ 'typePlaceholder': vphpw#util#GetOpt('vphpw_doc_type_placeholder', "'...'")
  \})

  " Line up params.
  if vphpw#util#GetOpt('vphpw_doc_gen_lineup', 1)
    call vphpw#docblock#AlignDocblock(lnStart, lnEnd)
  endif

  " Jump to the docblock.
  call cursor(lnStart, 0)
  normal! $
endfunc

"""
" Line up tags, type, and variable names in the docblock. If no
" range is given, consider any docblock enclosing the cursor.
"
func! VphpwAlignDocblock() range
  let [startLine, endLine] = a:firstline < a:lastline
                         \ ? [a:firstline, a:lastline]
                         \ : vphpw#class#GetEnclosingDocblockLineNumbers()
  if !startLine || !endLine
    echom 'Cursor not in a docblock'
    return
  end
  call vphpw#docblock#AlignDocblock(startLine, endLine)
endfunc

"""
" Reset a docblock to no line-up. If no range is given,
" consider any docblock enclosing the cursor.
"
func! VphpwResetDocblock() range
  let [startLine, endLine] = a:firstline < a:lastline
                         \ ? [a:firstline, a:lastline]
                         \ : vphpw#class#GetEnclosingDocblockLineNumbers()
  if !startLine || !endLine
    echom 'Cursor not in a docblock'
    return
  end
  call vphpw#docblock#ResetDocblock(startLine, endLine)
endfunc

"""
" Delete the the docblock enclosing the cursor.
"
func! VphpwDeleteEnclosingDocblock()
  let [startLine, endLine] = vphpw#class#GetEnclosingDocblockLineNumbers()
  if !startLine || !endLine
    echom 'Cursor not in a docblock'
    return
  end

  " Delete lines from startLine to endLine.
  exec startLine . ',' . endLine . 'd'
endfunc

"""
" Test the current file.
"
func! VphpwTestAll()
  call vphpw#cmd#Execute('vphpw#cmd#BuildTestCommand', {
    \ 'target': expand('%'),
    \ 'asLast': 1
  \})
endfunc

"""
" Test the closest test case to the cursor.
"
" @param boolean a:afterCursor
"
func! VphpwTestClosestTestCase(afterCursor)
  let testCase = vphpw#class#GetClosestTestCaseName(a:afterCursor)
  if empty(testCase)
    echom 'No test case found'
    return
  endif

  let cmdConfig = {'target': expand('%'), 'asLast': 1}
  let testFramework = vphpw#util#GetOpt('vphpw_test_framework', 'phpunit')
  if testFramework ==? 'phpunit'
    let cmdConfig.params = ['--filter', testCase]
  elseif testFramework ==? 'codeception'
    let cmdConfig.target = cmdConfig.target . ':' . testCase
  else
    echom 'Unsupported test framework (' . testFramework . ')'
    return
  endif

  call vphpw#cmd#Execute('vphpw#cmd#BuildTestCommand', cmdConfig)
  exec 'match Search /' . testCase . '/'
endfunc

"""
" Test with the manually specified options. Default options
" are skipped.
"
func! VphpwTestWithOptions()
  let opts = input('Options: ')
  if empty(opts)
    return
  endif
  let answer = input('Is target the current buffer? (Y/n) ')
  call vphpw#cmd#Execute('vphpw#cmd#BuildTestCommand', {
    \ 'params': [opts],
    \ 'target': empty(answer) || answer ==? 'y' ? expand('%') : '',
    \ 'asLast': 1
  \})
endfunc

"""
" Clear all matches (hilight).
"
func! VphpwClearMatches()
  call clearmatches()
endfunc

"""
" Perform the default mapping.
"
func! VphpwMapKeys()
  nnoremap <buffer> <silent> <Leader>rr :call VphpwRunPhp()<CR>
  nnoremap <buffer> <silent> <Leader>rl :call VphpwRunLastCommand()<CR>
  nnoremap <buffer> <silent> <Leader>rb :call VphpwRunLastCommandCurrentBuffer()<CR>
  nnoremap <buffer> <silent> <Leader>ta :call VphpwTestAll()<CR>
  nnoremap <buffer> <silent> <Leader>tk :call VphpwTestClosestTestCase(0)<CR>
  nnoremap <buffer> <silent> <Leader>tj :call VphpwTestClosestTestCase(1)<CR>
  nnoremap <buffer> <silent> <Leader>to :call VphpwTestWithOptions()<CR>
  nnoremap <buffer> <silent> <Leader>dk :call VphpwDocClosestMethod(0)<CR>
  nnoremap <buffer> <silent> <Leader>dj :call VphpwDocClosestMethod(1)<CR>
  noremap  <buffer> <silent> <Leader>dl :call VphpwAlignDocblock()<CR>
  nnoremap <buffer> <silent> <Leader>dd :call VphpwDeleteEnclosingDocblock()<CR>
  noremap  <buffer> <silent> <Leader>dr :call VphpwResetDocblock()<CR>
  nnoremap <buffer> <silent> <Leader>cc :call VphpwCheckSyntax()<CR>
  nnoremap <buffer> <silent> <Leader>cm :call VphpwClearMatches()<CR>
  nnoremap <buffer> <silent> <Leader>is :call VphpwSortImports()<CR>
  nnoremap <buffer> <silent> <Leader>ic :call VphpwImportClass({'inline': 0})<CR>
  nnoremap <buffer> <silent> <Leader>ia :call VphpwImportClass({'inline': 0, 'importAs': 1})<CR>
  nnoremap <buffer> <silent> <Leader>ii :call VphpwImportClass({'inline': 1, 'modeAfter': 'n', 'prefixSlash': 1})<CR>
  nnoremap <buffer> <silent> <Leader>id :call VphpwImportClass({'inline': 1, 'modeAfter': 'n', 'prefixSlash': 0})<CR>
  inoremap <buffer> <silent> <C-@>ic <Esc>:call VphpwImportClass({'inline': 0, 'modeAfter': 'i'})<CR>
  inoremap <buffer> <silent> <C-@>ia <Esc>:call VphpwImportClass({'inline': 0, 'importAs': 1, 'modeAfter': 'i'})<CR>
  inoremap <buffer> <silent> <C-@>ii <Esc>:call VphpwImportClass({'inline': 1, 'modeAfter': 'i', 'prefixSlash': 1})<CR>
  inoremap <buffer> <silent> <C-@>id <Esc>:call VphpwImportClass({'inline': 1, 'modeAfter': 'i', 'prefixSlash': 0})<CR>
  inoremap <buffer> <silent> <C-Space>ic <Esc>:call VphpwImportClass({'inline': 0, 'modeAfter': 'i'})<CR>
  inoremap <buffer> <silent> <C-Space>ia <Esc>:call VphpwImportClass({'inline': 0, 'importAs': 1, 'modeAfter': 'i'})<CR>
  inoremap <buffer> <silent> <C-Space>ii <Esc>:call VphpwImportClass({'inline': 1, 'modeAfter': 'i', 'prefixSlash': 1})<CR>
  inoremap <buffer> <silent> <C-Space>id <Esc>:call VphpwImportClass({'inline': 1, 'modeAfter': 'i', 'prefixSlash': 0})<CR>
endfunc

if vphpw#util#GetOpt('vphpw_use_default_mapping', 0)
  call VphpwMapKeys()
endif
