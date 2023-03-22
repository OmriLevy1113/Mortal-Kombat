IDEAL
MODEL small
STACK 100h
segment buffer public
	screen_buffer db 64000 dup(0)
ends buffer
segment movement public 
	include "move.inc"
ends movement
segment hitting public
	include "hit.inc"
ends hitting
segment movementP2
	include "moveP2.inc"
ends movementP2
segment hittingP2 public
	include "hitP2.inc"
ends hittingP2
DATASEG
filename db 'bscreen.bmp',0
filehandle dw ?
Header db 54 dup (0)
Palette db 256*4 dup (0)
ScrLine db 320 dup (0)
ErrorMsg db 'Error', 13, 10 ,'$'
sprite_width  	equ 50
sprite_hight equ 78
SCREEN_WIDHT equ 320
SCREEN_HIGHT equ 200	
IGNORE_COLOR equ 215
MOVE_AMOUNT equ 18
TICKS equ 0
starter_player_point dw 39040
starter_player2_point dw 39309
CODESEG
kbdbuf      db 7 dup (0)
proc OpenFile
; Open file
mov ah, 3Dh
xor al, al
mov dx, offset filename
int 21h
jc openerror
mov [filehandle], ax
ret
openerror :
mov dx, offset ErrorMsg
mov ah, 9h
int 21h
ret
endp OpenFile
proc ReadHeader
; Read BMP file header, 54 bytes
mov ah,3fh
mov bx, [filehandle]
mov cx,54
mov dx,offset Header
int 21h
ret
endp ReadHeader
proc ReadPalette
; Read BMP file color palette, 256 colors * 4 bytes (400h)
mov ah,3fh
mov cx,400h
mov dx,offset Palette
int 21h
ret
endp ReadPalette
proc CopyPal
; Copy the colors palette to the video memory
; The number of the first color should be sent to port 3C8h
; The palette is sent to port 3C9h
mov si,offset Palette
mov cx,256
mov dx,3C8h
mov al,0
; Copy starting color to port 3C8h
out dx,al
; Copy palette itself to port 3C9h
inc dx
PalLoop:
; Note: Colors in a BMP file are saved as BGR values rather than RGB .
mov al,[si+2] ; Get red value .
shr al,2 ; Max. is 255, but video palette maximal
; value is 63. Therefore dividing by 4.
out dx,al ; Send it .
mov al,[si+1] ; Get green value .
shr al,2
out dx,al ; Send it .
mov al,[si] ; Get blue value .
shr al,2
out dx,al ; Send it .
add si,4 ; Point to next color .
; (There is a null chr. after every color.)
loop PalLoop
ret
endp CopyPal
proc CopyBitmap
; BMP graphics are saved upside-down .
; Read the graphic line by line (200 lines in VGA format),
; displaying the lines from bottom to top.
mov ax, 0A000h
mov es, ax
mov cx,200
PrintBMPLoop :
push cx
; di = cx*320, point to the correct screen line
mov di,cx
shl cx,6
shl di,8
add di,cx
; Read one line
mov ah,3fh
mov cx,320
mov dx,offset ScrLine
int 21h
; Copy one line into video memory
cld ; Clear direction flag, for movsb
mov cx,320
mov si,offset ScrLine
rep movsb ; Copy line to the screen
 ;rep movsb is same as the following code :
 ;mov es:di, ds:si
 ;inc si
 ;inc di
 ;dec cx
 ;loop until cx=0
pop cx
loop PrintBMPLoop
ret
endp CopyBitmap

;--------------------------------------------- Put Sprite ---------------------------------------------;
;This procedure gets:
;[bp+4] == offset of the image.
;[bp+6] == the location of the player on the screen.
;[bp+8] == the location of the segment.
;[bp+10] == sprite width.
;[bp+12] == sprite hight.
;this procedure doesn't return anything.
;this procedure draw the sprite on the screen.
proc put_sprite
;;;;;;;;;;;;;;;;;;;;;;;  
	push bp
	mov bp,sp
	push ax
	push si
	push dx
	push bx
	push cx
	push ds
;;;;;;;;;;;;;;;;;;;;;;;  

	mov si,[bp+4]
	mov bx,[bp+6]
	mov dx,[bp+12]
	mov ax,[bp+8]
	mov ds,ax
lop2:
	mov cx,[bp+10]
lop:
	mov ah,[byte ptr ds:si]
	cmp ah,IGNORE_COLOR
	je skip
	mov [byte ptr es:bx],ah
skip:
	inc si
	inc bx
	loop lop
	add bx,SCREEN_WIDHT		
	sub bx,[bp+10] 
	dec dx
	cmp dx,0
	jnz lop2

;;;;;;;;;;;;;;;;;;;;;;;  
	pop ds
	pop cx
	pop bx
	pop dx
	pop si
	pop ax
	pop bp
;;;;;;;;;;;;;;;;;;;;;;;  
	ret	10
endp put_sprite
;--------------------------------------------- End Put Sprite ---------------------------------------------;
;this procedure gets:
;[bp+4] == offset of the screen buffer.
;this procedure doesn't return anything.
;this procedure copys the graphic screen to the buffer.
proc copy_to_buffer
;;;;;;;;;;;;;;;;;;;;;;;  
	push bp
	mov bp,sp
	push cx
	push si
	push dx
	push bx
	push ax
	push ds
;;;;;;;;;;;;;;;;;;;;;;;  
	mov dx,SCREEN_HIGHT					
	mov si,[bp+4] ;offset of the buffer
	mov bx,0;stater pixel in graphic screen
	mov ax,buffer
	mov ds,ax
loop_buff2:
	mov cx,SCREEN_WIDHT
loop_buff:
	;-----------
	mov ah,[byte ptr es:bx]
	mov [byte ptr ds:si],ah
	inc bx
	inc si
	loop loop_buff
	;------------
	dec dx	
	cmp dx,0
	jne loop_buff2
	
;;;;;;;;;;;;;;;;;;;;;;;  
	pop ds
	pop ax
	pop bx
	pop dx
	pop si
	pop cx
	pop bp
;;;;;;;;;;;;;;;;;;;;;;;  
	ret 2
endp copy_to_buffer

;this procedure gets:
;[bp+4] == the location of the buffer in the buffer segment.
;[bp+6] == location of the player on the graphic screen.
;[bp+8] == sprite width.
;this procedure doesn't return anything.
;this procedure places the background behind the player.
proc place_buffer_on_screen
;;;;;;;;;;;;;;;;;;;;;;;  
	push bp
	mov bp,sp
	push cx
	push si
	push dx
	push bx
	push ax
	push ds
;;;;;;;;;;;;;;;;;;;;;;;  
	mov dx,sprite_hight					
	mov si,[bp+4] ;offset of the buffer
	mov bx,[bp+6]
	add si,bx
	mov ax,buffer
	mov ds,ax
loop_buff2_place:
	mov cx,[bp+8]
loop_buff_place:
	;-----------
	mov ah,[byte ptr ds:si]
	mov [byte ptr es:bx],ah
	inc bx
	inc si
	loop loop_buff_place
	;------------
	add bx,SCREEN_WIDHT
	sub bx,[bp+8]
	add si,SCREEN_WIDHT
	sub si,[bp+8]
	dec dx	
	cmp dx,0
	jne loop_buff2_place
	
;;;;;;;;;;;;;;;;;;;;;;;
	pop ds
	pop ax
	pop bx
	pop dx
	pop si
	pop cx
	pop bp
;;;;;;;;;;;;;;;;;;;;;;;  
	ret 6
endp place_buffer_on_screen

;this procedure gets:
;[bp+4] == number of ticks to wait.
;this procedure doesn't return anything.
;this procedure create a costume delay.
proc delay
	push bp
	mov bp,sp
	push ax
	push dx
	push bx
	
	mov ah,0
    int 1Ah
    mov bx,dx   ;bx gets the lower part of clock (from dx)

Delay_wait:
    int 1Ah
    sub dx,bx       ;sub the last clock value from the current
    cmp dx,[bp+4]   ;did we wait long enough?
    jl delay_wait
	
	pop bx
	pop dx
	pop ax
	pop bp
	ret 2
endp delay


;this procedure gets:
;[bp+4] == offset moving_forward1 (location of sprite).
;[bp+6] == offset moving_forward2 (location of sprite).
;[bp+8] == offset moving_forward3 (location of sprite).
;[bp+10] == offset moving_forward4 (location of sprite).
;[bp+12] == offset moving_forward5 (location of sprite).
;[bp+14] == offset moving_forward6 (location of sprite).
;[bp+16] == offset moving_forward7 (location of sprite).
;[bp+18] == offset moving_forward8 (location of sprite).
;[bp+20] == offset moving_forward9 (location of sprite).
;[bp+22] == the location of the player in the graphic screen.
;[bp+24] == offset of the screen buffer.
;this procedure returns:
;the updated player location on the graphic screen.
;this procedure creates animation and moving the player forward.
proc moving_forward
;;;;;;;;;;;;;;;;;;;;;;; 
	push bp
	mov bp,sp
	push bx
	push dx
	push ax
;;;;;;;;;;;;;;;;;;;;;;; 
	mov bx,[bp+22]
	mov ax,50
	mov dx,78
	add bx,2
	push movement
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+4]
	call animation
	add bx,2
	push movement
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+6]
	call animation
	add bx,2
	push movement
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+8]
	call animation
	add bx,2
	push movement
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+10]
	call animation
	add bx,2
	push movement
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+12]
	call animation
	add bx,2
	push movement
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+14]
	call animation
	add bx,2
	push movement
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+16]
	call animation
	add bx,2
	push movement
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+18]
	call animation
	add bx,2
	push dx
	push ax
	push movement
	push bx
	push [bp+20]
	call put_sprite
	mov [bp+24],bx
;;;;;;;;;;;;;;;;;;;;;;; 
	pop ax
	pop dx
	pop bx
	pop bp
;;;;;;;;;;;;;;;;;;;;;;; 
	ret 20
endp moving_forward

;this procedure gets:
;[bp+4] == offset moving_forward9 (location of sprite).
;[bp+6] == offset moving_forward8 (location of sprite).
;[bp+8] == offset moving_forward7 (location of sprite).
;[bp+10] == offset moving_forward6 (location of sprite).
;[bp+12] == offset moving_forward5 (location of sprite).
;[bp+14] == offset moving_forward4 (location of sprite).
;[bp+16] == offset moving_forward3 (location of sprite).
;[bp+18] == offset moving_forward2 (location of sprite).
;[bp+20] == offset moving_forward1 (location of sprite).
;[bp+22] == the location of the player in the graphic screen.
;[bp+24] == offset of the screen buffer.
;this procedure returns:
;the updated player location on the graphic screen.
;this procedure creates animation and moving the player backwards.
proc moving_backwards
;;;;;;;;;;;;;;;;;;;;;;; 
	push bp
	mov bp,sp
	push bx
	push dx
	push ax
;;;;;;;;;;;;;;;;;;;;;;;
	mov bx,[bp+22]
	mov dx,78
	mov ax,50
	sub bx,2
	push movement
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+6]
	call animation
	sub bx,2
	push movement
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+8]
	call animation
	sub bx,2
	push movement
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+10]
	call animation
	sub bx,2
	push movement
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+12]
	call animation
	sub bx,2
	push movement
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+14]
	call animation
	sub bx,2
	push movement
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+16]
	call animation
	sub bx,2
	push movement
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+18]
	call animation
	sub bx,2
	push movement
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+20]
	call animation
	sub bx,2
	push dx
	push ax
	push movement
	push bx
	push [bp+4]
	call put_sprite
	mov [bp+24],bx
;;;;;;;;;;;;;;;;;;;;;;; 
	pop ax
	pop dx
	pop bx
	pop bp
;;;;;;;;;;;;;;;;;;;;;;; 
	ret 20
endp moving_backwards

;this procedure gets:
;[bp+4] == offset punching1 (location of sprite).
;[bp+6] == offset punching2 (location of sprite).
;[bp+8] == offset punching3 (location of sprite).
;[bp+10] == offset punching4 (location of sprite).
;[bp+12] == offset punching5 (location of sprite).
;[bp+14] == offset punching6 (location of sprite).
;[bp+16] == offset punching7 (location of sprite).
;[bp+18] == offset punching8 (location of sprite).
;[bp+20] == the location of the player in the graphic screen.
;[bp+22] == offset of the screen buffer.
;[bp+24] == offset moving_forward9 (location of sprite).
;this procedure doesn't return anything.
;this procedure creates the animation of punching.
proc punching
;;;;;;;;;;;;;;;;;;;;;;; 
	push bp
	mov bp,sp
	push bx
	push dx
	push ax
;;;;;;;;;;;;;;;;;;;;;;; 
	mov bx,[bp+20]
	mov dx,78
	mov ax,67
	push hitting
	push 2
	push dx
	push ax
	push [bp+22]
	push bx
	push [bp+4]
	call animation
	push hitting
	push 2
	push dx
	push ax
	push [bp+22]
	push bx
	push [bp+6]
	call animation
	push hitting
	push 2
	push dx
	push ax
	push [bp+22]
	push bx
	push [bp+8]
	call animation
	push hitting
	push 2
	push dx
	push ax
	push [bp+22]
	push bx
	push [bp+10]
	call animation
	push hitting
	push 2
	push dx
	push ax
	push [bp+22]
	push bx
	push [bp+12]
	call animation
	push hitting
	push 2
	push dx
	push ax
	push [bp+22]
	push bx
	push [bp+14]
	call animation
	push hitting
	push 2
	push dx
	push ax
	push [bp+22]
	push bx
	push [bp+16]
	call animation
	push hitting
	push 2
	push dx
	push ax
	push [bp+22]
	push bx
	push [bp+18]
	call animation
	push hitting
	push 2
	push dx
	push ax
	push [bp+22]
	push bx
	push [bp+16]
	call animation
	push hitting
	push 2
	push dx
	push ax
	push [bp+22]
	push bx
	push [bp+4]
	call animation
	push dx
	push 50
	push movement
	push bx
	push [bp+24]
	call put_sprite
;;;;;;;;;;;;;;;;;;;;;;; 
	pop ax
	pop dx
	pop bx
	pop bp
;;;;;;;;;;;;;;;;;;;;;;; 
	ret 22
endp punching

;this procedure gets:
;[bp+4] == offset moving_forwardP2_1 (location of sprite).
;[bp+6] == offset moving_forwardP2_2 (location of sprite).
;[bp+8] == offset moving_forwardP2_3 (location of sprite).
;[bp+10] == offset moving_forwardP2_4 (location of sprite).
;[bp+12] == offset moving_forwardP2_5 (location of sprite).
;[bp+14] == offset moving_forwardP2_6 (location of sprite).
;[bp+16] == offset moving_forwardP2_7 (location of sprite).
;[bp+18] == offset moving_forwardP2_8 (location of sprite).
;[bp+20] == offset moving_forwardP2_9 (location of sprite).
;[bp+22] == the location of the player2 in the graphic screen.
;[bp+24] == offset of the screen buffer.
;this procedure returns:
;the updated player2 location on the graphic screen.
;this procedure creates animation and moving the player2 forward.
proc moving_forwardP2
;;;;;;;;;;;;;;;;;;;;;;; 
	push bp
	mov bp,sp 
	push bx
	push dx
	push ax
;;;;;;;;;;;;;;;;;;;;;;; 
	mov bx,[bp+22]
	mov ax,50
	mov dx,78
	sub bx,2
	push movementP2
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+4]
	call animation
	sub bx,2
	push movementP2
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+6]
	call animation
	sub bx,2
	push movementP2
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+8]
	call animation
	sub bx,2
	push movementP2
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+10]
	call animation
	sub bx,2
	push movementP2
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+12]
	call animation
	sub bx,2
	push movementP2
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+14]
	call animation
	sub bx,2
	push movementP2
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+16]
	call animation
	sub bx,2
	push movementP2
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+18]
	call animation
	sub bx,2
	push dx
	push ax
	push movementP2
	push bx
	push [bp+20]
	call put_sprite
	mov [bp+24],bx
;;;;;;;;;;;;;;;;;;;;;;; 
	pop ax
	pop dx
	pop bx
	pop bp
;;;;;;;;;;;;;;;;;;;;;;; 
	ret 20
endp moving_forwardP2

;this procedure gets:
;[bp+4] == offset moving_forwardP2_9 (location of sprite).
;[bp+6] == offset moving_forwardP2_8 (location of sprite).
;[bp+8] == offset moving_forwardP2_7 (location of sprite).
;[bp+10] == offset moving_forwardP2_6 (location of sprite).
;[bp+12] == offset moving_forwardP2_5 (location of sprite).
;[bp+14] == offset moving_forwardP2_4 (location of sprite).
;[bp+16] == offset moving_forwardP2_3 (location of sprite).
;[bp+18] == offset moving_forwardP2_2 (location of sprite).
;[bp+20] == offset moving_forwardP2_1 (location of sprite).
;[bp+22] == the location of the player2 in the graphic screen.
;[bp+24] == offset of the screen buffer.
;this procedure returns:
;the updated player location on the graphic screen.
;this procedure creates animation and moving the player2 backwards.
proc moving_backwardsP2
;;;;;;;;;;;;;;;;;;;;;;; 
	push bp
	mov bp,sp
	push bx
	push dx
	push ax
;;;;;;;;;;;;;;;;;;;;;;;
	mov bx,[bp+22]
	mov dx,78
	mov ax,50
	add bx,2
	push movementP2
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+6]
	call animation
	add bx,2
	push movementP2
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+8]
	call animation
	add bx,2
	push movementP2
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+10]
	call animation
	add bx,2
	push movementP2
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+12]
	call animation
	add bx,2
	push movementP2
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+14]
	call animation
	add bx,2
	push movementP2
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+16]
	call animation
	add bx,2
	push movementP2
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+18]
	call animation
	add bx,2
	push movementP2
	push TICKS
	push dx
	push ax
	push [bp+24]
	push bx
	push [bp+20]
	call animation
	add bx,2
	push dx
	push ax
	push movementP2
	push bx
	push [bp+4]
	call put_sprite
	mov [bp+24],bx
;;;;;;;;;;;;;;;;;;;;;;; 
	pop ax
	pop dx
	pop bx
	pop bp
;;;;;;;;;;;;;;;;;;;;;;; 
	ret 20
endp moving_backwardsP2

;this procedure gets:
;[bp+4] == offset punchingP2_1 (location of sprite).
;[bp+6] == offset punchingP2_2 (location of sprite).
;[bp+8] == offset punchingP2_3 (location of sprite).
;[bp+10] == offset punchingP2_4 (location of sprite).
;[bp+12] == offset punchingP2_5 (location of sprite).
;[bp+14] == offset punchingP2_6 (location of sprite).
;[bp+16] == offset punchingP2_7 (location of sprite).
;[bp+18] == offset punchingP2_8 (location of sprite).
;[bp+20] == the location of the player2 in the graphic screen.
;[bp+22] == offset of the screen buffer.
;[bp+24] == offset moving_forwardP2_9 (location of sprite).
;this procedure doesn't return anything.
;this procedure creates the animation of punching for the second player.
proc punchingP2
;;;;;;;;;;;;;;;;;;;;;;; 
	push bp
	mov bp,sp
	push bx
	push dx
	push ax
;;;;;;;;;;;;;;;;;;;;;;; 
	mov bx,[bp+20]
	mov dx,78
	sub bx,17
	mov ax,67
	push hittingP2
	push 2
	push dx
	push ax
	push [bp+22]
	push bx
	push [bp+4]
	call animation
	push hittingP2
	push 2
	push dx
	push ax
	push [bp+22]
	push bx
	push [bp+6]
	call animation
	push hittingP2
	push 2
	push dx
	push ax
	push [bp+22]
	push bx
	push [bp+8]
	call animation
	push hittingP2
	push 2
	push dx
	push ax
	push [bp+22]
	push bx
	push [bp+10]
	call animation
	push hittingP2
	push 2
	push dx
	push ax
	push [bp+22]
	push bx
	push [bp+12]
	call animation
	push hittingP2
	push 2
	push dx
	push ax
	push [bp+22]
	push bx
	push [bp+14]
	call animation
	push hittingP2
	push 2
	push dx
	push ax
	push [bp+22]
	push bx
	push [bp+16]
	call animation
	push hittingP2
	push 2
	push dx
	push ax
	push [bp+22]
	push bx
	push [bp+18]
	call animation
	push hittingP2
	push 2
	push dx
	push ax
	push [bp+22]
	push bx
	push [bp+16]
	call animation
	push hittingP2
	push 2
	push dx
	push ax
	push [bp+22]
	push bx
	push [bp+4]
	call animation
	add bx,17
	push dx
	push 50
	push movementP2
	push bx
	push [bp+24]
	call put_sprite
;;;;;;;;;;;;;;;;;;;;;;; 
	pop ax
	pop dx
	pop bx
	pop bp
;;;;;;;;;;;;;;;;;;;;;;; 
	ret 22
endp punchingP2
;this procedure gets:
;[bp+4] == the offset of the sprite that needs drawing.
;[bp+6] == the location of the sprite on the screen.
;[bp+8] == offset of the screen buffer.
;[bp+10] == the sprite width.
;[bp+12] == the sprite hight.
;[bp+14] == the ticks of the cloack that the delay needs to wait.
;[bp+16] == the segment of the sprite.
;this procedure doesn't return anything.
;this procedure creates the cycle of the procedures to create animation.
proc animation
;;;;;;;;;;;;;;;;;;;;;;; 
	push bp
	mov bp,sp
;;;;;;;;;;;;;;;;;;;;;;; 
	push [bp+12]
	push [bp+10]
	push [bp+16]
	push [bp+6]
	push [bp+4]
	call put_sprite
	push [bp+14]
	call delay
	push [bp+10]
	push [bp+6]
	push [bp+8]
	call place_buffer_on_screen
;;;;;;;;;;;;;;;;;;;;;;; 
	pop bp
;;;;;;;;;;;;;;;;;;;;;;; 
	ret 14
endp animation

;this procedure gets:
;[bp+4] == the location of player one on the graphic screen.
;[bp+6] == the location of player two on the graphic screen.
;[bp+8] == sprite width.
;this procedure return:
;nothing.
;this procedure checks if the player made an incorrect move.
proc check_move
	push bp
	mov bp,sp
	push bx
	push dx
	push ax
	mov bx,[bp+4]
	mov dx,[bp+6]
	add bx,[bp+8]
	mov al,[cs:kbdbuf+3]
	cmp al,1
	jne forwardCheckP2
	add bx,MOVE_AMOUNT
	cmp bx,dx
	jna exit_check_move
	mov [cs:kbdbuf+3],0
forwardCheckP2:	
	mov al,[cs:kbdbuf]
	cmp al,1
	jne borderP1
	sub dx,MOVE_AMOUNT
	cmp dx,bx
	jnb exit_check_move
	mov [cs:kbdbuf],0
borderP1:
	mov al,[cs:kbdbuf+1]
	cmp al,1
	jne borderP2
	sub bx,MOVE_AMOUNT
	sub bx,[bp+8]
	cmp bx,39040
	jnb exit_check_move
	mov [cs:kbdbuf+1],0
borderP2:
	mov al,[cs:kbdbuf+2]
	cmp al,1
	jne exit_check_move
	add dx,sprite_width
	add dx,MOVE_AMOUNT
	cmp dx,39359
	jna exit_check_move
	mov [cs:kbdbuf+2],0
exit_check_move:
	pop ax
	pop dx
	pop bx
	pop bp
	ret 6
endp check_move
;this procedure gets:
;[bp+4] == the location of player one on the graphic screen.
;[bp+6] == the location of player two on the graphic screen.
;[bp+8] == the offset of the screen buffer.
;[bp+10] == the sprite width.
;[bp+12] == the sprite hight.
;[bp+14] == offset moving_forward1 (location of sprite).
;[bp+16] == offset moving_forward2 (location of sprite).
;[bp+18] == offset moving_forward3 (location of sprite).
;[bp+20] == offset moving_forward4 (location of sprite).
;[bp+22] == offset moving_forward5 (location of sprite).
;[bp+24] == offset moving_forward6 (location of sprite).
;[bp+26] == offset moving_forward7 (location of sprite).
;[bp+28] == offset moving_forward8 (location of sprite).
;[bp+30] == offset moving_forward9 (location of sprite).
;[bp+32] == offset punching1 (location of sprite).
;[bp+34] == offset punching2 (location of sprite).
;[bp+36] == offset punching3 (location of sprite).
;[bp+38] == offset punching4 (location of sprite).
;[bp+40] == offset punching5 (location of sprite).
;[bp+42] == offset punching6 (location of sprite).
;[bp+44] == offset punching7 (location of sprite).
;[bp+46] == offset punching8 (location of sprite).
;[bp+48] == offset moving_forwardP2_1 (location of sprite).
;[bp+50] == offset moving_forwardP2_2 (location of sprite).
;[bp+52] == offset moving_forwardP2_3 (location of sprite).
;[bp+54] == offset moving_forwardP2_4 (location of sprite).
;[bp+56] == offset moving_forwardP2_5 (location of sprite).
;[bp+58] == offset moving_forwardP2_6 (location of sprite).
;[bp+60] == offset moving_forwardP2_7 (location of sprite).
;[bp+62] == offset moving_forwardP2_8 (location of sprite).
;[bp+64] == offset moving_forwardP2_9 (location of sprite).
;[bp+66] == offset punchingP2_1 (location of sprite).
;[bp+68] == offset punchingP2_2 (location of sprite).
;[bp+70] == offset punchingP2_3 (location of sprite).
;[bp+72] == offset punchingP2_4 (location of sprite).
;[bp+74] == offset punchingP2_5 (location of sprite).
;[bp+76] == offset punchingP2_6 (location of sprite).
;[bp+78] == offset punchingP2_7 (location of sprite).
;[bp+80] == offset punchingP2_8 (location of sprite).
;this procedure returns:
;the updated location of the first and second player.
;the updated key.
proc main
	push bp
	mov bp,sp
	push bx
	push dx
	push ax
	push es
	push si
	push cx
	mov ax,0A000h
	mov es,ax
	mov bx,[bp+4]
	mov dx,[bp+6]
	xor si,si
	mov cx,7
	push [bp+10]
	push dx
	push bx
	call check_move
if_pressed:
	mov     al, [cs:kbdbuf + si]       ;scan array of clickes
	cmp al,1
	je forwards_check
	inc si
	loop if_pressed
	jmp exit_main_proc
forwards_check:
	mov al,[cs:kbdbuf+3]
	cmp al,1
	jne backwards
	push [bp+8]
	push bx
	push [bp+30]
	push [bp+28]
	push [bp+26]
	push [bp+24]
	push [bp+22]
	push [bp+20]
	push [bp+18]
	push [bp+16]
	push [bp+14]
	call moving_forward
	pop bx
backwards:
	mov al, [cs:kbdbuf+1]
	cmp al,1
	jne punch
 	push [bp+8]
	push bx
	push [bp+14]
	push [bp+16]
	push [bp+18]
	push [bp+20]
	push [bp+22]
	push [bp+24]
	push [bp+26]
	push [bp+28]
	push [bp+30]
	call moving_backwards
	pop bx
punch:
	mov al,[cs:kbdbuf+6]
	cmp al,1
	jne forwardP2
	push [bp+30]
	push [bp+8]
	push bx
	push [bp+46] 
	push [bp+44]
	push [bp+42]
	push [bp+40]
	push [bp+38] 
	push [bp+36] 
	push [bp+34]
	push [bp+32] 
	call punching
forwardP2:
	mov al,[cs:kbdbuf]
	cmp al, 1
	jne backwardsP2
	push [bp+8]
	push dx
	push [bp+64]
	push [bp+62]
	push [bp+60]
	push [bp+58]
	push [bp+56]
	push [bp+54]
	push [bp+52]
	push [bp+50]
	push [bp+48]
	call moving_forwardP2
	pop dx
backwardsP2:
	mov al,[cs:kbdbuf+2]
	cmp al,1
	jne punchP2
	push [bp+8]
	push dx
	push [bp+48]
	push [bp+50]
	push [bp+52]
	push [bp+54]
	push [bp+56]
	push [bp+58]
	push [bp+60]
	push [bp+62]
	push [bp+64]
	call moving_backwardsP2
	pop dx
punchP2:
	mov al,[cs:kbdbuf+5]
	cmp al,1
	jne exit_main_proc 
	push [bp+64]
	push [bp+8]
	push dx
	push [bp+80] 
	push [bp+78]
	push [bp+76]
	push [bp+74]
	push [bp+72]
	push [bp+70] 
	push [bp+68]
	push [bp+66] 
	call punchingP2
exit_main_proc:
	mov [bp+76],bx
	mov [bp+78],dx
	mov [bp+80],ax
	pop cx
	pop si
	pop es
	pop ax
	pop dx
	pop bx
	pop bp
	ret 72
endp main

proc change_handler
	push bp
	mov bp,sp
	push bx
	push dx
	mov bx,[bp+4]
	mov dx,[bp+6]
    xor     ax, ax
    mov     es, ax

    cli                              ; interrupts disabled
    push    [word ptr es:9*4+2]      ; save old keyboard (9) ISR address - interrupt service routine(ISR)
    push    [word ptr es:9*4]
	                                 ; put my keyboard (9) ISR address: procedure irq1isr
    mov     [word ptr es:9*4], offset my_isr
	                                 ; put cs in ISR address
    mov     [es:9*4+2],        cs
    sti                               ; interrupts enabled
main_loop:
	push offset punchingP2_8 
	push offset punchingP2_7
	push offset punchingP2_6
	push offset punchingP2_5
	push offset punchingP2_4 
	push offset punchingP2_3 
	push offset punchingP2_2
	push offset punchingP2_1 
	push offset moving_forwardP2_9
	push offset moving_forwardP2_8
	push offset moving_forwardP2_7
	push offset moving_forwardP2_6
	push offset moving_forwardP2_5
	push offset moving_forwardP2_4
	push offset moving_forwardP2_3
	push offset moving_forwardP2_2
	push offset moving_forwardP2_1
	push offset punching8 
	push offset punching7
	push offset punching6
	push offset punching5
	push offset punching4 
	push offset punching3 
	push offset punching2
	push offset punching1 
	push offset moving_forward9
	push offset moving_forward8
	push offset moving_forward7
	push offset moving_forward6
	push offset moving_forward5
	push offset moving_forward4
	push offset moving_forward3
	push offset moving_forward2
	push offset moving_forward1
	push sprite_hight
	push sprite_width
	push offset screen_buffer
	push dx
	push bx
    call    main                     ; program that use the interrupt  lines 43 - 83
	pop bx
	pop dx
	pop ax
	cmp [cs:kbdbuf+4],1
	je end_game
	jmp main_loop
end_game:
    cli                               ; interrupts disabled
    pop     [word ptr es:9*4]         ; restore ISR address
    pop     [word ptr es:9*4+2]
    sti         	; interrupts enabled
	pop dx
	pop bx
	pop bp
    ret 4
endp change_handler

proc my_isr               
 ; my isr for keyboard   
	push    ax
	push    bx
    push    cx
    push    dx
	push    di
	push    si
        

                        ; read keyboard scan code
    in      al, 60h

                        ; update keyboard state
    xor     bh, bh
    mov     bl, al
    and     bl, 7Fh     ; bx = scan code
	cmp bl, 4Dh         ; if click on right arrow (index 1 in array kbdbuf)
	jne check1
	mov bl,2
	jmp end_check
	
check1:
	cmp bl, 1eh		    ; if click on a (index 0 in array kbdbuf)
	jne check2
	mov bl,1
	jmp end_check
	
check2:
	cmp bl, 20h		    ; if click on d (index 2 in array kbdbuf)
	jne check3
	mov bl,3
	jmp end_check
	
check3:
	cmp bl, 4Bh		    ; if click on left arrow (index 3 in array kbdbuf)
	jne check4
	mov bl,0
	jmp end_check
	
check4:
    cmp bl, 1h		    ; if click on esc
	jne check5
	mov bl,4
	jmp end_check
check5:
	cmp bl,39h			; if click space.
	jne check6
	mov bl,5
	jmp end_check
check6:
	cmp bl,2Dh
	jne end_check
	mov bl,6
end_check:
    push cx
	mov cx, 7
    shr al, cl              ; al = 0 if pressed, 1 if released
	pop cx
    xor al, 1               ; al = 1 if pressed, 0 if released
    mov     [cs:kbdbuf+bx], al  ; save pressed buttons in array kbdbuf
	
	
                                ; send EOI to XT keyboard
    in      al, 61h
    mov     ah, al
    or      al, 80h
    out     61h, al
    mov     al, ah
    out     61h, al

                                ; send EOI to master PIC
    mov     al, 20h
    out     20h, al
	
    pop     si
    pop     di                       ;
    pop     dx
    pop     cx
    pop     bx
    pop     ax
   
    iret
endp my_isr	

start:
	mov ax, @data
	mov ds, ax
;---------------------------------------------Main---------------------------------------------;
	mov ax,0A000h
	mov es,ax
	mov ax,13h
	int 10h
	call OpenFile
	call ReadHeader
	call ReadPalette
	call CopyPal
	call CopyBitmap
;-----------------------
	mov bx,[starter_player_point]
	mov dx,[starter_player2_point]
	push offset screen_buffer
	call copy_to_buffer
	push sprite_hight
	push sprite_width
	push movement
	push bx										;starter_player_point.
	push offset moving_forward9					;offset player.
	call put_sprite
	push sprite_hight
	push sprite_width
	push movementP2
	push dx 									;starter_player2_point.
	push offset moving_forwardP2_9				;offset player.
	call put_sprite
	push dx
	push bx
	call change_handler
	mov al,2
	mov ah,0
	int 10h
;---------------------------------------------End Main---------------------------------------------;
	
exit:
	mov ax, 4c00h
	int 21h
END start