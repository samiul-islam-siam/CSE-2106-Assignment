; ==============================================================================
; SmartCare-32: Module 8 – Patient Bill Aggregator
; File: module8.s - FIXED: BILLING_OFF = 0x80
; ==============================================================================

		AREA    Module8_code, CODE, READONLY
        ALIGN   2
        EXPORT  aggregate_total_bill
        THUMB

; CONSTANTS - FIXED
BILLING_OFF             EQU     0x80    ; CHANGED from 0x184
TREATMENT_COST_OFF      EQU     0x00
ROOM_COST_OFF           EQU     0x04
MEDICINE_COST_OFF       EQU     0x08
LAB_TEST_COST_OFF       EQU     0x0C
TOTAL_BILL_OFF          EQU     0x10
OVERFLOW_FLAG_OFF       EQU     0x14

aggregate_total_bill
        PUSH    {LR}

        LDR     R1, [R0, #BILLING_OFF + TREATMENT_COST_OFF]
        LDR     R2, [R0, #BILLING_OFF + ROOM_COST_OFF]
        LDR     R3, [R0, #BILLING_OFF + MEDICINE_COST_OFF]
        LDR     R4, [R0, #BILLING_OFF + LAB_TEST_COST_OFF]

        ADDS    R5, R1, R2
        BCS     overflow_detected

        ADDS    R5, R5, R3
        BCS     overflow_detected

        ADDS    R5, R5, R4
        BCS     overflow_detected

        STR     R5, [R0, #BILLING_OFF + TOTAL_BILL_OFF]
        MOVS    R6, #0
        STRB    R6, [R0, #BILLING_OFF + OVERFLOW_FLAG_OFF]
        B       done

overflow_detected
        LDR     R6, =0xFFFFFFFF
        STR     R6, [R0, #BILLING_OFF + TOTAL_BILL_OFF]

        MOVS    R6, #1
        STRB    R6, [R0, #BILLING_OFF + OVERFLOW_FLAG_OFF]

done
        POP     {PC}
        ALIGN   2
        END
