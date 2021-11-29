INCLUDE Irvine32.inc

Point STRUCT
	x BYTE 0
	y BYTE 0
Point ENDS

Platform STRUCT
	pos Point <?, ?>	;starting pos
	_length BYTE 10		;The lenght of platform
	isInit BYTE 0		; This checks if platform is generated yet
Platform ENDS


.data
	numPlatformsMax = 8 ; There can only be <= 4 platforms at one time
	inputChar BYTE ?
	player Point <40, 27>
	coin Point<?,?>
	dirX SBYTE 0
	clock DWORD 0
	platformClock DWORD 0
	ground BYTE "----------------------------------------------------------------------------------------------------------------------",0
	isJumping BYTE 0
	jumpCount BYTE 0 ; Used to keep track of how many frames till jump triggered
	platforms Platform numPlatformsMax DUP(<>)
	numberOfPlatforms BYTE 0
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
		;call UpdatePlatforms  ;controls platform generation, draw, clear, removal and moving
		; i have commented it for now because its not working as needed. needs debugging.
		ret
	Update ENDP

	Gravity PROC uses eax ; Now this procedure will check if it is colliding with a platform and if the player is jumping. if either condition is true gravity wont affect player
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
				je break
				mov isJumping, 1
				je break

			_2:
				cmp inputChar,"a" ;else if a
				jne _3
				call moveLeft
				jmp break
	
			_3:
				cmp inputChar,"d" ; else if d
				jne break
				call moveRight
		
			break:
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
			cmp platforms[esi * TYPE Platform].isInit, 1 ; if the platform is not initialized then skip it
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

	ClearPlatforms PROC uses esi edx
		mov esi, 0
		_:
			cmp platforms[esi * TYPE Platform].isInit, 0
			jne checkNext
			
			mov dl, platforms[esi * TYPE Platform].pos.x
			mov dh, platforms[esi * TYPE Platform].pos.y
			mov al, ' '
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
	ClearPlatforms ENDP



	GeneratePlatform PROC uses esi eax
			movzx esi, numberOfPlatforms
			inc esi
			cmp esi, numPlatformsMax
			jnb break ; if number of platforms + 1 >= number of max platforms then break

			mov eax, 60
			call randomRange 
			mov platforms[esi * TYPE Platform].isInit, 1		
			mov platforms[esi * TYPE Platform].pos.x , al
			mov platforms[esi * TYPE Platform].pos.y, 1

			inc numberOfPlatforms
			Break:
				ret
	GeneratePlatform ENDP


	UpdatePlatforms PROC uses eax esi ebx
		call PlatformGenerator
		mov esi, 0
		_:
			mov ebx, esi
			cmp bl, numberOfPlatforms
			jge break

			mov al, platforms[esi * TYPE Platform].pos.y
			inc al
			cmp al, 28
			jl platformNotRemoved
			
			call RemovePlatform ; if the platform gets to the bottom of the platform remove it

			platformNotRemoved:
			inc platforms[esi * TYPE Platform].pos.y
			
			inc esi
		break:
			call ClearPlatforms
			call DrawPlatforms
		ret
	UpdatePlatforms ENDP


	RemovePlatform PROC uses eax ebx
		mov eax, esi

		_:
			cmp al, numberOfPlatforms
			jge break
			mov bl, platforms[edi * 4 + 4].pos.y 
			mov platforms[edi * 4].pos.y, bl

			mov bl, platforms[edi * 4 + 4].pos.x
			mov platforms[edi * 4].pos.x, bl

			mov bl, platforms[edi * 4 + 4]._length
			mov platforms[edi * 4]._length, bl

			mov bl, platforms[edi * 4 + 4].isInit
			mov platforms[edi * 4].isInit, bl
			inc al
			; since an arbitary index from the array is being removed, shifting back all indices by 1 
			; for(i = ind ; i < num ; i++) arr[i] = arr[i + 1];

		break:
			dec numberOfPlatforms
			ret
	RemovePlatform ENDP

	PlatformGenerator PROC
		inc PlatformClock
		cmp PlatformClock, 4000 ;for spawning a platform around every 4000 frames
		jb noReset
		mov PlatformClock, 0
		call GeneratePlatform		
		noReset:
			ret
	PlatformGenerator ENDP

END main
