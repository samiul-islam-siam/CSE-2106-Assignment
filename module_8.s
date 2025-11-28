        AREA    module8_code, CODE, READONLY
        EXPORT  main

; ---------------------------------------------------------
; RAM VARIABLES (simulate Patient.billing section)
; ---------------------------------------------------------
TREATMENT_COST      EQU     0x20000300      ; word
ROOM_COST           EQU     0x20000304      ; word
MEDICINE_COST       EQU     0x20000308      ; word
LABTEST_COST        EQU     0x2000030C      ; word

TOTAL_BILL          EQU     0x20000310      ; word
OVERFLOW_FLAG       EQU     0x20000314      ; byte

; ---------------------------------------------------------
; MAIN PROGRAM — standalone Module 8
; ---------------------------------------------------------
main

        ; ---------------------------------------------
        ; Load the 4 billing components into registers
        ; ---------------------------------------------

        ; treatment
        LDR     R0, =TREATMENT_COST
        LDR     R1, [R0]                       ; R1 = treatment
        ; Example inject value:
        LDR     R1, =5000

        ; room
        LDR     R0, =ROOM_COST
        LDR     R2, [R0]                       ; R2 = room
        ; Example inject:
        LDR     R2, =7000

        ; medicine
        LDR     R0, =MEDICINE_COST
        LDR     R3, [R0]                       ; R3 = medicine
        ; Example inject:
        LDR     R3, =3000

        ; lab tests
        LDR     R0, =LABTEST_COST
        LDR     R4, [R0]                       ; R4 = labtests
        ; Example inject:
        LDR     R4, =2000


; ---------------------------------------------------------
; total = treatment + room
; ---------------------------------------------------------
        ADDS    R5, R1, R2
        CMP     R5, R1
        BCC     OVERFLOW           ; overflow occurred


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
; SUCCESS — store total_bill and clear overflow flag
; ---------------------------------------------------------
        LDR     R0, =TOTAL_BILL
        STR     R5, [R0]

        LDR     R0, =OVERFLOW_FLAG
        MOVS    R6, #0
        STRB    R6, [R0]

        B       DONE


; ---------------------------------------------------------
; OVERFLOW HANDLING
; ---------------------------------------------------------
OVERFLOW
        ; total_bill = 0xFFFFFFFF
        LDR     R0, =TOTAL_BILL
        LDR     R6, =0xFFFFFFFF
        STR     R6, [R0]

        ; overflow_flag = 1
        LDR     R0, =OVERFLOW_FLAG
        MOVS    R6, #1
        STRB    R6, [R0]


; ---------------------------------------------------------
; END OF PROGRAM LOOP
; ---------------------------------------------------------
DONE
        B       DONE

        END
