; check_map.asm - small test for getTile and resetMap
; build from the repo root: nasm -f bin tests/check_map.asm -o CHECK.COM

cpu 8086
[org 0x0100]

%include "codeFiles/constants.inc"

jmp start

%include "codeFiles/gameData.inc"
%include "assets/level.inc"
%include "codeFiles/world.asm"

passMsg db "CHECK PASSED$"
failMsg db "CHECK FAILED$"

start:
    push cs
    pop ds ; DS = CS, a .COM program uses one segment
    cld

    ; test 1: getTile should find ground at x=32, y=160
    call resetMap  ; make sure gameMap is fresh
    mov ax, 160
    push ax ; y (pushed first)
    mov ax, 32
    push ax  ; x
    call getTile
    add sp, 4 ; remove the two parameters
    cmp al, T_GROUND ; x=32 -> column 2, y=160 -> row 10, that is ground
    jne failed

    ; test 2: resetMap should bring a changed tile back
    mov byte [gameMap+600], 0 ; erase a ground tile (row 10, column 0)
    call resetMap
    cmp byte [gameMap+600], T_GROUND
    jne failed

    mov dx, passMsg ; both tests passed
    jmp finish

failed:
    mov dx, failMsg

finish:
    mov ah, 09h ;print the $ terminated string at DS:DX
    int 21h
    mov ax, 4c00h
    int 21h