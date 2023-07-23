org 0x7C00

jmp game_setup

; Constants
TIMER       equ 046Ch
VIDMEM      equ 0b800h
SCREENW     equ 80
SCREENH     equ 25
WINCOND     equ 5
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

    ; Hide annoying blinking cursor
    mov ah, 02h
    mov dx, 2600 ; DH is row, DL is column 
    int 10h

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

        cmp al, 'w'
        je w_pressed

        cmp al, 'a'
        je a_pressed

        cmp al, 's' 
        je s_pressed

        cmp al, 'd'
        je d_pressed

        jmp check_apple

        w_pressed:
            mov bl, UP
            jmp check_apple

        a_pressed:
            mov bl, LEFT
            jmp check_apple

        s_pressed:
            mov bl, DOWN
            jmp check_apple

        d_pressed:
            mov bl, RIGHT
            jmp check_apple

   ; Check if player hit an apple
    check_apple:
        mov byte [direction], bl

        mov ax, [playerX]
        cmp ax, [appleX]
        jne delay_loop

        mov ax, [playerY]
        cmp ax, [appleY]
        jne delay_loop

        inc word [snakeLength]
        cmp word [snakeLength], WINCOND
        je game_won

    ; New apple if did not win
    new_apple:
        ; Random X position 
        xor ah, ah
        int 1Ah          ; Timer ticks in CX:DX
        mov ax, dx       ; Lower half of timer ticks
        xor dx, dx       ; Clear out upper half of ticks
        mov cx, SCREENW
        div cx           ; AX = quotient, DX = remainder (0-79) 
        mov word [appleX], dx

        ; Random Y position
        xor ah, ah
        int 1Ah          ; Timer ticks in CX:DX
        mov ax, dx       ; Lower half of timer ticks
        xor dx, dx       ; Clear out upper half of ticks
        mov cx, SCREENH
        div cx           ; AX = quotient, DX = remainder (0-24) 
        mov word [appleY], dx

    ; Check if apple spawned on the snake
    xor bx, bx
    mov cx, [snakeLength]
    check_apple_on_snake:
        mov ax, [appleX]
        cmp ax, [SNAKEARRAYX+bx]
        jne .increment

        mov ax, [appleY]
        cmp ax, [SNAKEARRAYY+bx]
        je new_apple

        .increment:
            inc bx
            inc bx
    loop check_apple_on_snake
        
    ; Redraw delay
    delay_loop:
    mov bx, [TIMER]
    inc bx
    inc bx
    .delay:
        cmp [TIMER], bx
        jl .delay


jmp game_loop

; End conditions
game_won:
    mov dword [ES:0000], 0f490f57h
    mov dword [ES:0004], 0f210f4eh
    jmp reset

game_over:

    mov dword [ES:0000], 0f410f47h  
    mov dword [ES:0004], 0f450f4dh
    mov dword [ES:0008], 00000000h ; There's probably a better way
    mov dword [ES:0010], 0f560f4fh 
    mov dword [ES:0014], 0f520f45h

reset:
    xor ah, ah
    int 16h  ; Gets keyboard input

    int 19h  ; Reboots qemu

; Bootsector
times 510 - ($-$$) db 0
dw 0aa55h
