INCLUDE Irvine32.inc

Point STRUCT
	x BYTE 0
	y BYTE 0
Point ENDS

Platform STRUCT
	pos Point <?, ?>	;starting pos
	_length BYTE 7		;The lenght of platform
	isInit BYTE 0		; This checks if platform is generated yet
Platform ENDS


.data
	numPlatformsMax = 4 ; There can only be <= 4 platforms at one time
	inputChar BYTE ?
	player Point <40, 27>
	coin Point<?,?>
	dirX SBYTE 0
	clock DWORD 0
	ground BYTE "----------------------------------------------------------------------------------------------------------------------",0
	isJumping BYTE 0
	jumpCount BYTE 0 ; Used to keep track of how many frames till jump triggered
	platforms Platform numPlatformsMax DUP(<>)
.code
	main PROC
		;initialize stuff
		call Randomize
		call initializeground
		call DrawPlayer
		;call CreateRandomCoin
		;call DrawCoin
		


		gameLoop:
			call Update
			jmp gameLoop 
			
		exit
	main ENDP

	initializeground PROC 
		mov dl,0
		mov dh,28
		call Gotoxy
		mov edx,OFFSET ground
		mov eax,green (green * 16)
		call SetTextColor
		call WriteString
		mov eax,white (black * 16)
		call SetTextColor
	initializeground ENDP

	Update PROC
		call HandleEvents
		cmp isJumping, 0
		je _
		call Jump
		_:
			call Gravity
			call Inertia
		ret
	Update ENDP

	Gravity PROC uses eax
		movzx eax, player.y
		cmp isJumping, 0
		je CheckIfOnPlatform
		ret
		CheckIfOnPlatform:
			cmp player.y, 27
			jl _
			ret
		_:
			call clearPlayer
			inc player.y
			call SideCollision
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
				cmp isJumping, 1
				je _4
				mov isJumping, 1
				je _4

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

	Jump PROC uses eax
			call ClearPlayer
			dec player.y
			mov al,player.x 
			add al, dirX
			mov player.x, al
			call DrawPlayer
			call SideCollision
			mov eax,40
			call Delay
			inc jumpCount
			cmp jumpCount, 5   ; If it has been 5 cycles since ju,p triggered
			jl _			;if it hasnt then return	
			mov jumpCount, 0	; else reset count
			mov isJumping, 0	; Now player can jump again
			_:
				ret
	Jump ENDP

	moveLeft PROC
		call SideCollision
		mov clock, 0
		call clearPlayer
		mov dirX, -1
		dec player.x
		call DrawPlayer
		ret
	moveLeft ENDP
	
	moveRight PROC
		call SideCollision
		mov clock, 0
		call clearPlayer
		mov dirX, 1
		inc player.x
		call DrawPlayer
		ret
	moveRight ENDP
	

	DrawPlayer PROC
		mov eax,white (black * 16)
		call settextcolor
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

	SideCollision Proc
		cmp player.x,3
		jg checkpos
		call clearPlayer
		mov player.x,3

		checkpos:
		cmp player.x,115
		jl return
		call clearPlayer
		mov player.x,110

		return:
		ret
	SideCollision ENDP

	DrawCoin PROC
		mov eax,yellow (yellow * 16)
		call SetTextColor
		mov dl,coin.x
		mov dh,coin.y
		call Gotoxy
		mov al,"X"
		call WriteChar
		ret
	DrawCoin ENDP

	CreateRandomCoin PROC
		mov eax,30
		call RandomRange
		mov coin.x,al
		mov eax,5
		call RandomRange
		add al, 23
		mov coin.y,al
		ret
	CreateRandomCoin ENDP
	
	DrawPlatforms PROC uses esi edx
		mov esi, 0
		_:
			cmp platforms[esi * TYPE Platform].isInit, 0
			jne checkNext
			
			mov dl, platforms[esi * TYPE Platform].pos.x
			mov dh, platforms[esi * TYPE Platform].pos.y
			mov al, '-'
			movzx ecx, platforms[esi * TYPE Platform]._length
			_draw:
				inc dl
				call writeCharToConsoleXY
				Loop _draw

			checkNext:
				inc esi
				cmp esi, LENGTH platforms
				jne _
		Break:
			ret
	DrawPlatforms ENDP

	GeneratePlatform PROC uses esi eax
		mov esi, 0
		_:
			cmp platforms[esi * TYPE Platform].isInit, 0
			jne checkNext
			
			mov eax, 60
			call randomRange 
			mov platforms[esi * TYPE Platform].isInit, 1
			mov platforms[esi * TYPE Platform].pos.x , al
			mov platforms[esi * TYPE Platform].pos.y, 1

			checkNext:
				inc esi
				cmp esi, LENGTH platforms
				jne _
		Break:
			ret
	GeneratePlatform ENDP


	UpdatePlatforms PROC
		ret
	UpdatePlatforms ENDP

	CollisionWithPlatform PROC
		ret
	CollisionWithPlatform ENDP

END main