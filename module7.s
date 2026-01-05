; ==============================================================================
; SmartCare-32: Module 7 — Medicine Billing Module
; File: module7.s
; ==============================================================================

		AREA    Module7_code, CODE, READONLY
        THUMB

MED_ID_OFF              EQU     0x00
DOSAGE_INTERVAL_OFF     EQU     0x01
LAST_ADMIN_TIME_OFF     EQU     0x04   ; 4-byte aligned
UNIT_PRICE_OFF          EQU     0x08   ; 4-byte aligned
QUANTITY_OFF            EQU     0x0C
MED_PADDING_OFF         EQU     0x0E
MEDICINE_SIZE           EQU     0x10   ; 16 bytes total

MEDICINE_LIST_PTR_OFF   EQU     0x10
MEDICINE_COUNT_OFF      EQU     0x14
STAY_DAYS_OFF           EQU     0x16
BILLING_OFF             EQU     0xE4
MEDICINE_COST_OFF       EQU     0x08   ; (relative to billing start)

        EXPORT  medicine_billing_module

; void compute_medicine_cost(Patient *patient)
; R0 = patient*
medicine_billing_module
        PUSH    {R4-R7, LR}

        LDRB    R1, [R0, #MEDICINE_COUNT_OFF]
        CMP     R1, #0
        BEQ     cmc_zero

        LDR     R2, [R0, #MEDICINE_LIST_PTR_OFF]
        LDRH    R3, [R0, #STAY_DAYS_OFF]

        MOVS    R4, #0      ; total cost
        MOVS    R5, #0      ; index

cmc_loop
        MOV     R6, R5
        LSLS    R6, R6, #4       ; index * MEDICINE_SIZE
        ADDS    R6, R6, R2       ; med_ptr

        LDR     R7, [R6, #UNIT_PRICE_OFF]   ; aligned now
        LDRH    R6, [R6, #QUANTITY_OFF]
        MUL     R7, R7, R6
        MUL     R7, R7, R3

        ADDS    R4, R4, R7

        ADDS    R5, R5, #1
        CMP     R5, R1
        BLT     cmc_loop

        ADDS    R6, R0, #BILLING_OFF
        STR     R4, [R6, #MEDICINE_COST_OFF]

        POP     {R4-R7, PC}

cmc_zero
        ADDS    R6, R0, #BILLING_OFF
        MOVS    R4, #0
        STR     R4, [R6, #MEDICINE_COST_OFF]
        POP     {R4-R7, PC}

        ALIGN
        END
