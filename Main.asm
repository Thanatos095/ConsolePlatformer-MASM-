INCLUDE Irvine32.inc


Point STRUCT
	x BYTE 0
	y BYTE 0
Point ENDS

.data

ground BYTE "------------------------------------------------------------------------------------------------------------------------",0
strScore BYTE "Your score is: ",0
score BYTE 0
xVec BYTE 0
xPos BYTE 20
yPos BYTE 20
xCoinPos BYTE ?
yCoinPos BYTE ?
inputChar BYTE ?

.code
main PROC
	call Randomize
	call DrawGround
	call DrawPlayer
	call CreateRandomCoin
	call DrawCoin
	gameLoop:
		call ShowPlayerPos
		; getting points:
		mov bl,xPos
		cmp bl,xCoinPos
		jne notCollecting
		mov bl,yPos
		cmp bl,yCoinPos
		jge notCollecting
		; player is intersecting coin:
		inc score
		call CreateRandomCoin
		call DrawCoin
		notCollecting:

		mov eax,white (black * 16)
		call SetTextColor

		; draw score:
		mov dl,0
		mov dh,0
		call Gotoxy
		mov edx,OFFSET strScore
		call WriteString
		mov al,score
		call WriteInt

		; gravity logic:
		gravity:
		cmp yPos,27
		jg onGround
		; make player fall:
		call UpdatePlayer
		inc yPos
		call DrawPlayer
		mov eax,80
		call Delay
		jmp gravity
		onGround:

		; get user key input:
		call ReadChar
		mov inputChar,al

		; exit game if user types 'x':
		cmp inputChar,"x"
		je exitGame

		cmp inputChar,"w"
		je moveUp

		cmp inputChar,"s"
		je moveDown

		cmp inputChar,"a"
		je moveLeft

		cmp inputChar,"d"
		je moveRight

		moveUp:
		; allow player to jump:
		mov ecx,5
		jumpLoop:
			call UpdatePlayer
			dec yPos
			;CMP xVec,0
			;JG moveRightJump
			;CMP xVec,0
			;JL moveLeftJump
			rest:
			call DrawPlayer
			mov eax,70
			call Delay
		loop jumpLoop
		jmp gameLoop

		moveDown:
		call UpdatePlayer
		inc yPos
		call DrawPlayer
		jmp gameLoop

		moveLeft:
		mov xvec,-1
		call UpdatePlayer
		dec xPos
		call DrawPlayer
		jmp gameLoop

		moveRight:
		mov xvec,1
		call UpdatePlayer
		inc xPos
		call DrawPlayer
		jmp gameLoop

	

	jmp gameLoop

	moveRightJump:
		inc xPos
		JMP rest

	moveLeftJump:
	dec xPos
	JMP rest


	exitGame:
	exit
main ENDP

ShowPlayerPos PROC
	mov eax,white (black * 16)
	mov dl,30
	mov dh,0
	call Gotoxy
	movzx eax,xPos
	call writedec
	mov dl,40
	mov dh,0
	call Gotoxy
	movzx eax,yPos
	call writedec
ShowPlayerPos ENDP


DrawPlayer PROC
	; draw player at (xPos,yPos):
	mov dl,xPos
	mov dh,yPos
	call Gotoxy
	mov al,"X"
	call WriteChar
	ret
DrawPlayer ENDP

UpdatePlayer PROC
	mov dl,xPos
	mov dh,yPos
	call Gotoxy
	mov al," "
	call WriteChar
	ret
UpdatePlayer ENDP

DrawCoin PROC
	mov eax,yellow (yellow * 16)
	call SetTextColor
	mov dl,xCoinPos
	mov dh,yCoinPos
	call Gotoxy
	mov al,"X"
	call WriteChar
	ret
DrawCoin ENDP

DrawGround PROC uses edx eax
	mov dl,0
	mov dh,29
	call Gotoxy
	mov edx,OFFSET ground
	mov eax,green (green * 16)
	call SetTextColor
	call WriteString
	ret
DrawGround ENDP


CreateRandomCoin PROC
	mov eax,30
	call RandomRange
	mov xCoinPos,al
	mov eax,5
	call RandomRange
	add al, 23
	mov yCoinPos,al
	ret
CreateRandomCoin ENDP




END main