	[ORG 0x00]              ; Start code Address 0x00          
[BITS 16]               ; code size 16-bit

SECTION .text           ; text section

jmp 0x07C0:START        ; copy 0x07c0 to CS & jump to START

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   MINT64 OS Preperense
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TOTALSECTORCOUNT:   dw  0x02    ; size of MINT64 OS (MAX 1152sector)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
START:
    mov ax, 0x07C0  
    mov ds, ax      ; ds = Start address (Bootloader)
    mov ax, 0xB800  
    mov es, ax      ; es = Start address (Video Memory)

    ; Stak : 0x0000:0000~0x0000:FFFF (size 64KB)
    mov ax, 0x0000  
    mov ss, ax      ; ss = Start address (Stack segment)
    mov sp, 0xFFFE  ; SP address = 0xFFFE
    mov bp, 0xFFFE  ; BP address = 0xFFFE

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; clear & green
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov si,    0                    ; SI reset
        
.SCREENCLEARLOOP:                   ; clear loop
    mov byte [ es: si ], 0          ; clear
    mov byte [ es: si + 1 ], 0x0A   ; set black background & green text

    add si, 2                       ; next

    cmp si, 80 * 25 * 2             ; screen size = 80 * 25 * 2
    jl .SCREENCLEARLOOP             ; if less > loop

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; "START" MESSAGE
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    push MESSAGE1               ; "START" message push stack
    push 0                      
    push 0                      ; in (0,0)
    call PRINTMESSAGE           ; PRINT
    add  sp, 6                  ; remove parameter
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; "TIME" MESSAGE
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    push 	TIMEMESSAGE         ; "TIME" message push stack
	push 	1
	push	0                   ; in (0, 1)
	call	PRINTMESSAGE        ; PRINT
	add	sp,	6                   ; remove parameter
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; "TIME" PRINT
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ah,2h                           
    int 1ah                             ; Get local time

    mov ah, 0x0e
    mov al, CH
    and al,0xf0
    shr al,0x04
    add al,0x30
    mov byte [ es : (160*1)+32],al   
 
    mov al, CH
    and al,0x0f
    add al,0x30    
    mov byte [ es : (160*1)+34],al   

    mov ah, 0x0e
    mov al, ":"
    mov byte [ es : (160*1)+36],al 

    mov ah, 0x0e
    mov al, CL
    and al,0xf0
    shr al,0x04
    add al,0x30
    mov byte [ es : (160*1)+38],al    
 
    mov al, CL
    and al,0x0f
    add al,0x30
    mov byte [ es : (160*1)+40],al 

    mov ah, 0x0e
    mov al, ":"
    mov byte [ es : (160*1)+42],al 

    mov ah, 0x0e
    mov al, DH
    and al,0xf0
    shr al,0x04
    add al,0x30
    mov byte [ es : (160*1)+44],al    

    mov al, DH
    and al,0x0f
    add al,0x30
    mov byte [ es : (160*1)+46],al 

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; "OS IMAGE LOADING" message
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    push IMAGELOADINGMESSAGE    ; "OS IMAGE LOADING" message push stack         
    push 2                                           
    push 0                      ; in (0, 2)                    
    call PRINTMESSAGE           ; PRINT                          
    add  sp, 6                  ; remove parameter                             
        
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; "OS IMAGE LOADING"
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; RESET DISK
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RESETDISK:                          ; Start reset disk
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; BIOS Reset
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; service num 0, drive num 0(Floppy)
    mov ax, 0
    mov dl, 0              
    int 0x13     
    jc  HANDLEDISKERROR                     ; error
        
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Read sector from disk
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov si, 0x1000                  
    mov es, si                          ; es = To copy OS image in (0x10000)
    mov bx, 0x0000                      ; TO Copy in (0x1000:0000) 

    mov di, word [ TOTALSECTORCOUNT ]   ; di = OS image sector
READDATA:                               ; READ disk
    ; Comfirm that read all
    cmp di, 0                           ; compare sector count
    je  READEND                         ; equle > READEND
    sub di, 0x1                         ; different > sector count--

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
