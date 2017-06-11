"""
" This file contains functions to build or execute commands.
""

"""
" Last command executed.
"
" @var dict
"
let s:lastCmd = {'cmd': '', 'target': ''}

"""
" Execute the command built by the given function builder.
"
" @param  string|func a:fnCmdBuilder Function to build a command.
" @param  dict        a:config
"   Valid keys:
"     'params' list    Params for the build function.
"     'target' string  Target file to execute on if any.
"     'asLast' boolean Keep the command as the last one or not.
" @return list The command and target executed.
"
func! vphpw#cmd#Execute(fnCmdBuilder, config)
  try
    let cmd = call(
      \ a:fnCmdBuilder,
      \ get(a:config, 'params', []),
    \)
  catch /.*/
    echoerr v:exception
  endtry
  call vphpw#cmd#RunCommand(cmd, a:config)
endfunc

"""
" Execute the given command.
"
" @param string a:cmd
" @param dict   a:config
"   Valid keys:
"     'target' string  Target file to execute on, if any.
"     'asLast' boolean Keep the command as the last one or not.
"
func! vphpw#cmd#RunCommand(cmd, config)
  let target = get(a:config, 'target', '')
  if get(a:config, 'asLast', 0)
    let s:lastCmd.cmd = a:cmd
    let s:lastCmd.target = target
  endif

  let fullCmd = a:cmd . (!empty(target) ? ' ' . shellescape(target) : '')
  if vphpw#util#GetOpt('vphpw_debug', 0)
    echom fullCmd
    echom string(s:lastCmd)
  endif
  call clearmatches()
  if vphpw#util#GetOpt('vphpw_use_dispatch', 0)
    exec 'Dispatch' fullCmd
  else
    exec '!' fullCmd
  endif
endfunc

"""
" Run the last command on the given target. If target
" is empty, use the last target if there is one.
"
" @param  string a:target
" @return int    Return 0 for success, -1 for no last command.
"
func! vphpw#cmd#RunLastCommand(target)
  if empty(s:lastCmd.cmd)
    return -1
  endif

  " Use the given target if any. Otherwise, use the last target.
  if !empty(a:target)
    let s:lastCmd.target = a:target
  endif
  call call('vphpw#cmd#RunCommand', [
    \ s:lastCmd.cmd,
    \ {'target': s:lastCmd.target}
  \])
  return 0
endfunc

"""
" Build a PHP command.
"
" @param  list   a:000 Extra params to build the command.
" @return string
"
func! vphpw#cmd#BuildPhpCommand(...)
  let runArgs = vphpw#cmd#ShellEscapeOpts(vphpw#util#GetOpt('vphpw_php_opts', []))
  return vphpw#util#GetOpt('vphpw_php_cmd', 'php') . ' '
       \ . join(runArgs + a:000, ' ')
endfunc

"""
" Build a PHPUnit command.
"
" @param  list   a:000 Extra params.
" @return string
" @throws "Unsupported test framework (framework)"
"
func! vphpw#cmd#BuildTestCommand(...)
  let testArgs = vphpw#cmd#ShellEscapeOpts(vphpw#util#GetOpt('vphpw_test_opts', []))
  let cmd = vphpw#util#GetOpt('vphpw_test_cmd', '')
  if empty(cmd)
    let cmd = s:GetDefaultTestCmd()
  endif
  return vphpw#util#GetOpt('vphpw_test_cmd', 'phpunit') . ' '
       \ . join(testArgs + a:000, ' ')
endfunc

"""
" Shell-escape the given list of options.
"
" @param  list a:opts
" @return list
"
func! vphpw#cmd#ShellEscapeOpts(opts)
  return map(copy(a:opts), 's:EscapeOpt(v:val)')
endfunct

"""
" Shell-escape the given option.
"
" @param  string a:opt
" @return string
"
func! s:EscapeOpt(opt)
  return a:opt =~ '\v^-' ? a:opt : shellescape(a:opt)
endfunc

"""
" Determine the default test command based on the test framework.
"
" @return string
" @throws "Unsupported test framework (framework)"
"
func! s:GetDefaultTestCmd()
  let framework = vphpw#util#GetOpt('vphpw_test_framework', 'phpunit')
  if framework ==? 'phpunit'
    return 'phpunit'
  elseif framework ==? 'codeception'
    return 'codecept run'
  endif
  throw 'Unsupported test framework (' . framework . ')'
endfunc
