SCREEN_W   equ 320
SCREEN_H   equ 200
MAP_W      equ 60
MAP_H      equ 12
TILE_W     equ 16
MAP_SIZE   equ MAP_W * MAP_H
CAM_MAX    equ 640

ST_TITLE   equ 0
ST_PLAY    equ 1
ST_PAUSE   equ 2
ST_DYING   equ 3
ST_LIFE    equ 4
ST_WIN     equ 5
ST_DONE    equ 6
ST_OVER    equ 7
ST_EXIT    equ 8

K_ESC      equ 01h
K_SHIFT    equ 2Ah
K_LEFT     equ 4Bh
K_RIGHT    equ 4Dh
K_UP       equ 48h
K_DOWN     equ 50h
K_SPACE    equ 39h
K_P        equ 19h
K_ENTER    equ 1Ch
K_T        equ 14h
K_C        equ 2Eh

T_SKY      equ 0
T_GROUND   equ 1
T_BRICK    equ 2
T_QCOIN    equ 3
T_QMUSH    equ 4
T_EMPTY    equ 5
T_PIPE_L   equ 6
T_PIPE_R   equ 7
T_PIPE_BL  equ 8
T_PIPE_BR  equ 9
T_STAIR    equ 10
T_COIN     equ 11
T_FLAG     equ 12

E_GOOMBA   equ 1
E_KOOPA    equ 2
ES_WALK    equ 0
ES_FLAT    equ 1
ES_SHELL   equ 2
ES_SLIDE   equ 3
ES_DEAD    equ 4
EN_SIZE    equ 10
