org 0x7C00

jmp game_setup

; Constants
TIMER       equ 046Ch
VIDMEM      equ 0b800h
SCREENW     equ 80
SCREENH     equ 25
WINCOND     equ 10
BGCOLOR     equ 0020h
SNAKECOLOR  equ 2020h
APPLECOLOR  equ 4020h
SNAKEARRAYX equ 1000h
SNAKEARRAYY equ 2000h
UP          equ 0
DOWN        equ 1
LEFT        equ 2
RIGHT       equ 3
TOP         equ -1

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
    mov ax, 0003h
    int 10h

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
            jne .snake_update_loop            ; Stops at head

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

    ; Lose conditions

    ; 1. Hit borders of the screen
    cmp word [playerY], -1
    je game_over

    cmp word [playerY], SCREENH ; screen rows are 0-24 
    je game_over

    cmp word [playerX], -1
    je game_over

    cmp word [playerX], SCREENW
    je game_over

    ; 2. Snake hits itself
    cmp word [snakeLength], 1
    je get_player_input

    mov bx, 2             ; Start from 2nd segment
    mov cx, [snakeLength] ; Loop counter

    check_if_snake_hit_itself:
    mov ax, [playerX]
    cmp ax, [SNAKEARRAYX+bx]
    jne .increment

    mov ax, [playerY]
    cmp ax, [SNAKEARRAYY+bx]
    je game_over

    .increment:           ; Increment bx to check the next segment
        inc bx
        inc bx
    loop check_if_snake_hit_itself
        
    ; Player input
    get_player_input:
        mov bl, [direction]
        
        mov ah, 1
        int 16h
        jz check_apple
        
        xor ah, ah
        int 16h ; ah has the scancode and al has the ascii char

        cmp al, 'h'
        je h_pressed

        cmp al, 'j'
        je j_pressed

        cmp al, 'k' 
        je k_pressed

        cmp al, 'l'
        je l_pressed

        jmp check_apple

        h_pressed:
            mov bl, LEFT
            jmp check_apple

        j_pressed:
            mov bl, DOWN
            jmp check_apple

        k_pressed:
            mov bl, UP
            jmp check_apple

        l_pressed:
            mov bl, RIGHT
            jmp check_apple

        ; Check if player hit an apple
        check_apple:
            mov byte [direction], bl

jmp game_loop

; End conditions
game_won:
    jmp reset

game_over:

    mov dword [ES:0000], 0f410f47h  
    mov dword [ES:0004], 0f450f4dh
    mov dword [ES:0008], 00000000h ; There's probably a better way
    mov dword [ES:0010], 0f560f4fh 
    mov dword [ES:0014], 0f520f45h

reset:
    xor ah, ah
    int 16h

    int 19h  ; Reboots qemu

; Bootsector
times 510 - ($-$$) db 0
dw 0aa55h
