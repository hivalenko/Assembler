; Перехватывается прерывание 09H (клавиатура), горячая клавиша: <Alt>+<S>.
; Действие резидентной части программы: записать определённую последовательность символов в буфер клавиатуры (в области данных BIOS).
; Последовательность символов задаётся в строке параметров программы.

.model tiny
.code
org 100h

main:
	jmp setup

	installMessage    db 'Program started. Input sequense.', 10, 13, '$'
	hotkeyInfoMessage db 'Press Alt+S to set keyboard buffer text or Alt+Q to terminate.', '$'
	runningMessage    db 'Program is already running. Press Alt+S to set keyboard buffer text or Alt+Q to stop.', 10, 13, '$'
	terminateMessage  db 10, 13, 'Program stopped.', 10, 13, '$'
	systemHandler dd 00000000h
	buffer    dw 128 dup('$')
	count	  dw 0

	SCANCODE_Q equ 10h
	SCANCODE_S equ 1Fh
	ALT_PRESSED_MASK   equ 0001000b
	REPLACED_INTERRUPT equ 09h

	print macro string:REQ
		mov ax, cs
		mov ds, ax
		lea dx, string
		mov ah, 09h
		int 21h
	endm

; резидентный обработчик
customHandler proc far uses ax cx di si ds es
	; проверяем флаги клавиатуры
	mov ah, 02h
	int 16h
	; вызываем системное прерывание, если альт не нажат
	test al, ALT_PRESSED_MASK
	jz invokeSystemInterrupt

	; проверяем, нажаты ли S/Q
	in al, 60h
	cmp al, SCANCODE_Q
	je terminate			  ; нажата Q - выход
	cmp al, SCANCODE_S
	je outputBuffer			  ; нажата S - вывод клавиш из буфера
	jmp invokeSystemInterrupt ; вызываем системное прерывание

outputBuffer:
	mov cx, cs:count
	shr cx, 1
	xor si, si
	keystroke:
		push cx

		mov cx, cs:buffer[si]
		mov ah, 05h
		int 16h

		add si, 2

		pop cx
	loop keystroke

	jmp skipSystemInterrupt

; завершение программы
terminate:
	; возвращаем старый обработчик в таблицу прерываний
	mov ax, word ptr cs:systemHandler[2]
	mov ds, ax
	mov dx, word ptr cs:systemHandler
	mov ax, 2509h
	int 21h

	; устанавливаем флаги
	mov ax, 25FFh
	mov dx, 0000h
	int 21h

	push es

	; освобождаем окружение (PSP)
	mov es, cs:2Ch
	mov ah, 49h
	int 21h

	; удаляем резидент
	push cs
	pop es
	mov ah, 49h
	int 21h
	pop es

	; выводим сообщение об удалении
	push ds
	print cs:terminateMessage
	pop ds

	jmp skipSystemInterrupt

; вызываем системное прерывание
invokeSystemInterrupt:
	pushf
	call cs:systemHandler
	jmp exit

; пропускаем системное прерывание
skipSystemInterrupt:
	; устанавливаем 7 бит порта, а затем возвращаем его
    in al, 61H
    mov ah, al
    or al, 80h
    out 61H, al
    xchg ah, al
    out 61H, al

    mov al, 20H     ; \ отправляем сигнал завершения
    out 20H, al     ; / контроллеру прерываний

exit:
	iret
customHandler endp
customHandlerEnd:

;==============================================================================
setup:
	; получаем FF вектора прерываний
	mov ax, 35FFh
	int 21h
	cmp bx, 0000h
	jne running

install:
	print installMessage

	xor si, si
	bufferInput:
		; Считываем коды в AX
		xor ah, ah
		int 16h

		; Если enter, завершаем
		cmp al, 13
		je endOfInput

		; Записываем в буфер
		mov buffer[si], ax
		add si, 2
		mov count, si

		; mov cx, ax
		; mov ah, 05h
		; int 16h

	jmp bufferInput

	endOfInput:
	print hotkeyInfoMessage

	; устанавливаем вектор прерывания
	mov ax, 25FFh
	mov dx, 0001h	; адрес резидентного обработчика
	int 21h

	; получаем системный адрес прерываний
	mov ah, 35h
	mov al, REPLACED_INTERRUPT
	int 21h
	mov word ptr cs:systemHandler, bx
	mov word ptr cs:systemHandler+2, es

	; установка вектора прерываний
	mov ah, 25h
	mov al, REPLACED_INTERRUPT
	lea dx, customHandler
	int 21h

	; завершиться и остаться резидентным
	mov dx, offset customHandler - offset customHandlerEnd
	mov cl, 4
	shr dx, cl
	inc dx

	mov ax, 3100h	; код выхода 0
	int 21h

running:
	print runningMessage
	mov ax, 4C00h
	int 21h

end main
