" Syntax for the pickaxe.nvim blame popup.
" Self-contained reimplementation of git-messenger.vim's gitmessengerpopup
" highlighting so the plugin carries no dependency on git-messenger.vim.

if exists('b:current_syntax')
    finish
endif

syn match pickaxeHeader '^ \=\%(History\|Commit\|\%(Author \|Committer \)\=Date\|Author\|Committer\):' display
syn match pickaxeHash '\%(^ \=Commit: \+\)\@<=[[:xdigit:]]\+' display
syn match pickaxeHistory '\%(^ \=History: \+\)\@<=#\d\+' display
syn match pickaxeEmail '\%(^ \=\%(Author\|Committer\): \+.*\)\@<=<.\+>' display

" Embedded unified diff (shown when diff display is enabled).
syn match diffRemoved "^ \=-.*" display
syn match diffAdded "^ \=+.*" display
syn match diffFile "^ \=diff --git .*" display
syn match diffOldFile "^ \=--- a\>.*" display
syn match diffNewFile "^ \=+++ b\>.*" display
syn match diffIndexLine "^ \=index \x\{7,}\.\.\x\{7,}.*" display
syn match diffLine "^ \=@@ .*" display

hi def link pickaxeHeader  Identifier
hi def link pickaxeHash    Comment
hi def link pickaxeHistory Constant
hi def link pickaxeEmail   NormalFloat

hi def link diffOldFile   diffFile
hi def link diffNewFile   diffFile
hi def link diffIndexLine PreProc
hi def link diffFile      Type
hi def link diffRemoved   Special
hi def link diffAdded     Identifier
hi def link diffLine      Statement

let b:current_syntax = 'pickaxe'
