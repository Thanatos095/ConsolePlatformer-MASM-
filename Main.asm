INCLUDE Irvine32.inc

Point STRUCT
	x BYTE 0
	y BYTE 0
Point ENDS


.data
	inputChar BYTE ?
	player Point <40, 27>
	dirX SBYTE 0
	clock DWORD 0
.code
	main PROC
		call DrawPlayer
		gameLoop:
			call Update
			jmp gameLoop 
			
		exit
	main ENDP

	Update PROC
		call HandleEvents
		call Gravity
		call Inertia
		ret
	Update ENDP

	Gravity PROC uses eax
		movzx eax, player.y
		cmp player.y, 27
		jl _
		ret
		_:
			call clearPlayer
			inc player.y
			cmp dirX, 0
			je Rest

			mov al,player.x 
			add al, dirX
			mov player.x, al

			Rest:
			call DrawPlayer
			mov eax, 40
			call delay
			ret
	Gravity ENDP

	Inertia PROC
		inc Clock     ; i have used a clock to basically check if it has been 10 cycles without any movement
		cmp Clock, 1500 ; if it has been 1500 cycles then i reset dirX
		jne Return
		mov dirX, 0
		Return:
			ret
	Inertia ENDP

	HandleEvents PROC
		call ReadKey
		jnz KeyEntered 
		ret	;if no key is entered it returns
		
		KeyEntered:
			mov inputChar,al

			_1:
				cmp inputChar,"w"	;if w
				jne _2
				call Jump

			_2:
				cmp inputChar,"a" ;else if a
				jne _3
				call moveLeft
	
			_3:
				cmp inputChar,"d" ; else if d
				jne _4
				call moveRight
		
			_4:
				ret			 ; else return
	HandleEvents ENDP

	Jump PROC uses ecx eax 
		mov ecx, 5
		_:
			call ClearPlayer
			dec player.y
			mov al,player.x 
			add al, dirX
			mov player.x, al
			call DrawPlayer
			mov eax,40
			call Delay
			loop _
		ret
	Jump ENDP

	moveLeft PROC
		mov clock, 0
		call clearPlayer
		mov dirX, -1
		dec player.x
		call DrawPlayer
		ret
	moveLeft ENDP
	
	moveRight PROC
		mov clock, 0
		call clearPlayer
		mov dirX, 1
		inc player.x
		call DrawPlayer
		ret
	moveRight ENDP
	

	DrawPlayer PROC
		mov dl, player.x
		mov dh, player.y
		mov al, 'X'
		call WriteCharToConsoleXY
		ret
	DrawPlayer ENDP


	ClearPlayer PROC
		mov dl, player.x
		mov dh, player.y
		mov al, ' '
		call WriteCharToConsoleXY
		ret
	CLearPlayer ENDP

	WriteCharToConsoleXY PROC ; Params{dl: X, dh: Y, al: 'char'} 
		call gotoXY
		call writeChar
		ret
	WriteCharToConsoleXY ENDP
END main
