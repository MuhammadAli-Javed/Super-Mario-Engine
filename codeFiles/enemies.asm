; Moiz: enemy records and interactions
; Record: type, state, worldX(word), y(word), direction, timer, active, fraction

enemyOriginal:
    db E_GOOMBA, ES_WALK
    dw 160, 144
    db 0, 0, 0, 0
    db E_GOOMBA, ES_WALK
    dw 192, 144
    db 1, 0, 0, 0
    db E_GOOMBA, ES_WALK
    dw 512, 144
    db 0, 0, 0, 0
    db E_GOOMBA, ES_WALK
    dw 688, 144
    db 0, 0, 0, 0
    db E_KOOPA, ES_WALK
    dw 456, 144
    db 0, 0, 0, 0
    db E_KOOPA, ES_WALK
    dw 752, 144
    db 0, 0, 0, 0
enemyList: times 6*EN_SIZE db 0

; Restore all enemies from their original records.
; Input none; output enemyList; preserves all registers.
resetEnemies:
    push cx
    push si
    push di
    push es
    push ds
    pop es
    mov si, enemyOriginal
    mov di, enemyList
    mov cx, 6*EN_SIZE
    cld
    rep movsb
    pop es
    pop di
    pop si
    pop cx
    ret