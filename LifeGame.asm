section .data				;---> CONSTANTS <---
	rowSize EQU 30
	n db 13, 10
	nLen: EQU $-n
	msjX db 'Enter X pos: '
	msjXlen EQU $-msjX
	msjY db 'Enter Y pos: '
	msjYlen EQU $-msjY
	msjNew db 13, 10, 'Enter new cell? y/n '
	newLen EQU $-msjNew
	msjRand db 13, 10, 'Type of game? 1.Manual 2.Random '
	randLen EQU $-msjRand
	mainMsj db 13, 10, 10, 10, '***CONWAY GAME OF LIFE***', 13, 10
	mainLen EQU $-mainMsj
	cntrlMsj db 13, 10, 'ENTER: Go to the next Generation', 13, 10, 'e: Exit'
	cntrlLen EQU $-cntrlMsj
	Alive db '0'
	Dead db ' '
	size dd rowSize*rowSize
	
section .bss				;---> VARIABLES <---
	Map resb rowSize*rowSize
	stringX resb 10
	stringY resb 10
	lengthX resb 1
	lengthY resb 1
	Y resd 1
	X resd 1
	opc resb 10
	typeOpc resb 10
	empty resb 1

section .text

%macro Input 2				;Macro -> Input (1.Variable 2.Length)
	pushad
	mov eax, 3
	mov ebx, 1
	mov ecx, %1
	mov edx, %2
	int 80h
	popad
%endmacro

%macro Output 3				;Macro -> Output (1.Variable 2.Length 3.Position)
	pushad
	mov eax, 4
	mov ebx, 1
	mov ecx, %1
	mov edx, %2
	add ecx, %3
	int 80h
	popad
%endmacro

%macro getLength 2			;MACRO -> get String length (1:String 2:Length)
	xor esi, esi
	xor eax, eax
	continue%1:
	mov al, [%1+esi]
	cmp al, ''
	jne increment%1
	je final%1
	
	increment%1:
	inc esi
	jmp continue%1
	
	final%1:
	dec esi
	mov [%2], esi
	xor esi, esi
	xor eax, eax
%endmacro

%macro toDigit 3			;MACRO -> String to number (1:Numer 2:Str 3:str.Length)
	mov esi, [%3]
	dec esi
	mov ecx, [%3]
	mov ebx, 1
	convert%1:
	xor eax, eax
	mov al, [%2+esi]
	sub al, 30h
	mul ebx
	add [%1], eax
	
	mov eax, ebx
	mov edx, 10
	mul edx
	mov ebx, eax
	dec esi
	LOOP convert%1
%endmacro

%macro clrString 2			;MACRO -> Clear String (1:String 2:str.Length)
	xor esi, esi
	xor eax, eax
	mov al, ''
	mov ecx, %2
	clr%1:
	mov [%1+esi], al
	inc esi
	LOOP clr%1
%endmacro


%macro checkCell 0			;MACRO -> Check cell and its neighbours
	pushad
	push esi
	xor eax, eax
	xor edx, edx
	jmp left%1
	
	increment%1:			;Increment neighbour counter
	inc edx
	ret
	
	left%1:					;Left neighbour
	mov al, [Map+esi-1]
	cmp al, [Alive]
	jne right%1
	call increment%1
	
	right%1:				;Right neighbour
	mov al, [Map+esi+1]
	cmp al, [Alive]
	jne up%1
	call increment%1

	up%1:					;Up neighbours
	push esi
	sub esi, rowSize+1
	mov ecx, 3
	upCycle%1:
	mov al, [Map+esi]
	cmp al, [Alive]
	jne continueUp
	call increment%1
	continueUp:
	inc esi
	LOOP upCycle%1
	pop esi
	
	down%1:					;Down neighbours
	push esi
	add esi, rowSize-1
	mov ecx, 3
	downCycle%1:
	mov al, [Map+esi]
	cmp al, [Alive]
	jne continueDown
	call increment%1
	continueDown:
	inc esi
	LOOP downCycle%1
	pop esi
		
	theCheck%1:				;Check if dead or alive
	xor eax, eax
	mov al, [Map+esi]
	cmp al, [Dead]
	je isDeath%1
	cmp al, [Alive]
	je isAlive%1
	
	isAlive%1:				;Alive cell
	cmp edx, 2
	jl kill%1
	cmp edx, 3
	ja kill%1
	jmp finishThis%1
	
	kill%1:					;Kill Alive cell
	mov al, [Dead]
	mov [Map+esi], al
	jmp finishThis%1
	
	
	isDeath%1:				;Dead cell
	cmp edx, 2
	jne check2%1
	check2%1:
	cmp edx, 3
	jne finishThis%1
	mov al, [Alive]
	mov [Map+esi], al
	
	finishThis%1:
	pop esi
	popad
%endmacro


drawMap:					;Draw all the map
	push esi
	mov ecx, 9
	spaces:					;Draw spaces
	Output n, nLen, 0
	LOOP spaces
	
	xor esi, esi
	xor ebx, ebx
	mov ecx, [size]
	mapCycle:				;Draw map
	cmp ebx, rowSize
	je newRow
	still:
	Output Dead, 1, 0
	Output Map, 1, esi
	inc ebx
	inc esi
	LOOP mapCycle
	pop esi
	ret

	newRow:					;Draw new Map row
	Output n, nLen, 0
	xor ebx, ebx
	jmp still
	
aleatory:					;Get aleatory number
rdtsc
cmp al, 180 
jae revive
mov eax, [Dead]
ret
revive:
mov eax, [Alive]
ret

;------> ***** M A I N ***** <------

global _start:
_start:

Output msjRand, randLen, 0	;Ask type of game
Input typeOpc, 10
mov al, [typeOpc]
cmp al, '1'
je ManualGame

xor esi, esi				;Initialize (random map)
mov eax, ' '
xor ebx, ebx
mov ecx, [size]
initializeRand:
	mov [Map+esi], eax
	inc esi
	call aleatory
LOOP initializeRand
jmp Begin

ManualGame:
xor esi, esi				;Initialize (Normal map)
mov eax, ' '
xor ebx, ebx
mov ecx, [size]
initialize:
	mov [Map+esi], eax
	inc esi
LOOP initialize

addNewCell:					;Question to add new Cell
Output msjNew, newLen, 0
Input opc, 10
mov al, [opc]
cmp al, 'n'
je Begin

clrString stringX, 10		;Clearing variables
clrString stringY, 10
xor eax, eax
mov [X], eax
mov [Y], eax

Output msjX, msjXlen, 0		;Procesing X
Input stringX, 10
getLength stringX, lengthX
toDigit X, stringX, lengthX

Output msjY, msjYlen, 0		;Procesing Y
Input stringY, 10
getLength stringY, lengthY
toDigit Y, stringY, lengthY

pushad						;Adding cell to Map
xor esi, esi
mov eax, rowSize
mov ebx, [Y]
mul ebx
add esi, eax
add esi, [X]
mov dl, [Alive]
mov [Map+esi], dl
popad

call drawMap
jmp addNewCell

Begin:
Output mainMsj, mainLen, 0
Output cntrlMsj, cntrlLen, 0
Input empty, 1

LIFEGAME:					;--->LIFE GAME<---
xor esi, esi
mov ecx, [size]
cycle:
	checkCell
	inc esi
	dec ecx
	cmp ecx, 0
jne cycle					;Next generation
	call drawMap
	Input empty, 1			
	push eax				;Check for exit
	mov al, [empty]
	cmp al, 'e'
	je exit
	pop eax
jmp LIFEGAME

exit:						;Exit
mov eax, 1				
int 80h
