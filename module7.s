        AREA 	MODULE_7, CODE, READONLY
        THUMB

MEDICINE_LIST_PTR_OFF   EQU     0x10
MEDICINE_COUNT_OFF      EQU     0x14
STAY_DAYS_OFF           EQU     0x16
BILLING_OFF             EQU     0x184
MEDICINE_COST_OFF       EQU     0x08 ;(relative to billing start)

        EXPORT  medicine_billing_module

; void compute_medicine_cost(Patient *patient)

medicine_billing_module
        PUSH    {r4-r7, lr}

        ; r0 = patient*
        LDRB    r1, [r0, #MEDICINE_COUNT_OFF]    ; r1 = medicine_count
        CMP     r1, #0
        BEQ     cmc_store_zero

        LDR     r2, [r0, #MEDICINE_LIST_PTR_OFF] ; r2 = med_list ptr
        LDRH    r3, [r0, #STAY_DAYS_OFF]         ; r3 = stay_days (uint16)

        MOVS    r4, #0               ; total_medicine_cost in r4
        MOVS    r6, #0               ; index = 0

cmc_loop
        ; med_ptr = r2 + index*16
        MOV     r5, r6
        LSL     r5, r5, #4
        ADD     r5, r2, r5

        ; load unit_price (word) -> r7
        LDR     r7, [r5, #8]

        ; load quantity (halfword) -> r8
        LDRH    r8, [r5, #12]

        ; med_cost = unit_price * quantity
        MUL     r9, r7, r8           ; r9 = product (32-bit)

        ; med_cost *= stay_days
        MUL     r9, r9, r3

        ; accumulate
        ADDS    r4, r4, r9

        ; i++
        ADDS    r6, r6, #1
        CMP     r6, r1
        BLT     cmc_loop

        ; store total into patient->billing.medicine_cost
        ; billing base = r0 + BILLING_OFF
        ADD     r11, r0, #BILLING_OFF
        STR     r4, [r11, #MEDICINE_COST_OFF]

        POP     {r4-r7, pc}

cmc_store_zero
        ; store 0 at billing.medicine_cost
        ADD     r11, r0, #BILLING_OFF
        MOVS    r4, #0
        STR     r4, [r11, #MEDICINE_COST_OFF]
        POP     {r4-r7, pc}
        ALIGN
		END
