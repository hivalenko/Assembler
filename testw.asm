.model small
.stack 100h

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

macrPrintInt16 MACRO int16:REQ
	mov ax,int16
	call PrintInt16
ENDM

macrPrintInt16Array MACRO array:REQ, size:REQ, sep:=<','>
	mov cx,size
	mov si,OFFSET array
	mov dl,sep
	call PrintInt16Array
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

initArray SWORD -125,-98,121,-128,-18,349,576,-1245, 348,40
secondArraySize WORD 0

.data?
secondArray SWORD 10 DUP(?)
sumEvenElements WORD ?
offs WORD ?

.code
main PROC
	.startup
	macrPrintString greeting
	macrPrintString initArrayMessage             
    macrPrintInt16Array  initArray,LENGTHOF initArray  
    macrPrintLn    

    mov si,OFFSET initArray
    mov cx,LENGTHOF initArray
    call TransformInt16Array

    macrPrintString step1Message
    macrPrintInt16Array initArray,LENGTHOF initArray
    macrPrintLn

    mov sumEvenElements,0
    mov si,0
    mov bx,LENGTHOF initArray * 2

 step1:
    add si, 2
    cmp si, bx
    jge step2
    mov ax, initArray[si]
    add sumEvenElements, ax
    add si, 2
    cmp si, bx
    jge step2
    jmp step1

step2:
	macrPrintString sumEvenElementsMessage
	macrPrintInt16 sumEvenElements
	macrPrintLn

	mov si,0
	mov bx,0
	mov dx,LENGTHOF initArray

step3:
	mov ax,initArray[si]
	cmp ax,sumEvenElements
	jg step4
	add si,2
	cmp si,dx
	je step5
	jmp step3

step4:
	mov ax,initArray[si]
	mov secondArray[bx],ax
	add bx,TYPE secondArray
	add si,2
	cmp si,dx
	je step5
	jmp step3

step5:
	shr bx,Type initArray/2
	mov secondArraySize,bx
	macrPrintString resultMessage
	macrPrintInt16Array secondArray,secondArraySize

	.exit	
main ENDP


TransformInt16Array PROC USES ax bx dx si di
    pushf               

    cmp   cx,0
    je   return         

    dec  cx             
    shl  cx,1           
    mov  dx,si
    add  dx,cx          

    mov  ax,[si]        
    and  ah,10000000b
    jnz  else1 
    mov  bh,10000000b 
    jmp  endif1 
else1:          
   mov bh,0            

endif1:
    add si,2            
                        
    mov di,si           

l2:                     
    cmp si,dx           
    ja return           
    cmp di,dx           
    je return           

    mov ax,[si]         
    and ah,10000000b    
    xor ax,bx           
    js unfit            
    

    push di 			
    mov  ax,[si]        
    xchg ax,[di]        
    mov [si],ax         

l3:                     
    add di, 2             
	cmp di, si          
	ja metka 			
    mov ax, [si] 		
    xchg ax,[di]		
    mov[si], ax 		
    jmp l3 				
	
metka:  	
	pop di


    not bx              
                        
    add di,2            
    mov si,di           
    jmp l2              
unfit:
    add si,2            
    jmp l2              
return:
    popf                
    RET
TransformInt16Array ENDP


PrintInt16 PROC USES ax cx bx dx
    pushf               

    TEST ah,1000000b    
    jz   positive_ax    
    push ax             
    macrPrintSymbol '-'
    pop  ax             
    neg  ax             

positive_ax:            
    mov  bx,10          
    mov  cx,0      
l1:
    mov  dx,0           
    div  bx             
    add  dx,30h         
    push dx             
    inc  cx             

    cmp ax,0            
    jne l1              

    mov ah,2            
l2:
    pop dx              
    int 21h             
    loop l2             

    popf                
    RET
PrintInt16 ENDP



PrintInt16Array PROC USES ax cx si
    pushf               

    cmp  cx,1
    jb   return         
    je   skip_l1        
    dec  cx             
l1:
    mov  ax,[si]        
    call PrintInt16     
    add  si,2           
    mov  ah,2
    int  21h            

    loop l1            
skip_l1:
    mov  ax,[si]        
    call PrintInt16    
return:
    popf                
    RET
PrintInt16Array ENDP
end 