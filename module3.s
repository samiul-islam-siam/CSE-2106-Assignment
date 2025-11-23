        AREA    module3_code, CODE, READONLY
        EXPORT  main
        THUMB

; ---------------------------------------------------------
; RAM LOCATIONS (BUFFER + VARIABLES)
; ---------------------------------------------------------
ALERT_FLAG          EQU     0x20000000      ; 1-byte alert flag
ALERT_WRITE_INDEX   EQU     0x20000004      ; word index
ALERT_BUFFER_BASE   EQU     0x20000100      ; buffer start
ALERT_RECORD_SIZE   EQU     16              ; 16 bytes per record
ALERT_BUFFER_COUNT  EQU     32              ; total 32 records

; Timestamp counter
TIME_COUNTER        EQU     0x20000020      ; word increments per reading

; ---------------------------------------------------------
; INPUT VITALS (TEST VALUES)
; ---------------------------------------------------------
HR_VALUE        EQU     130     ; >120 triggers alert
O2_VALUE        EQU     90      ; <92 triggers alert
SBP_VALUE       EQU     170     ; >160 triggers alert

; ---------------------------------------------------------
; MAIN PROGRAM
; ---------------------------------------------------------
main

        ; Load vitals into registers
        MOV     R0, #HR_VALUE
        MOV     R1, #O2_VALUE
        MOV     R2, #SBP_VALUE

        ; Load timestamp
        LDR     R3, =TIME_COUNTER
        LDR     R3, [R3]

        ; Optional: increment timestamp for next reading
        ADD     R3, R3, #1
        LDR     R12, =TIME_COUNTER
        STR     R3, [R12]

        ; -----------------------------
        ; CHECK HEART RATE
        ; -----------------------------
        CMP     R0, #120
        BLE     SKIP_HR
        MOV     R4, #1          ; Vital type = HR
        MOV     R5, R0          ; Reading
        BL      CREATE_RECORD
SKIP_HR

        ; -----------------------------
        ; CHECK OXYGEN
        ; -----------------------------
        CMP     R1, #92
        BGE     SKIP_O2
        MOV     R4, #2          ; Vital type = O2
        MOV     R5, R1
        BL      CREATE_RECORD
SKIP_O2

        ; -----------------------------
        ; CHECK SYSTOLIC BP
        ; -----------------------------
        CMP     R2, #160
        BLE     CHECK_SBP_LOW
        MOV     R4, #3          ; Vital type = SBP
        MOV     R5, R2
        BL      CREATE_RECORD
        B       DONE

CHECK_SBP_LOW
        CMP     R2, #90
        BGE     DONE
        MOV     R4, #3
        MOV     R5, R2
        BL      CREATE_RECORD

DONE
        B       DONE            ; Infinite loop

; ---------------------------------------------------------
; CREATE RECORD SUBROUTINE
; Input: R4 = vital type, R5 = reading, R3 = timestamp
; ---------------------------------------------------------
CREATE_RECORD

        ; Set ALERT_FLAG = 1
        LDR     R6, =ALERT_FLAG
        MOV     R7, #1
        STRB    R7, [R6]

        ; Load write index
        LDR     R6, =ALERT_WRITE_INDEX
        LDR     R7, [R6]               ; R7 = index

        ; Compute destination address: base + index * 16
        LDR     R8, =ALERT_BUFFER_BASE
        ADD     R8, R8, R7, LSL #4

        ; -----------------------------
        ; STORE FIELDS INTO RECORD
        ; -----------------------------
        ; Byte 0: Vital type
        STRB    R4, [R8, #0]

        ; Byte 1-2: Reading (16-bit)
        STRH    R5, [R8, #1]

        ; Byte 3-6: Timestamp (32-bit)
        STR     R3, [R8, #3]

        ; Bytes 7-15: Zero remaining
        MOVS    R9, #0
        STR     R9, [R8, #7]      ; bytes 7-10
        STR     R9, [R8, #11]     ; bytes 11-14
        MOVS    R10, #0
        STRB    R10, [R8, #15]    ; byte 15

        ; -----------------------------
        ; UPDATE WRITE INDEX (ring buffer)
        ; -----------------------------
        ADD     R7, R7, #1
        CMP     R7, #ALERT_BUFFER_COUNT
        BLT     STORE_INDEX
        MOV     R7, #0
STORE_INDEX
        STR     R7, [R6]

        BX      LR                ; Return

        END
