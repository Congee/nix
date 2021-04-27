" https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=475266
" third version
" depending on debchangelog.vim
if exists("g:mail_fold_enable")
  setlocal foldmethod=expr
  " disable folding if there is no From header (presumably only one
  " mail message in the file)
  setlocal foldexpr=getline(1)=~#'^From\ '?GetMboxFold(v:lnum):'0'
  setlocal foldtext=GetMboxFoldText()
endif

" {{{1 folding
echo "mail"

function! s:getAuthor(zonestart, zoneend) " return author name if present,
	                                  " otherwise just email address
  let linepos = a:zonestart
  while linepos <= a:zoneend
    let line = getline(linepos)
    if line =~? '^From:\s'
      if line =~? '^From:\s\+[^<>]*\s\+<'
        return substitute(line, '^[^:]*:\s\+["]\?\([^<>]*[^<>"]\)["]\?\s\+<.*', '\1', '')
      else
	return substitute(line, '^[^:]*:\s\+\(.*\)', '\1', '')
      endif
    endif
    let linepos += 1
  endwhile
  return '[unknown author]'
endfunction

function! s:getSubject(zonestart, zoneend)
  let linepos = a:zonestart
  while linepos <= a:zoneend
    let line = getline(linepos)
    if line =~? '^Subject:\s'
      return substitute(line, '^[^:]*:\s\+\(.*\)', '\1', '')
    endif
    let linepos += 1
  endwhile
  return '[no subject]'
endfunction

function! GetMboxFoldText()
  if v:folddashes == '-' " whole mail msg folded:
	                 " show number of lines as well as author & subject
    let text = substitute(foldtext(), '^\([-+0-9 ]\+lines: \).*', '\1', '') . s:getAuthor(v:foldstart, v:foldend)
    while strlen(text) < 36
      let text = text . ' '
    endwhile
    if strlen(text) > 36
      let text = text[0 : 34] . '>'
    endif
  else " only headers folded, use full available space to show author & subject
    let text = '+--- ' . s:getAuthor(v:foldstart, v:foldend)
  endif

  return text . ' - ' . s:getSubject(v:foldstart, v:foldend) . ' '
endfunction

function! GetMboxFold(lnum)
  let line = getline(a:lnum)
  if line =~# '^From '
    return '>1' " beginning of a message
  endif
  if line =~ '^[-a-zA-Z0-9]\+:'
    if a:lnum > 1 && getline(a:lnum - 1) =~# '^From '
      return '>2' " beginning of header block
    else
      return '='
    endif
  endif
  if a:lnum > 1 && line =~ '^$'
    return '<2'
  endif
  return '='
endfunction

silent! foldopen!   " unfold the entry the cursor is on (usually the first one)

" }}}
