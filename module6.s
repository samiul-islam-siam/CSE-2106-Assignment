; ==============================================================================
; SmartCare-32: Module 6 – Daily Room Rent Calculation
; File: module6.s - FIXED: BILLING_OFF = 0x80
; ==============================================================================

		AREA    Module6_code, CODE, READONLY
        ALIGN   2
        EXPORT  compute_room_cost
        THUMB

; CONSTANTS - FIXED
BILLING_OFF             EQU     0x80    ; CHANGED from 0x184
ROOM_DAILY_RATE_OFF     EQU     0x0C
STAY_DAYS_OFF           EQU     0x16
ROOM_COST_OFF           EQU     0x04

DISCOUNT_THRESHOLD      EQU     10
DISCOUNT_PERCENT        EQU     95

compute_room_cost
        PUSH    {LR}

        LDR     R1, [R0, #ROOM_DAILY_RATE_OFF]
        LDRH    R2, [R0, #STAY_DAYS_OFF]
        MUL     R3, R1, R2

        CMP     R2, #DISCOUNT_THRESHOLD
        BLE     store_room_cost

        MOV     R4, #DISCOUNT_PERCENT
        MUL     R3, R3, R4
        MOV     R4, #100
        UDIV    R3, R3, R4

store_room_cost
        STR     R3, [R0, #BILLING_OFF + ROOM_COST_OFF]

        POP     {PC}
        ALIGN   2
        END
