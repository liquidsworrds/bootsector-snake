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

; Variables
playerX:     dw 40
playerY:     dw 12
appleX:      dw 16
appleY:      dw 8
direction:   db 4
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
        

     


    jmp game_loop

; Bootsector
times 510 - ($-$$) db 0
dw 0xaa55
