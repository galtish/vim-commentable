StartTest reformat_indented_width reformat_indented_comment

"|===========================================================================|
"| Reformat the comment from each case and check the width applies           |
"|===========================================================================|
function s:RunCase(case, setting)
	NextTest
	Say 'Comment case ' . a:case
	NormalStyle
	let g:CommentableBlockWidth = 50
	let g:CommentableSubWidth = 60
	if a:setting ==# 1
		let g:CommentableBlockWidth = 80
	elseif a:setting ==# 2
		let g:CommentableSubWidth = 20
	endif

	Say ('Setting ' . a:setting .
	 \   ', block width ' . g:CommentableBlockWidth .
	 \   ', sub width ' . g:CommentableSubWidth)
	UseCase a:case
	Assert (b:case_lastline - 1) . 'CommentableReformat'
endfunction

for s:i in range(1, 4)
	for s:j in range(3)
		call <SID>RunCase(s:i, s:j)
	endfor
endfor

EndTest
