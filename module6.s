#         AREA    module6_code, CODE, READONLY
#         EXPORT  main

# ; ---------------------------------------------------------
# ; RAM VARIABLES
# ; ---------------------------------------------------------
# PATIENT_RATE        EQU     0x20000200      ; daily room rate
# PATIENT_DAYS        EQU     0x20000204      ; number of days
# TOTAL_COST          EQU     0x20000208      ; output

# DISCOUNT_THRESHOLD  EQU     10              ; if days > threshold → apply discount
# DISCOUNT_PERCENT    EQU     95              ; 95% = 5% discount

# ; ---------------------------------------------------------
# ; MAIN PROGRAM
# ; ---------------------------------------------------------
# main

#         ; Load rate
#         LDR     R0, =PATIENT_RATE
#         LDR     R1, [R0]                    ; R1 = rate

#         ; Load days
#         LDR     R0, =PATIENT_DAYS
#         LDR     R2, [R0]                    ; R2 = days

#         ; Compute room_cost = rate * days
#         MUL     R3, R1, R2                  ; R3 = cost

#         ; If days <= 10 → no discount
#         CMP     R2, #DISCOUNT_THRESHOLD
#         BLE     STORE_RESULT

#         ; Apply 5% discount:
#         ; cost = cost * 95 / 100
#         MOV     R4, #DISCOUNT_PERCENT
#         MUL     R3, R3, R4                  ; cost * 95

#         MOV     R4, #100
#         UDIV    R3, R3, R4                  ; divide by 100

# STORE_RESULT
#         LDR     R0, =TOTAL_COST
#         STR     R3, [R0]

# END_LOOP
#         B       END_LOOP

#         END
        AREA    module6_code, CODE, READONLY
        ALIGN   2
        EXPORT  compute_room_cost

; Offsets from data.s (Patient structure)
BILLING_OFF             EQU     0x184
ROOM_DAILY_RATE_OFF     EQU     0x0C
STAY_DAYS_OFF           EQU     0x16
ROOM_COST_OFF           EQU     0x04

DISCOUNT_THRESHOLD      EQU     10
DISCOUNT_PERCENT        EQU     95      ; multiply by 95 then divide by 100

; void compute_room_cost(Patient *patient)
; R0 = patient pointer
compute_room_cost
        PUSH    {LR}                ; preserve return address

        ; Load room_daily_rate (uint32_t)
        LDR     R1, [R0, #ROOM_DAILY_RATE_OFF]

        ; Load stay_days (uint16_t)
        LDRH    R2, [R0, #STAY_DAYS_OFF]

        ; room_cost = rate * days  (32-bit multiply)
        MUL     R3, R1, R2          ; R3 = room_cost

        ; if (days <= 10) -> skip discount
        CMP     R2, #DISCOUNT_THRESHOLD
        BLE     .store_room_cost

        ; apply discount: room_cost = room_cost * 95 / 100
        MOV     R4, #DISCOUNT_PERCENT
        MUL     R3, R3, R4          ; R3 = cost * 95
        MOV     R4, #100
        UDIV    R3, R3, R4          ; R3 = R3 / 100

.store_room_cost
        ; store into patient->billing.room_cost
        STR     R3, [R0, #BILLING_OFF + ROOM_COST_OFF]

        POP     {PC}                ; return (BX LR)
        ALIGN   2
        END

