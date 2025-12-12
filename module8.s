; ==============================================================================
; SmartCare-32: Module 8 — Patient Bill Aggregator
; File: module8.s
; ==============================================================================


		AREA    Module8_code, CODE, READONLY
        ALIGN   2
        EXPORT  aggregate_total_bill

; Billing offsets relative to billing start (from data.s)
BILLING_OFF             EQU     0xE4
TREATMENT_COST_OFF      EQU     0x00
ROOM_COST_OFF           EQU     0x04
MEDICINE_COST_OFF       EQU     0x08
LAB_TEST_COST_OFF       EQU     0x0C
TOTAL_BILL_OFF          EQU     0x10
OVERFLOW_FLAG_OFF       EQU     0x14

; void aggregate_total_bill(Patient *patient)
; R0 = patient pointer
aggregate_total_bill
        PUSH    {LR}                ; preserve return address

        ; Load billing fields (unsigned 32-bit)
        LDR     R1, [R0, #BILLING_OFF + TREATMENT_COST_OFF]   ; treatment
        LDR     R2, [R0, #BILLING_OFF + ROOM_COST_OFF]        ; room
        LDR     R3, [R0, #BILLING_OFF + MEDICINE_COST_OFF]    ; medicine
        LDR     R4, [R0, #BILLING_OFF + LAB_TEST_COST_OFF]    ; lab tests

        ; total = treatment + room
        ADDS    R5, R1, R2
        CMP     R5, R1
        BCC     overflow_detected

        ; total += medicine
        ADDS    R5, R5, R3
        CMP     R5, R3
        BCC     overflow_detected

        ; total += lab tests
        ADDS    R5, R5, R4
        CMP     R5, R4
        BCC     overflow_detected

        ; no overflow: store total and clear overflow flag
        STR     R5, [R0, #BILLING_OFF + TOTAL_BILL_OFF]
        MOVS    R6, #0
        STRB    R6, [R0, #BILLING_OFF + OVERFLOW_FLAG_OFF]
        B       done

overflow_detected
        ; set total_bill = 0xFFFFFFFF
        LDR     R6, =0xFFFFFFFF
        STR     R6, [R0, #BILLING_OFF + TOTAL_BILL_OFF]

        ; set overflow_flag = 1
        MOVS    R6, #1
        STRB    R6, [R0, #BILLING_OFF + OVERFLOW_FLAG_OFF]

done
        POP     {PC}                ; return
        ALIGN   2
        END