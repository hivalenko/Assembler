.model small
.stack
.386

cr = 0dh
lf = 0ah


macrPrintSymbol MACRO symbol:REQ
	mov ah,2
	mov dl,symbol
	int 21h
ENDM


macrPrintString MACRO string:REQ
	mov ah,9
	mov dx,OFFSET string
	int 21h
ENDM


macrPrintInt32 MACRO int32:REQ
	mov eax,int32
	call PrintInt32
ENDM


macrPrintInt32Array MACRO array:REQ, size:REQ, sep:=<','>
	mov cx,size
	mov si,OFFSET array
	mov dl,sep
	call PrintInt32Array
ENDM


macrPrintLn MACRO
	macrPrintSymbol cr
	macrPrintSymbol lf
ENDM


.data
greeting BYTE "Lab 1 Yegor Kovalenko P3217", cr, lf, "testString",cr,lf,"----------",cr,lf,cr,lf,'$'
initArrayMessage BYTE "Initial array: $"
step1Message BYTE "Array after step 1: $"
sumEvenElementsMessage BYTE "Sum of even elements: $"
resultMessage BYTE "Result array: $"

initArray SDWORD -125,-98,-1245,-128,-18,349,576,121,348,40
secondArraySize WORD 0

.data?
secondArray SDWORD 10 DUP(?)
sumEvenElements SDWORD ?
offs WORD ?

.code
main PROC
	.startup
	macrPrintString greeting
	macrPrintString initArrayMessage             
    macrPrintInt32Array  initArray,LENGTHOF initArray  
    macrPrintLn    

    mov si,OFFSET initArray
    mov cx,LENGTHOF initArray
    call TransformInt32Array

    macrPrintString step1Message
    macrPrintInt32Array initArray,LENGTHOF initArray
    macrPrintLn

    mov sumEvenElements,0
    mov si,0
    mov bx,LENGTHOF initArray * 4

 step1:
    add si, 4
    cmp si, bx
    jge step2
    mov eax, initArray[si]
    add sumEvenElements, eax
    add si, 4
    cmp si, bx
    jge step2
    jmp step1

step2:
	macrPrintString sumEvenElementsMessage
	macrPrintInt32 sumEvenElements
	macrPrintLn

	mov esi,0
	mov ebx,0
	mov edx,LENGTHOF initArray

step3:
	mov eax,initArray[esi]
	cmp eax,sumEvenElements
	jg step4
	add esi,4
	cmp esi,edx
	jge step5
	jmp step3

step4:
	mov eax,initArray[esi]
	mov secondArray[ebx],eax
	add bx,TYPE secondArray
	add esi,4
	cmp esi,edx
	jge step5
	jmp step3

step5:
    shr bx,Type initArray/2
    mov secondArraySize,bx
    macrPrintString resultMessage
	macrPrintInt32Array secondArray,secondArraySize

	.exit	
main ENDP


TransformInt32Array PROC USES ax bx dx si di
    pushfd              ; save flags

    cmp   cx,0
    je   return         ; return if empty array

    dec  cx             ; cx = (index of the last element)
    shl  cx,2           ; mult. cx by 2, so cx = (byte-index of the last element)
    mov  dx,si
    add  dx,cx          ; dx now points to the last element

    mov  eax,[si]        ; copy first element to ax
    and  eax,080000000h   ; and with 80h to find out sign of 1st element
    jnz  else1          ; if FZ != 0 (el. is < 0), skip several lines
    mov  ebx,080000000h  ; if FZ = 0 (el. is > 0) move 10000000b to bh, which
    jmp  endif1          ; means that next element should be < 0

else1:                  ; if FZ != 0 (el. is < 0), move 0 to bh, which
    mov ebx,0            ; means that next element should be >= 0

endif1:
    add si,4            ; si used as a pointer to itereate from [di] to [lastElement]
                        ; to element with required sign
    mov di,si           ; di points to element that needs to be replaced

l2:                     ; loop that transfrom array (from [2ndElement] to [lastElement])
    cmp si,dx           ; check if si not out of array range
    ja return           ; if so, end loop
    cmp di,dx           ; check if di points to the last element
    je return           ; if so, end loop

    mov eax,[si]         ; move curr. el. to ax
    and eax,080000000h    ; and it with 80h to determine its sign
    xor eax,ebx           ; if MSB of AX and of BX are the same (AX xor BX sets SF to 0)
                        ; then [si] has required sign, if not, it has wrong sign
    js unfit            ; SF = 0 means fit, SF = 1 - unfit
    

    push di 			; pushing di to stack
    mov  eax,[si]        ; swap [si] and [di]
    xchg eax,[di]        ;
    mov [si],eax         ;

l3:                     ; swapping all walues in stack increasing di until   
	add di, 4              ; result equals insertion in middle of stack
	cmp di, si          ;
	ja metka 			;
    mov eax, [si] 		;
    xchg eax,[di]		;
    mov[si], eax 		;
    jmp l3 				;
	
metka:  	
	pop di


    not ebx              ; reverse bx (meaning that next el. should be of the
                        ; opposite sign (only the first bit matters))
    add di,4            ; move di to the next element
    mov si,di           ; si = di
    jmp l2              ; start over
unfit:
    add si,4            ; move si to the next element
    jmp l2              ; start over
return:
    popfd               ; restore flags
    RET
TransformInt32Array ENDP

PrintInt32 PROC USES eax cx ebx edx
    pushfd               ; save flags

    TEST eax,080000000h    ; see if MSB is 1 or 0
    jz   positive_ax    ; if ax is positive, skip next lines
    push eax             ; save ax
    macrPrintSymbol '-'
    pop  eax             ; restore ax
    neg  eax             

positive_ax:            
    mov  ebx,10          ; bx will be used to compute modulus of
                        ; ax/10 to find each of its digits
    mov  cx,0           ; initialize loop counter
l1:
    mov  edx,0           
    div  ebx             ; div ax by bx to find the last digit
    add  dx,30h         ; convert last digit to ASCII
    push dx             ; save digit to stack
    inc  cx             ; increment loop counter

    cmp eax,0            ; if ax zero, stop, beacuse all digits are
    jne l1              ; on the stack, else start over the loop l1

    mov ah,2            ; interupt 21h's second function
l2:
    pop dx              ; pop digits from stack (now the will be in right order)
    int 21h             ; print digit (21h interrupt's 2nd function)
    loop l2             ; after l1 cx is equal to number of digits, so use it

    popfd                ; restore flags
    RET
PrintInt32 ENDP



PrintInt32Array PROC USES eax cx si
    pushfd               ; save flags

    cmp  cx,1
    jb   return         ; if empty array, return
    je   skip_l1        ; if length = 1, skip loop
    dec  cx             ; dec cs, loop won't print last el.
l1:
    mov  eax,[si]        ; mov current element to ax
    call PrintInt32     
    add  si,4           ; move to the next element
    mov  ah,2           ; interrupt 21h's 2nd function
    int  21h            ; print seperator (stores in DL)

    loop l1             ; do while cx > 0
skip_l1:
    mov  eax,[si]        ; last element printed ouside the loop
    call PrintInt32     ; separator is not printed after it
return:
    popfd                ; restore flags
    RET
PrintInt32Array ENDP
end 