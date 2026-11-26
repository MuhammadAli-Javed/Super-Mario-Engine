; interrupts.asm - Ali
; keyboard (IRQ1 / INT 09h) and timer (INT 1Ch) handlers
; keysDown[scan code] =1 while a key is held, 0 when it is released


;installInterrupts
; purpose: saves the old keyboard and timer vectors, then installs our own handlers
; inputs: CS = DS (a .COM program uses one segment)
; output: oldKeyOff/oldKeySeg and oldTickOff/oldTickSeg hold the old vectors,
;irqInstalled = 1
; changes: nothing (all registers are saved and restored)
; DOS 35h gets a vector in ES:BX, DOS 25h sets one from DS:DX

installInterrupts:
    push ax
    push bx
    push dx
    push es

    mov ax, 3509h ;get the old keyboard vector
    int 21h
    mov [oldKeyOff], bx
    mov [oldKeySeg], es

    mov ax, 351Ch ;get the old timer vector
    int 21h
    mov [oldTickOff], bx
    mov [oldTickSeg], es

    mov dx, keyboardISR ; set our keyboard handler
    mov ax, 2509h
    int 21h

    mov dx, timerISR ; set our timer handler
    mov ax, 251Ch
    int 21h

    mov byte [irqInstalled], 1  ;remember that we have to restore them

    pop es
    pop dx
    pop bx
    pop ax
    ret

; restoreInterrupts
; purpose: puts BOTH original vectors back before exiting to DOS
; (call this on every exit path, or the keyboard stops working)
; inputs: the saved old vectors and irqInstalled
; output: old vectors restored, irqInstalled = 0
; changes: nothing (all registers are saved and restored)

restoreInterrupts:
    push ax
    push dx
    push ds

    cmp byte [irqInstalled], 0
    je .done ; nothing was installed, so nothing to restore

    mov ax, [oldKeySeg]
    mov ds, ax ; DS:DX must point to the old handler
    mov dx, [cs:oldKeyOff] ; cs: because DS has changed now
    mov ax, 2509h
    int 21h

    mov ax, [cs:oldTickSeg]
    mov ds, ax
    mov dx, [cs:oldTickOff]
    mov ax, 251Ch
    int 21h

    mov byte [cs: irqInstalled], 0

.done:
    pop ds
    pop dx
    pop ax
    ret


; keyboardISR
; purpose: IRQ1 handler. Reads the scan code and sets or clears keysDown
; inputs: the scan code from port 60h
; output: keysDown[code] = 1 on key press (make), 0 on release (break)
; changes: nothing (all registers saved), ends with iret
; never calls DOS or BIOS inside an interrupt handler
; a release code is the press code + 80h, so and 7Fh gives the key number

keyboardISR:
    push ax
    push bx
    push dx
    push ds

    in al, 60h ; read the scan code from the keyboard
    mov dl, al
    cmp dl, 0E0h
    je .acknowledge ; E0 is a prefix for extended keys, skip it

    mov ax, cs
    mov ds, ax ; an interrupt can happen anywhere, so set DS ourselves
    mov bl, dl
    and bl, 7Fh ; remove the release bit
    xor bh, bh ; bx = key number
    test dl, 80h
    jnz .released
    mov byte [keysDown+bx], 1 ; key pressed
    jmp .acknowledge
.released:
    mov byte [keysDown+bx], 0 ; key released

.acknowledge:
    in al, 61h ; tell the keyboard we have read the key
    mov ah, al
    or al, 80h
    out 61h, al
    mov al, ah
    out 61h, al
    mov al, 20h ; EOI, tells the PIC the interrupt is finished
    out 20h, al

    pop ds
    pop dx
    pop bx
    pop ax
    iret


; timerISR
; purpose: INT 1Ch handler. Adds 1 to timerTicks (about 18.2 times a second)
;then jumps on to the old handler
; inputs: none
; output: timerTicks + 1
; changes: nothing (all registers saved), ends with iret
; the BIOS timer (IRQ0) already does its own EOI, so we do not send one here
; pushf + call far acts like an interrupt call, so the old handler's iret returns to us

timerISR:
    push ax
    push ds
    push cs
    pop ds ; DS = our segment
    inc word [timerTicks]
    pop ds
    pop ax

    pushf
    call far [cs:oldTickOff] ; chain to the old handler
    iret


; newPress
; purpose: tells if a key was just pressed this frame (held now, not held last frame)
; inputs: scan code at [bp+4] (pushed on the stack)
; output: AL = 1 on the first frame it is held, otherwise 0 (AH = 0)
; changes: AX and FLAGS only
; keysPrev is the key table from the previous frame, the main loop copies it

newPress:
    push bp
    mov bp, sp
    push bx

    xor ax, ax ; assume not a new press
    mov bx, [bp+4] ; bx = scan code
    cmp bx, 128
    jae .done ; out of table range
    cmp byte [keysDown+bx], 1
    jne .done ; not held now
    cmp byte [keysPrev+bx], 0
    jne .done ; it was already held last frame
    mov al, 1; held now and not before, new press

.done:
    pop bx
    pop bp
    ret