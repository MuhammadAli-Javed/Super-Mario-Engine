; Super Mario Engine
; starting COM program cpu 8086

[org 0x0100]

jmp start

start:
    mov ax, 0003h
    int 10h

mov ax, 4c00h
int 21h
