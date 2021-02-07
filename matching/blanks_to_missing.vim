" the Julia CSV module really dislikes  blank spaces as NA markers, so this just replaces the blanks with "NA"
" in the tabfiles.
" use like: use like vim -e [file] < blanks_to_missing.vim

%s/ /NA/g

:write
:quit 

