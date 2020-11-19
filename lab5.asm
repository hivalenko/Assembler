; Вариант 10
; Разрядность слова некоторого гипотетического процессора - 27 бита.
; Слова могут  принимать  положительные  или  отрицательные  значения.  Отрицательные значения хранятся в дополнительном коде.
; Объект моделирования:  массив N-разрядных слов из ITEM_COUNT элементов. Элементы располагаются в памяти реальной машины без промежутков.
; Макроопределения:
; 1) Чтение элемента из моделируемого массива по его порядковому номеру;
; 2) Запись элемента в массив на указанное место;
; 3) Циклический сдвиг элемента вправо;
; Для  всех  вычислений  нужно  использовать исходные, а не результирующие значения элементов.
; Вывод на экран  исходного и результирующего массивов  осуществить в виде
; двух панелей (как в Norton Commander'е). Исходный массив размещается на левой
; панели, результирующий - на правой.
; ==========================================================================================

.model small

stack segment para stack 'stack'
	 db 100h DUP(?)
stack ends

data segment para public 'data'

	WORD_SIZE EQU 17
	ITEM_COUNT EQU 12
	WORD_MASK EQU 11111111111111111000000000000000b
	LOW_MASK EQU 00000000000000001000000000000000b
	HIGH_MASK EQU 10000000000000000000000000000000b

	array dd 11100101001110001111111000110010b, 10101101010111001101000110110111b,
			 00011101010000001001100111100011b, 01011000110101010001000101100101b,
			 11000011011011011101110101010100b, 10101111101010110100a111010110011b,
			 01010011110100101110001110110000b, 11010010110101000011110100000100b,
			 11011101101100001001100100001001b, 10011000101101011000011110101101b,
			 10010101110110111011010010111010b

	;array dd 11111111111111111000000000000000b, 00111111111111111110000000000000b,
	;		  00001111111111111111100000000000b, 00000011111111111111111000000000b,
	;		  0000000011111111111111111000000b, 00000000000000000111111111111111b,
	;		 11000000000000000001111111111111b, 11110000000000000000011111111111b,
	;		  1111111111100000000000000000111b, 1111111111111100000000000000000b,
	;		  11111111110000000000000000000000b

	newline db 10, 13, '$'
	zero db '0', '$'
	one db '1', '$'

data ends

code segment para public 'code'
assume ds:data, ss:stack, cs:code
.486

; 1) Чтение элемента из моделируемого массива по его порядковому номеру в ЕВХ
; Аргументы:
; 	SI = индекс
; Используются:
;	ЕАХ = временное хранение второй части элемента
; 	CL = счётчик для сдвига
getElement macro array:=<array>
local endRead
	push si
	push cx

	; получаем индекс элемента в битах
	imul si, WORD_SIZE
	; получаем бит, с которого в этом двойном слове начинается нужный элемент (остаток от деления на 32)
	mov cx, si
	and cx, 31
	; получаем двойное слово, где начинается элемент
	sub si, cx	; биты
	shr si, 3	; байты

	; Первая часть нашего элемента
	mov ebx, array[si]
	shl ebx, cl			; сдвигаем на оставшиеся биты
	and ebx, WORD_MASK	; срезаем лишние 10 битов справа

	; Проверяем, остались ли биты нашего элемента в следующем слове
	; Если элемент начинается с бита < 16, то он целиком умещается в одно слово
	cmp cx, 16
	jl endRead
	push eax

		mov eax, array[si+4]
		xchg si, cx
		mov cx, 32
		sub cx, si
		shr eax, cl

	or ebx, eax
	and ebx, WORD_MASK

	pop eax
	endRead:
	pop cx
	pop si
endm

; 2) Запись элемента в массив на указанное место
; Аргументы:
;	EBX = элемент для записи
;	DI = индекс
; Используются:
;	EAX = маска
;	CX = счётчик сдвига
;	DX = промежуточные данные
setElement macro array:=<array>
local endWrite
	push di
	push cx
	push dx
	push eax

	and ebx, WORD_MASK

	; получаем индекс элемента в битах
	imul di, WORD_SIZE
	; получаем бит, с которого в этом двойном слове начинается нужный элемент (остаток от деления на 32)
	mov cx, di
	and cx, 31
	; получаем двойное слово, где начинается элемент
	sub di, cx	; биты
	shr di, 3	; байты

	; Первая часть нашего элемента
	; С помощью маски обнуляем существующий элемент в массиве
	mov eax, WORD_MASK
	shr eax, cl
	not eax
	and eax, array[di]

	; Применяем логическое ИЛИ к маске и аргументу
	push ebx
	shr ebx, cl
	or eax, ebx
	pop ebx

	mov array[di], eax

	; Проверяем, остались ли биты нашего элемента в следующем слове
	; Если элемент начинается с бита < 11, то он целиком умещается в одно слово
	cmp cx, 16
	jl endWrite

		; 32 - СХ = количество бит элемента, уместившееся в предыдущем слове
		mov dx, 32
		sub dx, cx
		xchg cx, dx

		; С помощью маски обнуляем существующий элемент в массиве
		mov eax, WORD_MASK
		shl eax, cl
		not eax
		and eax, array[di+4]

		; Применяем логическое ИЛИ к маске и аргументу
		push ebx
		shl ebx, cl
		or eax, ebx
		pop ebx

		mov array[di+4], eax

	endWrite:
	pop eax
	pop dx
	pop cx
	pop di
endm

; 3) Выполняет циклический сдвиг влево
; Аргументы:
;	SI = индекс
; Возвращает:
;	EDX = новый элемент
; Используются:
;	EBX = элемент
;	CX = счётчик цикла
makeoffsetd macro array:=<array>
local COUNT_LOOP, ONE_LAST, endd
	push ebx
	push cx
	push eax

	xor edx, edx

	getElement array
	mov cx, 2

	COUNT_LOOP:
		mov eax, ebx
		and eax, LOW_MASK
		cmp eax, 1
		jg ONE_LAST
		mov eax, ebx
		ror eax, 1
		and eax, WORD_MASK
		jmp endd
		ONE_LAST:
		mov eax, ebx
		ror eax, 1
		and eax, WORD_MASK
		or eax, HIGH_MASK
		endd:
		mov ebx, eax
	loop COUNT_LOOP
	mov edx, ebx
	pop eax
	pop cx
	pop ebx
endm

makeResultElement proc
	push edx

	makeoffsetd
	mov ebx, edx
	pop edx

	ret
makeResultElement endp

; Формирует массив результата
; Используются:
;	СХ = счётчик
;	DX = количество единиц
; 	EBX = результат
makeResultArray proc
	push si
	push di
	push cx
	push ebx

	mov cx, ITEM_COUNT
	xor si, si
	xor di, di
	RESULT_ARRAY_LOOP:
		call makeResultElement

		setElement

		inc si
		inc di
	loop RESULT_ARRAY_LOOP

	pop ebx
	pop cx
	pop di
	pop si
	ret
makeResultArray endp

; ====================================================================

; Печатает строку
print macro arg:REQ
	mov ah, 09h
	lea dx, arg
	int 21h
endm

; Заполняет экран
fillScreen proc near
	push    cx
	push    bx
	push    ax
	push    dx

	; Получить текущий видеорежим
	mov     ah, 0Fh
	int     10h

	; Устанавливаем позицию курсора
	mov     ah, 02h
	xor     dx, dx		; строка 0, столбец 0
	int     10h

	; Заполняем всё пробелами
	mov     cx, 2000
	mov     ah, 09h
	mov     al, ' '
	mov     bl, 13h		; цвет
	int     10h

	pop     dx
	pop     ax
	pop     bx
	pop     cx
	ret
fillScreen endp

; Рисует рамку с заданными координатами (от 1,1)
; Аргументы:
;	BH, BL - левый верхний угол (строка, столбец)
;	DH, DL - правый нижний угол
drawFrame proc near
	ul      = word ptr -2
	lr      = word ptr -4
	ul_c    = byte ptr -2
	ul_r    = byte ptr -1
	lr_c    = byte ptr -4
	lr_r    = byte ptr -3

	width_  = word ptr -6
	width_l = byte ptr -6

	push    bp
	mov     bp,sp
	sub     sp,6

	push    ax
	push    bx
	push    cx
	push    dx

	sub     bx,101h ;(0,0)
	sub     dx,101h
	mov     [bp+ul],bx
	mov     [bp+lr],dx

	; Получить текущий видеорежим
	mov     ah, 0Fh
	int     10h

	; Устанавливаем позицию курсора
	mov     dx,[bp+ul]
	mov     ah,02h
	int     10h

	; Вывод символа
	mov     ah,09h
	mov     bl, 17h
	mov     cx,1
	mov     al,0C9h ;г
	int     10h

	; Устанавливаем позицию курсора
	mov     dx,[bp+ul]
	inc     dx
	mov     ah,02h
	int     10h

	xor     ch,ch
	mov     cl,[bp+lr_c]
	sub     cl,[bp+ul_c]    ;Ширина рамки
	mov     [bp+width_],cx
	dec     [bp+width_l]
	sub     cl,2

	; Вывод символа
	mov     ah,09h
	mov     bl, 17h
	mov     al,205  ;=
	int     10h

	; Устанавливаем позицию курсора
	mov     dx,[bp+ul]
	add     dl,[bp+width_l]
	mov     ah,02h
	int     10h

	; Вывод символа
	mov     ah,09h
	mov     bl, 17h
	mov     cx,1
	mov     al,0BBh ;¬
	int     10h

	mov     cl,[bp+lr_r]
	sub     cl,[bp+ul_r]    ;Высота рамки
	sub     cl,2
	inc     [bp+ul_r]       ;Следующий ряд
	mov     al,186  ;¦
	mov     bl, 17h

	DRAW_FRAME_LOOP:
		; Устанавливаем позицию курсора
		push    cx
		mov     dx,[bp+ul]
		mov     ah,2h
		int     10h

		; Вывод символа
		mov     ah,9h
		mov     cx,1
		int     10h

		mov     ah,2h
		add     dl,[bp+width_l]
		int     10h

		; Вывод символа
		mov     ah,9h
		int     10h

		pop     cx
		inc     [bp+ul_r]
	loop    DRAW_FRAME_LOOP

	; Устанавливаем позицию курсора
	mov     dx,[bp+ul]
	mov     ah,02h
	int     10h

	; Вывод символа
	mov     ah,09h
	mov     bl, 17h
	mov     cx,1
	mov     al,200  ;L
	int     10h

	; Устанавливаем позицию курсора
	inc     dx
	mov     ah,02h
	int     10h

	; Вывод символа
	mov     cx,[bp+width_]
	dec     cl
	mov     ah,09h
	mov     bl, 17h
	mov     al,205  ;=
	int     10h

	; Устанавливаем позицию курсора
	add     dl,[bp+width_l]
	dec     dl
	mov     ah,02h
	int     10h

	; Вывод символа
	mov     ah,09h
	mov     bl, 17h
	mov     cx,1
	mov     al,188  ;-
	int     10h

	pop     dx
	pop     cx
	pop     bx
	pop     ax
	add     sp,6
	pop     bp
	ret
drawFrame ENDP

; Выводит массивы
; Аргументы:
;	DL = колонка
printArray macro array:=<array>
local PRINT_ARRAY_LOOP
	pusha

	; Получить текущий видеорежим
	mov ah,0Fh
	int 10h

	xor si, si	 ; индекс
	mov dh, 02   ; 2-я строка
	mov cx, ITEM_COUNT
	mov di, 0229h
	PRINT_ARRAY_LOOP:

		getElement array
		; Вывод строки
		call printBinaryWord

		inc dh
		inc si

	loop PRINT_ARRAY_LOOP

	popa
endm

; Печатает первые 17 бита EBX
; Аргументы:
;	ЕВХ = слово для вывода
printBinaryWord proc near uses ax cx dx bp ebx
	mov ax, 1300h
	mov cx, WORD_SIZE
	PRINT_LOOP:
		shl ebx, 1
		jc print_1
			lea bp, zero
			jmp print_bit
		print_1:
			lea bp, one
		print_bit:
		push ebx
		push cx
		xor ebx, ebx

		mov cx, 1
		mov bl, 13h			; Цвет
		int 10h

		pop cx
		pop ebx
		inc dl
	loop PRINT_LOOP

	ret
printBinaryWord endp

main:
	mov ax, data
	mov ds, ax
	mov es, ax

	call fillScreen

	mov bx, 101h 
	mov dx, 1927h
	call drawFrame

	mov bx, 128h
	mov dx, 1950h
	call drawFrame

	mov dl, 2
	printArray

	call makeResultArray

	mov dl, 41
	printArray

	xor ax, ax
	xor bx, bx
	xor dx, dx
	xor si, si
	mov ax, 4c00h
	int	21h
code ends
end	main
