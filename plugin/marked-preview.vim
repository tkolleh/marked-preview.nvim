" marked-preview.nvim - Plugin commands
"
" This file sets up user commands for the marked-preview plugin

if exists('g:loaded_marked_preview')
  finish
endif
let g:loaded_marked_preview = 1

" Generate help tags if :helptags is supported
if exists(':helptags')
  silent! helptags ALL
endif

" Define user commands
command! -nargs=0 MarkedPreviewUpdate lua require('marked-preview').update()
command! -nargs=0 MarkedPreviewOpen lua require('marked-preview').open_marked()
command! -nargs=0 MarkedPreviewStart lua require('marked-preview').start_watching()
command! -nargs=0 MarkedPreviewStop lua require('marked-preview').stop_watching()