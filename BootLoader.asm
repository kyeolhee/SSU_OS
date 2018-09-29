[ORG 0x00]
[BITS 16]

SECTION .text

jmp 0x07C0:START

TOTALSECTORCOUNT:	dw	1024

START:



    mov ax, 0x07C0
    mov ds, ax
    mov ax, 0xB800
    mov es, ax

	mov	ax,	0x0000
	mov	ss,	ax
	mov	sp,	0xFFFE
	mov	bp,	0xFFFE
   
   ; Clear & color=grean;
    mov	si,		0 

.SCREENCLEARLOOP:
    mov byte [ es: si ], 0
    mov byte [ es: si + 1 ], 0x0A

    add si, 2
    cmp si, 80 * 25 * 2

    jl .SCREENCLEARLOOP
; "START" message ;	
	push	MESSAGE1
	push	0
	push	0
	call	PRINTMESSAGE
	add	sp,	6

; "TIME" 	message ;
	push 	TIMEMESSAGE
	push 	1
	push	0
	call	PRINTMESSAGE
	;add	sp,	6


; TIME PRINT ;
    mov ah,2h
    int 1ah

    mov ah, 0x0e
    mov al, CH
    and al,0xf0
    shr al,0x04
    add al,0x30
    mov byte [ es : (160*1)+32],al   
    ;int 0x10

    mov al, CH
    and al,0x0f
    add al,0x30    
    mov byte [ es : (160*1)+34],al 

    ;int 0x10
    

    mov ah, 0x0e
    mov al, ":"
    mov byte [ es : (160*1)+36],al 
    ;int 0x10


    mov ah, 0x0e
    mov al, CL
    and al,0xf0
    shr al,0x04
    add al,0x30
    mov byte [ es : (160*1)+38],al    
    ;int 0x10

    mov al, CL
    and al,0x0f
    add al,0x30
    mov byte [ es : (160*1)+40],al 
    ;int 0x10

    mov ah, 0x0e
    mov al, ":"
    mov byte [ es : (160*1)+42],al 
    ;int 0x10


    mov ah, 0x0e
    mov al, DH
    and al,0xf0
    shr al,0x04
    add al,0x30
    mov byte [ es : (160*1)+44],al    
    ;int 0x10

    mov al, DH
    and al,0x0f
    add al,0x30
    mov byte [ es : (160*1)+46],al 
    ;int 0x10


; "OS IMAGE LOADING" message ;
	push	IMAGELOADINGMESSAGE
	push	2
	push	0
	call	PRINTMESSAGE
	add	sp,	6

	; OS image loading ;
	; Reset ;
	RESERRDISK:

	; DIOS Reset Func call ;
	mov	ax,	0
	mov	dl,	0
	int 0x13

	jc	HANDLEDISKERROR

	; Read sector ;
	mov	si,	0x1000
	mov	es,	si
	mov	bx,	0x0000

	mov	di,	word [TOTALSECTORCOUNT]

READDATA:
	;Test
	cmp	di,	0
	je	READEND	
	sub	di,	0x1

	;BIOS Read Func call ;
	mov	ah,	0x02
	mov	al,	0x1
	mov	ch,	byte	[TRACKNUMBER]
	mov	cl,	byte	[SECTORNUMBER]
	mov	dh,	byte	[HEADNUMBER]
	mov	dl,	0x00
	int	0x13
	jc	HANDLEDISKERROR

	;count track, head, sector that copy
	add	si,	0x0020
	mov	es,	si

	mov	al,	byte	[SECTORNUMBER]
	add	al, 0x01
	mov	byte	[SECTORNUMBER],	al
	cmp	al,	19
	jl	READDATA

	xor byte	[HEADNUMBER],	0x01
	mov byte	[SECTORNUMBER],	0x01

	cmp byte	[HEADNUMBER], 0x00
	jne	READDATA

	add	byte [TRACKNUMBER],	0x01
	jmp	READDATA
READEND:

	;"OS IMAGE COMPLETE" message;
	push LOADINGCOMPLETEMESSAGE
	push 2
	push 20
	call PRINTMESSAGE
	add sp,	6

	; OS IMAGE RUN ;
	jmp 0x1000:0x0000

;FUNC;
;DISK ERROR;
HANDLEDISKERROR:
	push DISKERRORMESSAGE
	push 1
	push 20
	call PRINTMESSAGE
	
	jmp $
	

PRINTMESSAGE:
	push bp
	mov bp, sp
	
	push es
	push si
	push di
	push ax
	push cx
	push dx
	
	mov ax, 0xB800
	mov es, ax
	
	;count video memory;
	mov ax, word [bp+6]
	mov si, 160
	mul si
	mov di, ax
	
	mov ax, word[bp+4]
	mov si, 2
	mul si
	add di, ax

	mov si, word[bp+8]
.MESSAGELOOP:
	mov cl, byte[si]
	cmp cl, 0
	je .MESSAGEEND

	mov byte [es:di], cl

	add si, 1
	add di, 2

	jmp .MESSAGELOOP

.MESSAGEEND:
	pop dx
	pop cx
	pop ax
	pop di
	pop si
	pop es
	pop bp
	ret
	
;DATA;
MESSAGE1:    db 'MINT64 OS Boot Loader Start~!!', 0
TIMEMESSAGE:	db	'Currunt TIme : ', 0

DISKERRORMESSAGE:		db	'DISK Error~!!', 0
IMAGELOADINGMESSAGE:	db	'OS Image Loading...', 0
LOADINGCOMPLETEMESSAGE:	db	'Complete~!!', 0

SECTORNUMBER:		db	0x02
HEADNUMBER:		db	0x00
TRACKNUMBER:		db	0x00

times 510 - ( $ - $$ )    db    0x00

db 0x55
db 0xAA