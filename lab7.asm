; Вариант 18
; Ряд: 1 + x*ln(a) + (x*ln(a))^2 / 2! + ... + (x*ln(a))^n / n!
; Функция: a^x
; ==========================================================================================

.686
.model flat, stdcall
option casemap: none
include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\masm32.inc
include \masm32\include\msvcrt.inc
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\masm32.lib
includelib \masm32\lib\msvcrt.lib

TABLE_WIDTH  equ 20
COLUMN_COUNT equ 4
BUFFER_SIZE  equ TABLE_WIDTH

print macro args:REQ
	irp arg, <args>
		invoke WriteConsole, handleOut, addr arg, length arg, NULL, NULL
	endm
endm

printS macro arg:REQ
	invoke WriteConsole, handleOut, addr arg, sizeof arg, NULL, NULL
endm

floatToString macro arg:REQ
	call clearBuffer
	invoke FloatToStr, arg, offset buffer
endm

input macro arg:REQ
	invoke crt_scanf, addr format, addr arg
endm

padLeft macro arg:REQ
	invoke WriteConsole, handleOut, addr arg, sizeof arg, NULL, NULL
	rept TABLE_WIDTH - sizeof arg
		print space
	endm
endm

.data
	; Сообщения
	message1 db 'xStart: ', 0
	message2 db 'xEnd: ', 0
	message3 db 'deltaX: ', 0
	message4 db 'Precision: ', 0
	message5 db 'Alpha: ', 0

	; Заголовки таблицы
	header1 db 'Argument', 0
	header2 db 'Series sum', 0
	header3 db 'a^x', 0
	header4 db 'Element count', 0

	; Введённые значения
	currentX  dq ?
	finalX    dq ?
	deltaX 	  dq ?
	precision dq ?
	alpha	  dq ?

	; Строка таблицы
	function  dq ?
	seriesSum dq ?
	element   dq ?
	elemCount dq 0

	; Ввод-вывод
	handleIn  dd ?
	handleOut dd ?
	buffer	  db BUFFER_SIZE dup(0)
	format 	  db "%lf", 0

	; Псевдографика
	upperLeft      db 201, 0
	upperRight     db 187, 0
	upperT         db 203, 0
	lowerLeft      db 200, 0
	lowerRight 	   db 188, 0
	lowerT         db 202, 0
	leftT          db 204, 0
	rightT         db 185, 0
	cross      	   db 206, 0
	verticalLine   db 186, 0
	horizontalLine db TABLE_WIDTH dup(205), 0
	space		   db ' ', 0
	newline		   db 10, 13, 0

.code
; Вычисляет сумму ряда и кол-во элементов
getSeriesSum proc uses eax
	local count: dword
	local lnax: qword

	mov count, 0
	finit

	fld currentX	; x --> st(1)
	fld alpha		; a --> st(0)
	fyl2x 			; log2a*x
	fldln2			; \ ln2*log2a*x = lna*x
	fmul			; /
	fstp lnax		; сохраняем значение lna*x

	fldz				; сумма = 0
	fld1				; \ элемент = 1
	fstp element		; /

@loop:  fld element
		fadd
		inc count

		fld element		; \
		fld lnax		;  | Умножаем элемент на lna*x
		fmul			; /

		cmp count, 2	; Факториал растёт только после 2 элемента
		jl @f
		fidiv count		; Делим на n

@@:		fstp element
		push offset precision
		push offset element
		call compare
	ja @loop

	fstp seriesSum
	fild count
	fstp elemCount

	ret
getSeriesSum endp

; Вычисляет значение функции a^x
calcFunction proc
	local trunc:dword

	finit
	fld currentX	; x --> st(1)
	fld alpha		; a --> st(0)

	; a^x = 2^(log2a*x)
	fyl2x 		; log2a*x
	fist trunc	; сохраняем целую часть логарифма
	fild trunc	; кладём её в стек FPU
	fsub		; вычитаем из логарифма, получаем дробную часть
	f2xm1 		; 2^decimalPart(log2a*x) - 1
	fld1		; \ result++
	fadd		; /
	fild trunc	; кладём целую часть в FPU
    fxch		; swap(st0, st1)
    fscale		; result * 2^trunc(log2a*x) = 2^(log2a*x) = a^x

	fstp function		; result --> function

	ret
calcFunction endp

; Сравнивает два числа double
compare proc uses eax X:dword, Y:dword
	mov eax, Y
	fld qword ptr [eax]
	mov eax, X
	fld qword ptr [eax]
	fcompp	 	; сравнение двух чисел и удаление их из стека
	fstsw ax 	; сохраняем статусное слово в АХ
	sahf		; загружаем содержимое АН в регистр флагов
	ret 8
compare endp

; Очищает буфер
clearBuffer proc uses eax cx edi
	mov ecx, BUFFER_SIZE / 4
	lea edi, buffer
	xor eax, eax
	cld
@@: stosd
	loop @b
	ret
clearBuffer endp

drawHeader proc
	print upperLeft
	rept COLUMN_COUNT - 1
		print horizontalLine
		print upperT
	endm
	print <horizontalLine, upperRight, newline>

	irp header, <header1, header2, header3, header4>
		print verticalLine
		padLeft header
	endm
	print <verticalLine, newline>

	print leftT
	rept COLUMN_COUNT - 1
		print horizontalLine
		print cross
	endm
	print <horizontalLine, rightT, newline>

	ret
drawHeader endp

drawRow	proc
	irp value, <currentX, seriesSum, function, elemCount>
		print verticalLine
		floatToString value
		padLeft buffer
	endm
	print <verticalLine, newline>
	ret
drawRow endp

drawTable proc
	call drawHeader

@@: call getSeriesSum
	call calcFunction
	call drawRow
	fld currentX
	fld deltaX
	fadd
	fstp currentX
	push offset finalX
	push offset currentX
	call compare
	jna @b

	print lowerLeft
	rept COLUMN_COUNT - 1
		print horizontalLine
		print lowerT
	endm
	print <horizontalLine, lowerRight>
	ret
drawTable endp

Start:
	invoke GetStdHandle, STD_INPUT_HANDLE
	mov handleIn, eax
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov handleOut, eax

	printS message1
	input currentX
	printS message2
	input finalX
	printS message3
	input deltaX
	printS message4
	input precision
	printS message5
	input alpha

	print newline
	call drawTable

	xor eax, eax
	invoke ReadConsole, handleIn, addr buffer, 1, NULL, NULL
	invoke ExitProcess, 0
end	Start
