; ==============================================================================
; SmartCare-32: Module 9 - Sort Patients by Criticality
; File: module9.s - FIXED: PATIENT_SIZE = 184
; ==============================================================================

        PRESERVE8
        THUMB
        AREA    Module9Code, CODE, READONLY
        
        EXPORT  sort_patients_by_criticality

; ==============================================================================
; CONSTANTS
; ==============================================================================
PATIENT_SIZE            EQU     184     ; CHANGED from 152
ALERT_COUNT_OFF         EQU     0x15

; ==============================================================================
; FUNCTION:   sort_patients_by_criticality
; ==============================================================================
sort_patients_by_criticality PROC
        PUSH    {R4-R11, LR}
        
        CMP     R1, #1
        BLE     sort_done
        
        MOV     R4, R0
        MOV     R5, R1
        
outer_loop
        MOVS    R6, #0
        MOVS    R7, #0
        SUBS    R8, R5, #1
        
inner_loop
        CMP     R7, R8
        BGE     check_swapped
        
        MOV     R9, R7
        MOVW    R10, #PATIENT_SIZE
        MUL     R9, R9, R10
        ADD     R9, R4, R9
        
        ADD     R10, R7, #1
        MOVW    R11, #PATIENT_SIZE
        MUL     R10, R10, R11
        ADD     R10, R4, R10
        
        LDRB    R0, [R9, #ALERT_COUNT_OFF]
        LDRB    R1, [R10, #ALERT_COUNT_OFF]
        
        CMP     R0, R1
        BGE     no_swap
        
        PUSH    {R4, R5}
        
        ; Swap 184 bytes = 46 words
        MOVS    R2, #0
        MOVW    R3, #46                 ; CHANGED from 38
        
swap_loop
        LDR     R4, [R9, R2]
        LDR     R5, [R10, R2]
        STR     R5, [R9, R2]
        STR     R4, [R10, R2]
        
        ADDS    R2, R2, #4
        SUBS    R3, R3, #1
        BNE     swap_loop
        
        POP     {R4, R5}
        
        MOVS    R6, #1
        
no_swap
        ADDS    R7, R7, #1
        B       inner_loop
        
check_swapped
        CMP     R6, #0
        BEQ     sort_done
        B       outer_loop
        
sort_done
        POP     {R4-R11, PC}
        ENDP

        ALIGN
        END
