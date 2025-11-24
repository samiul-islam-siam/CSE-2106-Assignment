        AREA    module6_code, CODE, READONLY
        EXPORT  main

; ---------------------------------------------------------
; RAM VARIABLES
; ---------------------------------------------------------
PATIENT_RATE        EQU     0x20000200      ; daily rate (word)
PATIENT_DAYS        EQU     0x20000204      ; number of days (word)
TOTAL_COST          EQU     0x20000208      ; computed total cost

DISCOUNT_THRESHOLD  EQU     10
DISCOUNT_PERCENT    EQU     95              ; 95% (5% discount)

; ---------------------------------------------------------
; MAIN PROGRAM
; ---------------------------------------------------------
main

		
        ; Load rate and days
        LDR     R0, =PATIENT_RATE
        LDR     R1, [R0]             ; R1 = rate
		LDR		R1, =1000;

		
        LDR     R0, =PATIENT_DAYS
        LDR     R2, [R0]             ; R2 = days
		LDR		R2, =12

        ; -------------------------------------------------
        ; room_cost = rate * days
        ; -------------------------------------------------
        MUL     R3, R1, R2           ; R3 = cost

        ; -------------------------------------------------
        ; If days <= 10 ? skip discount
        ; -------------------------------------------------
        CMP     R2, #DISCOUNT_THRESHOLD
        BLE     STORE_RESULT         ; no discount

        ; -------------------------------------------------
        ; Apply 5% discount using fixed point:
        ; cost = cost * 95 / 100
        ; -------------------------------------------------
        MOV     R4, #DISCOUNT_PERCENT
        MUL     R3, R3, R4           ; cost * 95

        MOV     R4, #100
        UDIV    R3, R3, R4           ; divide by 100

STORE_RESULT
        LDR     R0, =TOTAL_COST
        STR     R3, [R0]

DONE
        B       DONE

        END
