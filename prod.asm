INCLUDE Irvine32.inc
INCLUDE MACROS.inc
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
	numPlatformsMax = 15 ; There can only be <= 6 platforms at one time
	inputChar BYTE ?
	player Point <40, 27>
	enemy Point<50,15>
	enemydir Point<0,0>
	coin Point<?,?>
	dirX SBYTE 0
	InertiaClock DWORD 0
	platformGenerationClock DWORD 0
	platformMovementClock DWORD 0
	enemyClock DWORD 0
	JumpClock DWORD 5000
	ground BYTE "----------------------------------------------------------------------------------------------------------------------",0
	isJumping BYTE 0
	jumpCount BYTE 0 ; Used to keep track of how many frames till jump triggered
	platforms Platform numPlatformsMax DUP(<>)
	numberOfPlatforms BYTE 0
	score BYTE 0
	gameOverbool BYTE 0
.code
	main PROC
										;initialize stuff
		call Randomize
		mov dh,12
		mov dl,45
		call gotoxy
		mwrite"PRESS SPACE TO PLAY"
		menu:
			call readkey
			cmp al," "	
			je init
		jmp menu

		init:
			call clrscr
			call initializeground
			call DrawPlayer
			call CreateRandomCoin
		gameLoop:
			cmp gameoverbool,1
			je endscr
			call Update
			jmp gameLoop
			
		endscr:
			call clrscr
			mwrite"GAME OVER!"
			call crlf
			mwrite"SCORE:"
			call crlf
			mov al,score
			call writeint
		exit
	main ENDP
	
	DrawCoin PROC
	mov eax,yellow (black * 16)
	call SetTextColor
	mov dl,coin.x
	mov dh,coin.y
	mov al,"O"
	call WriteChartoconsolexy
	mov eax,white (black * 16)
	call SetTextColor
	ret
	DrawCoin ENDP

	CoinCollision Proc uses eax
	mov al,coin.y
	cmp al,player.y
	jne return
	mov al,coin.x
	cmp al,player.x
	jne return
	collision:
		call createRandomCoin
		inc score
	return:
	ret
	CoinCollision ENDP

	CreateRandomCoin PROC
		mov eax,100
		call RandomRange
		mov coin.x,al
		mov eax,25
		call randomrange
		mov coin.y,al
		ret
	CreateRandomCoin ENDP

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
		call DrawCoin
		call moveenemy
		cmp isJumping, 0
		je _
		call Jump
		_:
			call Gravity
			call Inertia
		call PlatformGenerator
		call PlatformMovement
		call UpdateClocks
		ret
	Update ENDP

	Gravity PROC uses eax ; Now this procedure will check if it is colliding with a platform and if the player is jumping. if either condition is true gravity wont affect player
		movzx eax, player.y
		cmp isJumping, 0
		je CheckIfOnPlatform
		ret
		CheckIfOnPlatform:
			mov esi,0
			movzx ecx,numberOfPlatforms
			cmp player.y, 26
			jg _ng
			check:


			mov al,platforms[esi * TYPE platform].pos.y
			;sub al,1
			cmp al,player.y
			je checkxgreater
			jmp next
			checkxgreater:
			mov al,platforms[esi * TYPE platform].pos.x
			add al,9
			cmp al,player.x
			jg checkxLesser
			jmp next
			checkxLesser:
			mov al,platforms[esi * TYPE platform].pos.x
			dec al
			cmp al,player.x
			jl _ng


			next:
			inc esi
			LOOP check
			jmp _
			_ng:  ;no gravity

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
			mov eax, 20
			call delay
			ret
	Gravity ENDP

	

	Inertia PROC
		cmp InertiaClock, 1500 ; if it has been 1500 cycles then i reset dirX
		jne Return
		mov dirX, 0
		Return:
			ret
	Inertia ENDP

	HandleEvents PROC
		call CoinCollision
		call enemyCollision
		call ReadKey
		jnz KeyEntered 
		ret	;if no key is entered it returns
		
		KeyEntered:
			mov inputChar,al

			_1:
				cmp inputChar,"w"	;if w
				jne _2
				cmp isJumping, 1	; cant jump if already jumping
				je break

				cmp jumpClock, 5000		; can jump every 5000 cycles
				jl break
				mov jumpClock, 0
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
		cmp jumpCount, 10   ; If it has been 5 cycles since ju,p triggered
		jl _			   ;if it hasnt then return	
		mov jumpCount, 0	; else reset count
		mov isJumping, 0	; Now player can jump again
		_:
			ret
	Jump ENDP

	moveLeft PROC
		call SideCollision
		mov InertiaClock, 0
		call clearPlayer
		mov dirX, -1
		dec player.x
		call DrawPlayer
		ret
	moveLeft ENDP
	
	moveRight PROC
		call SideCollision
		mov InertiaClock, 0
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
	
	moveEnemy PROC uses eax
	call clearenemy

	cmp enemyclock,500
	jl rest
	cmp enemy.y,25
	jg resetYdown
	cmp enemy.y,2
	jl resetYUp
	
	jmp newEnemyDirection
	resetYdown:
		call clearenemy
		mov enemy.y,24
	resetYup:
		call clearenemy


	newEnemyDirection:
		mov enemyclock,0
		mov eax,3
		call randomrange
		dec al
		mov enemydir.x,al
		mov eax,3
		call randomrange
		dec al
		mov enemydir.y,al
	enemymove:
		mov al,enemydir.x
		add enemy.x,al
		mov al,enemydir.y
		add enemy.y,al
	rest:
		call drawenemy
	ret
	moveEnemy endp

	DrawEnemy PROC
		mov eax,black (red * 16)
		call settextcolor
		mov dl, enemy.x
		mov dh, enemy.y
		mov al, 'X'
		call WriteCharToConsoleXY
		mov eax,white (black * 16)
		call settextcolor
		ret
	DrawEnemy ENDP

	EnemyCollision PROC uses eax
	mov al,enemy.x
	cmp player.x,al
	jne return
	mov al,enemy.y
	cmp player.y,al
	je gameover
	jmp return

	gameover:
	mov gameoverbool,1
	return:
	ret
	EnemyCollision ENDP

	ClearEnemy PROC
		mov dl, enemy.x
		mov dh, enemy.y
		mov al, ' '
		call WriteCharToConsoleXY
		ret
	CLearEnemy ENDP
	WriteCharToConsoleXY PROC ; Params{dl: X, dh: Y, al: 'char'} 
		call gotoXY
		call writeChar
		ret
	WriteCharToConsoleXY ENDP

	SideCollision Proc
		cmp player.x,1
		jg checkpos
		call clearPlayer
		mov player.x,1

		checkpos:
		cmp player.x,115
		jl return
		call clearPlayer
		mov player.x,115

		checkYpos:
		cmp player.y,1
		jg return
		call clearPlayer
		mov player.y,1

		return:
		ret
	SideCollision ENDP

	PlatformCollision Proc


	PlatformCollision ENDP
	

	COMMENT!{This procedure accepts x pos in al and puts a platform there if no of platforms < max}!
	GeneratePlatform PROC
		
		movzx esi, numberOfPlatforms

		mov platforms[esi * TYPE Platform].isInit, 1
		mov platforms[esi * TYPE Platform].pos.x, al
		mov platforms[esi * TYPE Platform].pos.y, 0
		call DrawPlatform
		ret
	GeneratePlatform ENDP

	COMMENT!{This procedure accepts an index between [0, number of platforms] in esi and draws the platform corresponding to that index}!
	DrawPlatform PROC uses ebx edx
		
		mov bl, platforms[esi * TYPE Platform].pos.x
		add bl, platforms[esi * TYPE Platform]._length
		mov dl, platforms[esi * TYPE Platform].pos.x
		mov dh, platforms[esi * TYPE Platform].pos.y
		mov al, '_'
		
		

		_:
			cmp dl, bl
			jnl end_
			
			
			
			
			
			call writeCharToConsoleXY

			inc dl
			jmp _

		end_:


		ret
	DrawPlatform ENDP

	COMMENT!{This procedure draws all platforms}!
	DrawAllPlatforms PROC
		pushad
		mov esi, 0
		movzx edi, numberOfPlatforms
		draw:
			cmp esi, edi
			jnl end_drawplatforms
			
			cmp platforms[esi * TYPE Platform].isInit, 0
			je cont

			call DrawPlatform

			cont:
			inc esi
			jmp draw

		end_drawplatforms:
		popad
		ret
	DrawAllPlatforms ENDP

	COMMENT!{accepts an index between [0, number of platforms] in esi and erases the platform corresponding to that index}!
	ClearPlatform PROC uses edx ebx
		
		mov bl, platforms[esi * TYPE Platform].pos.x
		add bl, platforms[esi * TYPE Platform]._length
		mov dl, platforms[esi * TYPE Platform].pos.x
		mov dh, platforms[esi * TYPE Platform].pos.y

		mov al, ' '
		_:
			cmp dl, bl
			jnl end_
			
			call writeCharToConsoleXY

			inc dl
			jmp _

		end_:
		ret
	ClearPlatform ENDP

	COMMENT!{This procedure clears all platforms.}!
	ClearAllPlatforms PROC uses esi ebx
		mov esi, 0
		movzx ebx, numberOfPlatforms
		_:
			cmp esi, ebx
			jnl end_

			call ClearPlatform

			inc esi
			jmp _
		end_:
		ret
	ClearAllPlatforms ENDP


	COMMENT!{accepts an index between [0, number of platforms] and removes it from array and moves back all elements after it one index back}!
	RemovePlatform PROC uses eax esi ebx

		call ClearPlatform

		movzx eax, numberOfPlatforms
		dec eax

		moveBack:
			cmp esi, eax
			jnl end_moveBack
			mov ebx, platforms[esi * TYPE Platform + TYPE Platform]
			mov platforms[esi * TYPE Platform], ebx
			inc esi
			jmp moveBack

		end_moveBack:
		ret
	RemovePlatform ENDP


	PlatformGenerator PROC uses eax
		movzx eax, numberOfPlatforms
		cmp platformGenerationClock, 3000  ; can generate a platform every 4000 iterations
		jl break

		cmp numberOfPlatforms, numPlatformsmax
		jnl break

		mov platformGenerationClock, 0
		mov eax, 100
		call RandomRange
		call GeneratePlatform
		inc numberOfPlatforms

		break:

		ret
	PlatformGenerator ENDP

	PlatformMovement PROC uses ebx esi eax
		cmp platformMovementClock, 1500  ; Move platforms once every 4000 cycles
		jl cont
		mov platformMovementClock, 0
		mov esi, 0
		movzx ebx, numberOfPlatforms
		call ClearAllPlatforms
		_:
			cmp esi,  ebx
			jnl end_
			inc platforms[esi * TYPE Platform].pos.y
			cmp platforms[esi * TYPE Platform].pos.y, 27
			jl _1

			call RemovePlatform
			dec numberOfPlatforms
			movzx eax, numberOfPlatforms
			_1:
			
			inc esi
			jmp _
		end_:
		call DrawAllPlatforms
		cont:
		ret
	PlatformMovement ENDP

	UpdateClocks PROC
		inc InertiaClock
		inc platformGenerationClock 
		inc platformMovementClock
		inc JumpClock
		inc enemyclock
		ret
	UpdateClocks ENDP

	drawscore proc uses eax
	movzx eax,score
	mov dl,0
	mov dh,0
	call gotoxy
	call writeint
	ret
	drawscore endp

END main
