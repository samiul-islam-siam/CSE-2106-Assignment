; ==============================================================================
; SmartCare-32:  Module 5 - Treatment Cost Computation
; File: module5.s - FIXED: BILLING_OFF = 0x94
; ==============================================================================

        PRESERVE8
        THUMB

        AREA    Module5Code, CODE, READONLY
        
        EXPORT  compute_treatment_cost

; ==============================================================================
; IMPORTS
; ==============================================================================
        IMPORT  treatment_cost_table

; ==============================================================================
; CONSTANTS - FIXED
; ==============================================================================
TREATMENT_CODE_OFF      EQU     0x09
BILLING_OFF             EQU     0x94    ; MOVED from 0x80
TREATMENT_COST_OFF      EQU     0x00

; ==============================================================================
; FUNCTION: compute_treatment_cost
; ==============================================================================
compute_treatment_cost PROC
        PUSH    {R4-R5, LR}
        
        MOV     R4, R0
        
        ADD     R0, R4, #TREATMENT_CODE_OFF
        LDRB    R1, [R0]
        
        CMP     R1, #16
        BHS     invalid_code
        
        LDR     R0, =treatment_cost_table
        LSL     R2, R1, #2
        ADD     R0, R0, R2
        LDR     R3, [R0]
        B       store_cost
        
invalid_code
        MOV     R3, #0
        
store_cost
        ADD     R0, R4, #BILLING_OFF
        ADD     R0, R0, #TREATMENT_COST_OFF
        STR     R3, [R0]
        
        POP     {R4-R5, PC}
        ENDP

        ALIGN
        END
