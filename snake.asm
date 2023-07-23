org 0x7C00

jmp game_setup

; Constants
TIMER       equ 0x046C
VIDMEM      equ 0xb800
SCREENW     equ 80
SCREENH     equ 25
WINCOND     equ 10
BGCOLOR     equ 0x0020
SNAKECOLOR  equ 0x2020
APPLECOLOR  equ 0x4020
SNAKEARRAYX equ 0x1000
SNAKEARRAYY equ 0x2000
UP          equ 0
DOWN        equ 1
LEFT        equ 2
RIGHT       equ 3

; Variables
playerX:     dw 40
playerY:     dw 12
appleX:      dw 16
appleY:      dw 8
direction:   db 3
snakeLength: dw 1

; Game

game_setup:

    ; VGA mode
    mov ax, 0x003
    int 0x10

    mov ax, VIDMEM
    mov es, ax      ; ES:DI <- video memory
    
    mov ax, [playerX]
    mov word [SNAKEARRAYX], ax
    mov ax, [playerY]
    mov word [SNAKEARRAYY], ax


game_loop:

    ; Clear screen 
    mov ax, BGCOLOR
    xor di, di 
    mov cx, SCREENW * SCREENH
    rep stosw       ; mov [ES:DI], AX and inc di

    
    ; Draw Snake 
    xor bx, bx
    mov cx, [snakeLength]
    mov ax, SNAKECOLOR
    .snake_loop:
        imul di, [SNAKEARRAYY+bx], SCREENW*2    ; VGA text mode -> 1 byte = fg and bg color 1 byte = char
        imul dx, [SNAKEARRAYX+bx], 2
        add di, dx
        stosw
        add bx, 2
    loop .snake_loop

    ; Draw Apple
    imul di, [appleY], SCREENW*2
    imul dx, [appleX], 2
    add di, dx
    mov ax, APPLECOLOR
    stosw

    ; Move the snake
    mov al, [direction]
    cmp al, UP
    je move_up

    mov al, [direction]
    cmp al, DOWN
    je move_down

    mov al, [direction]
    cmp al, LEFT
    je move_left

    mov al, [direction]
    cmp al, RIGHT
    je move_right

    jmp update_snake

    move_up:
        dec word [playerY]  
        jmp update_snake

    move_down:
        inc word [playerY]
        jmp update_snake

    move_left:
        dec word [playerX]
        jmp update_snake
        
    move_right:
        inc word [playerX]

    ; Update snake segments from back to front
    update_snake:
        imul bx, [snakeLength], 2 ; Each segment is 2 bytes
            .snake_update_loop:
                mov ax, [SNAKEARRAYX-2+bx]    
                mov word [SNAKEARRAYX+bx], ax ; X of last segment in ax is moved to the one before it 
               
                mov ax, [SNAKEARRAYY-2+bx]
                mov word [SNAKEARRAYY+bx], ax ; Y of last segment in ax is moved to the one before it 

                dec bx
                dec bx
            jne .snake_update_loop           ; Stops at head

    ; Storing updated values of head to SNAKEARRAY
    mov ax, [playerX]
    mov word [SNAKEARRAYX], ax

    mov ax, [playerY]
    mov word [SNAKEARRAYY], ax

    ; Redraw delay
    delay_loop:
    mov bx, [TIMER]
    inc bx
    inc bx
    .delay:
        cmp [TIMER], bx
        jl .delay


jmp game_loop


; Bootsector
times 510 - ($-$$) db 0
dw 0xaa55
