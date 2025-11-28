        AREA    module6_code, CODE, READONLY
        EXPORT  main

; ---------------------------------------------------------
; RAM VARIABLES
; ---------------------------------------------------------
PATIENT_RATE        EQU     0x20000200      ; daily room rate
PATIENT_DAYS        EQU     0x20000204      ; number of days
TOTAL_COST          EQU     0x20000208      ; output

DISCOUNT_THRESHOLD  EQU     10              ; if days > threshold → apply discount
DISCOUNT_PERCENT    EQU     95              ; 95% = 5% discount

; ---------------------------------------------------------
; MAIN PROGRAM
; ---------------------------------------------------------
main

        ; Load rate
        LDR     R0, =PATIENT_RATE
        LDR     R1, [R0]                    ; R1 = rate

        ; Load days
        LDR     R0, =PATIENT_DAYS
        LDR     R2, [R0]                    ; R2 = days

        ; Compute room_cost = rate * days
        MUL     R3, R1, R2                  ; R3 = cost

        ; If days <= 10 → no discount
        CMP     R2, #DISCOUNT_THRESHOLD
        BLE     STORE_RESULT

        ; Apply 5% discount:
        ; cost = cost * 95 / 100
        MOV     R4, #DISCOUNT_PERCENT
        MUL     R3, R3, R4                  ; cost * 95

        MOV     R4, #100
        UDIV    R3, R3, R4                  ; divide by 100

STORE_RESULT
        LDR     R0, =TOTAL_COST
        STR     R3, [R0]

END_LOOP
        B       END_LOOP

        END
