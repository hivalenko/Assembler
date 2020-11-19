; Вариант 30
; Первая процедура : ввод исходных данных с клавиатуры.
; Вторая процедура : вывод данных на экран дисплея.
; Обязательные параметры - номер строки и столбца начальной позиции вывода.
; ==========================================================================================

code segment para public 'code'
.486

	extrn getsize: far
	public inputHex, printOutput, parseHex

	; Считывает шестнадцатеричное число в символьной форме в EBX
	; Параметры: SI - адрес исходной строки
	parseHex proc near

		push cx
		push si

		xor ebx, ebx

		cld
		mov cl, [si - 1] ; длина строки
		cmp cl, 8
		je parseHexLoop
		mov ax, 2
		jmp parseHexEnd

		parseHexLoop:
			xor eax, eax
			lodsb [si] ; Al = input[i]

			; получаем значение шестнадцатеричного знака
			cmp ax, '0'
			jl hexIsLetter
			cmp ax, '9'
			jg hexIsLetter

				sub ax, '0'
				jmp hexDigitValue

			hexIsLetter:
			and al, '_'		 ; Приведение к верхнему регистру

			; Если это не буква, кидаем "исключение"
			cmp ax, 'A'
			jl exception
			cmp ax, 'F'
			jg exception
			sub ax, '7'	; dx = dx - 'A' + 10
			jmp hexDigitValue

			exception:
			mov ax, 1	; return code = 1 (ERROR)
			jmp parseHexEnd

			hexDigitValue:
			push cx
			dec cx
			shl cx, 2	; pow = 4 * (cx - 1)
			shl eax, cl	; eax = digit * 16^(cx - 1)
			pop cx

			; добавляем к сумме
			add ebx, eax

		loop parseHexLoop

		xor ax, ax ; return code = 0 (OK)

		parseHexEnd:
		pop si
		pop cx

		ret

	parseHex endp

	; Ввод шестнадцатеричного числа
	; Параметр: адрес буфера
	inputHex proc far

		push bp
		mov bp,sp

		push dx
		mov ah, 0Ah
		mov dx, [bp+6]      ; адрес строки результата
		int 21h

		pop dx
		pop bp
		ret 4

	inputHex endp

	; Печатает строку в указанном столбце и строке
	; Параметры: строка, столбец, адрес строки для вывода
	printOutput proc far

		push bp
		mov bp,sp

		push dx
		push ax

		mov dh, [bp+6] ; строка вывода
		mov ah, 02h
		targetRow:
		mov dl, 10
		int 21h
		mov dl, 13
		int 21h
		dec dh
		cmp dh, 0
		jne targetRow

		mov dh, [bp+8] ; столбец вывода
		targetCol:
		mov dl, ' '
		int 21h
		dec dh
		cmp dh, 0
		jne targetCol

		mov ah, 09h
		mov dx, [bp+10]
		int 21h

		pop ax
		pop dx
		;pop di

		pop bp
		ret

	printOutput endp

code ends
end
