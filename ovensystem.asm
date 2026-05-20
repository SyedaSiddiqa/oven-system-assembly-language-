.MODEL SMALL
.STACK 100H

.DATA

title1 DB 13,10,'==============================$'
title2 DB 13,10,'   SMART OVEN SYSTEM$'
title3 DB 13,10,'==============================$'

menu1 DB 13,10,'1. Power ON/OFF$'
menu2 DB 13,10,'2. Set Temperature$'
menu3 DB 13,10,'3. Set Timer$'
menu4 DB 13,10,'4. Select Cooking Mode$'
menu5 DB 13,10,'5. Start Cooking$'
menu6 DB 13,10,'6. Exit$'

askMsg DB 13,10,'Enter Choice: $'

onMsg  DB 13,10,'System Powered ON$'
offMsg DB 13,10,'System Powered OFF$'

tempMsg  DB 13,10,'Select Temperature: 1=100C 2=200C 3=300C$'

timerMsg DB 13,10,'Set Timer (1-9 seconds): $'

modeMsg   DB 13,10,'1.Baking 2.Grilling 3.Reheating$'

bakeMsg   DB 13,10,'Baking Mode Selected$'
grillMsg  DB 13,10,'Grilling Mode Selected$'
reheatMsg DB 13,10,'Reheating Mode Selected$'

startMsg  DB 13,10,'Cooking Started...$'

pauseMsg  DB 13,10,'Cooking Paused$'
resumeMsg DB 13,10,'Cooking Resumed$'

countMsg  DB 13,10,13,10,'Time Left: $'

finishMsg DB 13,10,'Cooking Complete! BEEP!$'

warningMsg DB 13,10,'WARNING! OVERHEAT DETECTED$'

controlMsg DB 13,10,'Press P=Pause  R=Resume  E=Exit$'

newline DB 13,10,'$'

powerFlag DB 0
ovenTemp  DB 1
cookTimer DB 5
cookMode  DB 1
pauseFlag DB 0

.CODE

; -------------------------
; PRINT - prints DX string
; -------------------------
PRINT PROC
    MOV AH,09H
    INT 21H
    RET
PRINT ENDP

; -------------------------
; SET COLOR using INT 10H
; BL = color attribute
; -------------------------
SET_COLOR PROC
    MOV AH, 09H
    MOV AL, ' '
    MOV BH, 00H
    MOV CX, 2000
    INT 10H
    RET
SET_COLOR ENDP

; -----------------------------------------------
; DELAY_1SEC: waits approximately 1 second
; Uses INT 1AH (BIOS timer ticks, ~18.2 per sec)
; -----------------------------------------------
DELAY_1SEC PROC
    MOV AH, 00H
    INT 1AH
    MOV BX, DX
    ADD BX, 18

TICK_WAIT:
    MOV AH, 06H
    MOV DL, 0FFH
    INT 21H
    JNZ KEY_DURING_DELAY

    MOV AH, 00H
    INT 1AH
    CMP DX, BX
    JB  TICK_WAIT
    RET

KEY_DURING_DELAY:
    CMP AL, 'P'
    JE  PAUSE_DURING_DELAY
    CMP AL, 'p'
    JE  PAUSE_DURING_DELAY

    CMP AL, 'R'
    JE  RESUME_DURING_DELAY
    CMP AL, 'r'
    JE  RESUME_DURING_DELAY

    CMP AL, 'E'
    JE  EXIT_DURING_DELAY
    CMP AL, 'e'
    JE  EXIT_DURING_DELAY

    JMP TICK_WAIT

PAUSE_DURING_DELAY:
    MOV pauseFlag, 1
    RET

RESUME_DURING_DELAY:
    MOV pauseFlag, 0
    RET

EXIT_DURING_DELAY:
    MOV pauseFlag, 0
    MOV cookTimer, 0
    RET

DELAY_1SEC ENDP

MAIN PROC

    MOV AX, @DATA
    MOV DS, AX

MAIN_MENU:

    MOV AX, 0003H
    INT 10H

    ; CYAN color for menu/headings (0BH)
    MOV BL, 0BH
    CALL SET_COLOR

    LEA DX, title1
    CALL PRINT
    LEA DX, title2
    CALL PRINT
    LEA DX, title3
    CALL PRINT
    LEA DX, menu1
    CALL PRINT
    LEA DX, menu2
    CALL PRINT
    LEA DX, menu3
    CALL PRINT
    LEA DX, menu4
    CALL PRINT
    LEA DX, menu5
    CALL PRINT
    LEA DX, menu6
    CALL PRINT

    ; YELLOW color for input prompt (0EH)
    MOV BL, 0EH
    CALL SET_COLOR

    LEA DX, askMsg
    CALL PRINT

    MOV AH, 01H
    INT 21H

    CMP AL, '1'
    JE POWER_MENU
    CMP AL, '2'
    JE TEMP_MENU
    CMP AL, '3'
    JE TIMER_MENU
    CMP AL, '4'
    JE MODE_MENU
    CMP AL, '5'
    JE START_COOKING
    CMP AL, '6'
    JE EXIT_PROGRAM

    JMP MAIN_MENU

; -------------------------
; POWER
; -------------------------
POWER_MENU:
    CMP powerFlag, 0
    JE  TURN_ON

    MOV powerFlag, 0

    ; GREEN color for system status (0AH)
    MOV BL, 0AH
    CALL SET_COLOR

    LEA DX, offMsg
    CALL PRINT
    MOV AH, 01H
    INT 21H
    JMP MAIN_MENU

TURN_ON:
    MOV powerFlag, 1

    ; GREEN color for system ready (0AH)
    MOV BL, 0AH
    CALL SET_COLOR

    LEA DX, onMsg
    CALL PRINT
    MOV AH, 01H
    INT 21H
    JMP MAIN_MENU

; -------------------------
; TEMPERATURE
; -------------------------
TEMP_MENU:
    ; YELLOW color for input prompt (0EH)
    MOV BL, 0EH
    CALL SET_COLOR

    LEA DX, tempMsg
    CALL PRINT
    MOV AH, 01H
    INT 21H
    SUB AL, 48
    MOV ovenTemp, AL
    CMP ovenTemp, 3
    JA  OVERHEAT
    JMP MAIN_MENU

; -------------------------
; TIMER
; -------------------------
TIMER_MENU:
    ; YELLOW color for input prompt (0EH)
    MOV BL, 0EH
    CALL SET_COLOR

    LEA DX, timerMsg
    CALL PRINT
    MOV AH, 01H
    INT 21H
    SUB AL, 48
    MOV cookTimer, AL
    JMP MAIN_MENU

; -------------------------
; MODES
; -------------------------
MODE_MENU:
    ; YELLOW color for input prompt (0EH)
    MOV BL, 0EH
    CALL SET_COLOR

    LEA DX, modeMsg
    CALL PRINT
    MOV AH, 01H
    INT 21H

    CMP AL, '1'
    JE BAKE_MODE
    CMP AL, '2'
    JE GRILL_MODE
    CMP AL, '3'
    JE REHEAT_MODE
    JMP MAIN_MENU

BAKE_MODE:
    MOV cookMode, 1

    ; GREEN for mode selected (0AH)
    MOV BL, 0AH
    CALL SET_COLOR

    LEA DX, bakeMsg
    CALL PRINT
    MOV AH, 01H
    INT 21H
    JMP MAIN_MENU

GRILL_MODE:
    MOV cookMode, 2

    MOV BL, 0AH
    CALL SET_COLOR

    LEA DX, grillMsg
    CALL PRINT
    MOV AH, 01H
    INT 21H
    JMP MAIN_MENU

REHEAT_MODE:
    MOV cookMode, 3

    MOV BL, 0AH
    CALL SET_COLOR

    LEA DX, reheatMsg
    CALL PRINT
    MOV AH, 01H
    INT 21H
    JMP MAIN_MENU

; -------------------------
; START COOKING
; -------------------------
START_COOKING:
    CMP powerFlag, 1
    JNE MAIN_MENU

    MOV pauseFlag, 0

    ; GREEN for cooking started (0AH)
    MOV BL, 0AH
    CALL SET_COLOR

    LEA DX, startMsg
    CALL PRINT

    ; YELLOW for controls info (0EH)
    MOV BL, 0EH
    CALL SET_COLOR

    LEA DX, controlMsg
    CALL PRINT

COOK_LOOP:
    CMP cookTimer, 0
    JE  COOK_DONE

    CMP pauseFlag, 1
    JE  PAUSE_LOOP

    ; CYAN for countdown display (0BH)
    MOV BL, 0BH
    CALL SET_COLOR

    LEA DX, countMsg
    CALL PRINT

    MOV DL, cookTimer
    ADD DL, 48
    MOV AH, 02H
    INT 21H

    CALL DELAY_1SEC

    CMP cookTimer, 0
    JE  MAIN_MENU

    CMP pauseFlag, 1
    JE  COOK_LOOP

    DEC cookTimer
    JMP COOK_LOOP

; -------------------------
; PAUSE LOOP
; -------------------------
PAUSE_LOOP:
    ; YELLOW for paused state (0EH)
    MOV BL, 0EH
    CALL SET_COLOR

    LEA DX, pauseMsg
    CALL PRINT

WAIT_RESUME:
    MOV AH, 06H
    MOV DL, 0FFH
    INT 21H
    JZ  WAIT_RESUME

    CMP AL, 'R'
    JE  DO_RESUME
    CMP AL, 'r'
    JE  DO_RESUME
    CMP AL, 'E'
    JE  MAIN_MENU
    CMP AL, 'e'
    JE  MAIN_MENU
    JMP WAIT_RESUME

DO_RESUME:
    MOV pauseFlag, 0

    ; GREEN for resumed (0AH)
    MOV BL, 0AH
    CALL SET_COLOR

    LEA DX, resumeMsg
    CALL PRINT
    JMP COOK_LOOP

; -------------------------
; FINISH
; -------------------------
COOK_DONE:
    ; GREEN for cooking complete (0AH)
    MOV BL, 0AH
    CALL SET_COLOR

    LEA DX, finishMsg
    CALL PRINT

    ; 3x beep
    MOV AH, 02H
    MOV DL, 07
    INT 21H
    MOV DL, 07
    INT 21H
    MOV DL, 07
    INT 21H

    MOV AH, 01H
    INT 21H
    JMP MAIN_MENU

; -------------------------
; OVERHEAT  - RED warning
; -------------------------
OVERHEAT:
    ; RED color for error/warning (0CH)
    MOV BL, 0CH
    CALL SET_COLOR

    LEA DX, warningMsg
    CALL PRINT
    MOV AH, 01H
    INT 21H
    JMP MAIN_MENU

; -------------------------
; EXIT
; -------------------------
EXIT_PROGRAM:
    MOV AH, 4CH
    INT 21H

MAIN ENDP
END MAIN
