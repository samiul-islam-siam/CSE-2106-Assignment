        AREA    MODULE_7, CODE, READONLY
        THUMB

MED_ID_OFF             EQU     0x00
DOSAGE_INTERVAL_OFF    EQU     0x01
LAST_ADMIN_TIME_OFF    EQU     0x02
UNIT_PRICE_OFF         EQU     0x06
QUANTITY_OFF           EQU     0x0A
MED_PADDING_OFF        EQU     0x0C
MEDICINE_SIZE          EQU     0x10        ; 16 bytes

MEDICINE_LIST_PTR_OFF   EQU     0x10
MEDICINE_COUNT_OFF      EQU     0x14
STAY_DAYS_OFF           EQU     0x16
BILLING_OFF             EQU     0x184
MEDICINE_COST_OFF       EQU     0x08   ; (relative to billing start)

        EXPORT  medicine_billing_module

; void compute_medicine_cost(Patient *patient)
; r0 = patient*
medicine_billing_module
        PUSH    {r4-r7, lr}

        ; load medicine_count (uint8)
        LDRB    r1, [r0, #MEDICINE_COUNT_OFF]
        CMP     r1, #0
        BEQ     cmc_zero

        ; load medicine_list pointer
        LDR     r2, [r0, #MEDICINE_LIST_PTR_OFF]

        ; load stay_days (uint16)
        LDRH    r3, [r0, #STAY_DAYS_OFF]

        MOVS    r4, #0      ; r4 = total_medicine_cost (accumulator)
        MOVS    r5, #0      ; r5 = index

cmc_loop
        ; med_ptr = r2 + index * MEDICINE_SIZE  (MEDICINE_SIZE == 16 -> shift left 4)
        MOV     r6, r5
        LSLS    r6, r6, #4
        ADDS    r6, r6, r2      ; r6 = med_ptr

        ; load unit_price (word) into r7
        LDR     r7, [r6, #UNIT_PRICE_OFF]

        ; load quantity (halfword) into r6 (reuse med_ptr register)
        LDRH    r6, [r6, #QUANTITY_OFF]

        ; med_cost = unit_price * quantity
        MUL     r7, r7, r6      ; r7 = price * qty

        ; med_cost *= stay_days
        MUL     r7, r7, r3      ; r7 = price * qty * days

        ; accumulate total
        ADDS    r4, r4, r7

        ; index++
        ADDS    r5, r5, #1
        CMP     r5, r1
        BLT     cmc_loop

        ; store total into patient->billing.medicine_cost
        ADDS    r6, r0, #BILLING_OFF
        STR     r4, [r6, #MEDICINE_COST_OFF]

        POP     {r4-r7, pc}

cmc_zero
        ; store 0 at billing.medicine_cost
        ADDS    r6, r0, #BILLING_OFF
        MOVS    r4, #0
        STR     r4, [r6, #MEDICINE_COST_OFF]
        POP     {r4-r7, pc}

        ALIGN
        END
