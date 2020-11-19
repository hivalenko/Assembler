; Вариант 30 (главный модуль)
; Преобразовать данные  представленные  в  шестнадцатеричном  виде (DWORD) в  восьмеричное число без знака в символьной форме.
; Число параметров 2.  Первый - исходное значение.  Второй - адрес,  начиная с которого размещается результат.
; ==========================================================================================

.model small

stack segment para stack 'stack'
	db 100h DUP(?)
stack ends

data segment para public 'data'

	input dd ?
	output db 12 DUP('$'), '$'

	bufferMax db 9
	bufferLen db ?
	buffer db 10 DUP('$')

	inputMsg db 'Input:  ', '$'
	resultMsg db 'Your result: ', '$'
	successMsg db 'Entered: ', '$'
	parseErrMsg db 'Incorrect number format', '$'
	sizeErrMsg db 'Input must be a oct', '$'

	newLine db 10, 13, '$'

	OUT_ROW equ 8
	OUT_COL equ 4

data ends

code segment para public 'code'
assume ds:data, ss:stack, cs:code
.486

	extrn hexToOct: far, inputHex: far, parseHex: far, printOutput: far

	print macro arg:REQ
		mov ah, 09h
		lea dx, arg
		int 21h
	endm

	main:
		mov ax, data
		mov ds, ax

		print inputMsg

		; ввод числа
		lea si, bufferMax
		push si
		call inputHex

		print newLine
		print successMsg
		print buffer

		; чтение числа из строки
		lea si, buffer
		call parseHex
		mov input, ebx

		; проверка на ошибку
		cmp ax, 0
		je noError
		cmp ax, 1
		je mainParseError

		; Некорректный размер
		print newLine
		print sizeErrMsg
		jmp mainEnd

		; Некорректный формат
		mainParseError:
		print newLine
		print parseErrMsg
		jmp mainEnd

		noError:
		; проверка на отрицательность
		cmp input, 0
		jge formResult
		not input
		inc input

		formResult:
		; формирование результата
		lea si, output
		push si
		push input
		call hexToOct

		print newLine
		print resultMsg

		; вывод результата
		push si
		push OUT_COL
		push OUT_ROW
		call printOutput

		; конец программы
		jmp mainEnd



		mainEnd:
		xor ebx, ebx
		xor dx, dx
		xor si, si

		mov ax, 4c00h	; функция выхода с кодом 0
		int	21h

code ends
end main
