## Vim PHP Wrapper

### 1. Introduction

**Vim PHP Wrapper** (**vphpw**) is a Vim plug-in to help improve PHP development
productivity. It provides functions for common tasks such as importing classes,
running, testing, or documenting PHP code as well as simple APIs for
custom tasks.

For unit testing, `vphpw` supports *PHPUnit* out of the box. *Codeception* is
also supported to a certain extent.

This plug-in can also be used with
[vim-dispatch](https://github.com/tpope/vim-dispatch) for a better,
non-disruptive development experience.

Requirements:
  * Tested with Vim 7.4 and 8. Might still work with 7.3.
  * Vim's `tags` for class import functions.

### 2. Features

For PHP development,

* Writing code:
  + Check for syntax (not in real-time).
  + Import classes.
  + Run the current PHP buffer with default or manually specified options.
  + Test with default or manually specified options.
  + Run a test class or specific test case.
  + Execute the last command on the last or current target.

* Documentation:
  + Generate docblock.
  + Align docblock.
  + Reset/Delete docblock.

A glance at the [default key mapping](#41-default-key-mapping) will give you
an idea of what common tasks `vphpw` provides.

This plug-in also exposes useful, well-documented APIs to write custom functions
for specific tasks. These can be grouped as follows.

* Class: Deal with PHP class buffer.
* Command: Build and execute commands.
* Docblock: Manipulate docblocks.
* Namespace: Work with namespaces.

### 3. Installation

Using pathogen.vim

```
cd ~/.vim/bundle
git clone https://github.com/diepm/vim-php-wrapper.git
```

Using Vundle

```
Plugin 'diepm/vim-php-wrapper'
```

Other methods should work as as well.

### 4. Usage

For a quick walk-through of PHP development with `vphpw` and some examples of
custom tasks, check out

https://github.com/diepm/vphpw-demos

For the details of options, functions, and APIs,

```
:help vphpw
```

or read the doc [here](./doc/vim-php-wrapper.txt).

#### 4.1. Default Key Mapping

The default key mapping is disabled by default. To enable,

```
let g:vphpw_use_default_mapping = 1
```

or for the buffer scope,

```
let b:vphpw_use_default_mapping = 1
```

The default mapping is as follows.

```
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
```

Regarding the "closest" functions, if the method is on the same line with
the cursor, it's considered below or after the cursor.

#### 4.2. Command Execution

By default, `vphpw` executes a command using Vim's `!`. This causes the current
session to wait for the shell process to finish. If your Vim has `vim-dispatch`
installed, you can configure `vphpw` to use that plug-in by

```
let g:vphpw_use_dispatch = 1
```

### 5. License

MIT
