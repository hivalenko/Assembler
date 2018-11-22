; ================================== ТЕХНИЧЕСКОЕ ЗАДАНИЕ ==================================
; Вариант 8
; Поместить в первую строку результата все символы из исходной строки, являющимися прописными буквами
; Поместить во вторую строку результата символы исходной строки до первого найденного в исходной строке символа '.', за которым следует прописная буква
; Битовая строка длиной 64 разряда устанавливает необходимость обработки соответствующего номеру бита в битовой строке
; номера байта из исходной строки, причем если бит установлен в 1, то соответствующий ему байт должен быть обработан при формировании первой строки результата.
; ==========================================================================================

.model small

stack segment para stack 'stack'
	 db 100h DUP(?)
stack ends

data segment para public 'data'

	string db  'qweRTY.84-s/62\k+-ls?93|-+t!S f764^sf+-k:s-+33jdskf83-=\ . 17lSj', '$'
	bitmask dq  0001001011101000101011110100010100010010111011001010010101001001b

	result1 db sizeof string DUP('$') ; ожидаемый результат: 146937333
	result2 db sizeof string DUP('$') ; ожидаемый результат: jsl71 . \=-38fksdj33+-s:k-

	message1 db 'Initial string:', '$'
	message2 db 'First result string:', '$'
	message3 db 'Second result string:', '$'

	minusFlag db 0	; показывает, был ли предыдущий символ минусом

	TRUE EQU 1
	FALSE EQU 0

data ends

code segment para public 'code'
assume ds:data, ss:stack, cs:code
.486

print macro arg:REQ
    mov ah, 09h
    lea dx, arg
    int 21h
	printLine
endm

printLine macro ; печатает символы 10 и 13 (перенос строки)
	mov ah, 02h
	mov dl, 10
	int 21h
	mov ah, 02h
	mov dl, 13
	int 21h
endm

; EBX - аргумент
printBinaryWord proc near
	push ax
	push dx
	push cx

	mov cx, 32 ; word

	PROC_LOOP:

		shl ebx, 1
		jc print_1	; if (CF != 1)

			mov dl, '0'
			jmp print_bit

		print_1:
		mov dl, '1'

		print_bit:
		mov ah, 02h
		int 21h

	loop PROC_LOOP

	pop cx
	pop dx
	pop ax

	ret

printBinaryWord endp

main:

	mov ax, data
	mov ds, ax

	print message1
	print string

	mov eax, dword ptr bitmask + 4
	mov ebx, eax
	call printBinaryWord

	xor si, si
	xor di, di
	mov dh, 31
	mov cx, sizeof string
	dec cx
	FIRST_LOOP:

		mov dl, string[si]

		cmp si, 32	; if (si == 32)
		jne num_check
			; когда дойдём до 32 символа, переходим на вторую половину маски
			mov eax, dword ptr bitmask
			mov ebx, eax
			call printBinaryWord
			printLine
			printLine

			mov dh, 31

		num_check:
		cmp dl, 'A'	; if(dl >= 'A' && dl <= 'Z')
		jl end_if1
		cmp dl, 'Z'
		jg end_if1

			push cx

			mov ebx, 1    ; ebx = 1 << dh
			mov cl, dh
			shl ebx, cl
			and ebx, eax  ; ebx = ebx & eax

			pop cx

			cmp ebx, 0
			je end_if1

			mov result1[di], dl	; result1 += dl
			inc di

		end_if1:

		inc si
		dec dh

	loop FIRST_LOOP

	print message2
	print result1
	printLine


	xor di, di
	mov cx, sizeof string
	mov si, cx
	sub si, 2
	SECOND_LOOP:

		mov dl, string[si]

		cmp dl, '.'	; if(dl == '.') minusFlag = true
		jne else_if2

			mov minusFlag, TRUE
			jmp end_if2

		else_if2:
		cmp minusFlag, TRUE	 ; if(minusFlag)
		jne end_if2
		mov minusFlag, FALSE ; minusFlag = false
		cmp dl, 'A'	; if(dl >= 'A' && dl <= 'Z')
		jl end_if2
		cmp dl, 'Z'
		jg end_if2
		jmp loop2_end

		end_if2:
		mov result2[di], dl

		inc di
		dec si

	loop SECOND_LOOP

	loop2_end:
	print message3
	print result2

	; конец программы
	xor eax, eax
	xor ebx, ebx
	xor cx, cx
	xor dx, dx
	xor si, si
	xor di, di

	mov ax, 4c00h	; функция выхода с кодом 0
	int	21h

code ends
end	main
