        AREA    module8_code, CODE, READONLY
        EXPORT  main

; ---------------------------------------------------------
; RAM VARIABLES
; ---------------------------------------------------------
TREATMENT_COST      EQU     0x20000300
ROOM_COST           EQU     0x20000304
MEDICINE_COST       EQU     0x20000308
LABTEST_COST        EQU     0x2000030C

TOTAL_BILL          EQU     0x20000310
OVERFLOW_FLAG       EQU     0x20000314      ; byte

; ---------------------------------------------------------
; MAIN PROGRAM
; ---------------------------------------------------------
main

        ; Load billing components
        LDR     R0, =TREATMENT_COST
        LDR     R1, [R0]                    ; treatment

        LDR     R0, =ROOM_COST
        LDR     R2, [R0]                    ; room

        LDR     R0, =MEDICINE_COST
        LDR     R3, [R0]                    ; medicine

        LDR     R0, =LABTEST_COST
        LDR     R4, [R0]                    ; lab tests

; ---------------------------------------------------------
; total = treatment + room
; ---------------------------------------------------------
        ADDS    R5, R1, R2
        CMP     R5, R1
        BCC     OVERFLOW

; ---------------------------------------------------------
; total += medicine
; ---------------------------------------------------------
        ADDS    R5, R5, R3
        CMP     R5, R3
        BCC     OVERFLOW

; ---------------------------------------------------------
; total += lab tests
; ---------------------------------------------------------
        ADDS    R5, R5, R4
        CMP     R5, R4
        BCC     OVERFLOW

; ---------------------------------------------------------
; SUCCESS: store total & clear overflow
; ---------------------------------------------------------
        LDR     R0, =TOTAL_BILL
        STR     R5, [R0]

        LDR     R0, =OVERFLOW_FLAG
        MOVS    R6, #0
        STRB    R6, [R0]

        B       END_LOOP

; ---------------------------------------------------------
; OVERFLOW HANDLER
; ---------------------------------------------------------
OVERFLOW
        LDR     R0, =TOTAL_BILL
        LDR     R6, =0xFFFFFFFF
        STR     R6, [R0]

        LDR     R0, =OVERFLOW_FLAG
        MOVS    R6, #1
        STRB    R6, [R0]

END_LOOP
        B       END_LOOP

        END
