"|===========================================================================|
"| Begin                                                                     |
"|===========================================================================|
source utils.vim
edit input/short_comment.in

"|===========================================================================|
"| Reformat a comment using the command.                                     |
"|===========================================================================|
NextCase
Out 'Reformat a comment using a command'
let g:CommentableBlockStyle = ['/*', '*', '*/']
call append(line('$'), GetCase(1))
try
	execute line('$') . 'CommentableReformat'
catch
	Out 'Caught exception!'
	call Out(v:exception)
endtry

"|===========================================================================|
"| Save and conclude                                                         |
"|===========================================================================|
NextCase
Out '-- End of Test --'
saveas output/reformat_command.out
quitall!