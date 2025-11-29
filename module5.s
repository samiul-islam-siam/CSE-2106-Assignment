; ==============================================================================
; SmartCare-32: Module 5 - Treatment Cost Computation
; File: module5.s
; ARM Cortex-M4 Assembly for Keil uVision
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
; CONSTANTS
; ==============================================================================
TREATMENT_CODE_OFF      EQU     0x09    ; Offset to treatment_code in Patient
BILLING_OFF             EQU     0x184   ; Offset to billing structure
TREATMENT_COST_OFF      EQU     0x00    ; Offset to treatment_cost in Billing

; ==============================================================================
; FUNCTION: compute_treatment_cost
; Description: Looks up treatment cost from table and stores in billing
; Parameters:
;   R0 = Pointer to Patient structure
; Returns: None
; Modifies: R0-R3
; ==============================================================================
compute_treatment_cost PROC
        PUSH    {R4-R5, LR}             ; Preserve registers
        
        MOV     R4, R0                  ; R4 = patient pointer (preserve)
        
        ; ======================================================================
        ; STEP 1: Read treatment code from patient structure
        ; ======================================================================
        ADD     R0, R4, #TREATMENT_CODE_OFF
        LDRB    R1, [R0]                ; R1 = treatment_code (0-15)
        
        ; ======================================================================
        ; STEP 2: Validate treatment code < 16
        ; ======================================================================
        CMP     R1, #16
        BHS     invalid_code            ; if (code >= 16) goto invalid_code
        
        ; ======================================================================
        ; STEP 3: Lookup cost from table
        ; treatment_cost_table[code] offset = code * 4
        ; ======================================================================
        LDR     R0, =treatment_cost_table
        LSL     R2, R1, #2              ; R2 = code * 4 (word offset)
        ADD     R0, R0, R2              ; R0 = address of table[code]
        LDR     R3, [R0]                ; R3 = cost value
        B       store_cost
        
invalid_code
        ; If code is invalid, set cost to 0
        MOV     R3, #0                  ; R3 = 0
        
store_cost
        ; ======================================================================
        ; STEP 4: Store cost in billing. treatment_cost
        ; ======================================================================
        ADD     R0, R4, #BILLING_OFF
        ADD     R0, R0, #TREATMENT_COST_OFF
        STR     R3, [R0]                ; Store treatment_cost
        
        POP     {R4-R5, PC}             ; Restore and return
        ENDP

        ALIGN
        END