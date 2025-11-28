; ==============================================================================
; SmartCare-32: Healthcare Monitoring & Billing System
; File: module5.s - Treatment Cost Computation
; ARM Cortex-M4 Assembly for Keil uVision
; ==============================================================================
;
; Function: compute_treatment_cost
; Description: Looks up treatment cost from a table based on treatment code
;              and stores the cost in the patient's billing structure.
;              Validates that treatment code is < 16.
;
; C Reference:
; uint32_t treatment_cost_table[16] = {
;     5000, 15000, 50000, 8000, 12000, 25000, 30000, 10000,
;     20000, 18000, 22000, 27000, 16000, 14000, 19000, 21000
; };
;
; void compute_treatment_cost(Patient *patient) {
;     uint8_t code = patient->treatment_code;
;     if (code < 16) {
;         patient->billing.treatment_cost = treatment_cost_table[code];
;     } else {
;         patient->billing.treatment_cost = 0;
;     }
; }
;
; ==============================================================================

        AREA    Module5Code, CODE, READONLY
        ALIGN   4

; ==============================================================================
; EXPORT/IMPORT DECLARATIONS
; ==============================================================================
        EXPORT  compute_treatment_cost

        ; Import treatment cost table from data.s
        IMPORT  treatment_cost_table

; ==============================================================================
; CONSTANTS - Patient Structure Offsets
; ==============================================================================
; Patient structure offsets (from data.s):
;   +0x09: treatment_code (1 byte)
;   +0x184: billing structure start
;   +0x184 + 0x00: treatment_cost (4 bytes)

TREATMENT_CODE_OFF      EQU     0x09    ; Offset to treatment_code in Patient
BILLING_OFF             EQU     0x184   ; Offset to billing structure in Patient
TREATMENT_COST_OFF      EQU     0x00    ; Offset to treatment_cost within billing

MAX_TREATMENT_CODE      EQU     16      ; Maximum valid treatment code (0-15)

; ==============================================================================
; Function: compute_treatment_cost
; Input:  R0 = Pointer to Patient structure
; Output: None (modifies patient->billing.treatment_cost in place)
; Modifies: R0-R4
; ==============================================================================
compute_treatment_cost PROC
        PUSH    {R4-R5, LR}             ; Preserve registers

        ; Save patient pointer for later use
        MOV     R4, R0                  ; R4 = patient pointer

        ; ======================================================================
        ; Step 1: Load treatment code from patient structure
        ; patient->treatment_code is at offset 0x09
        ; ======================================================================
        LDRB    R1, [R4, #TREATMENT_CODE_OFF]   ; R1 = treatment_code (byte)

        ; ======================================================================
        ; Step 2: Validate treatment code is within range (0-15)
        ; ======================================================================
        CMP     R1, #MAX_TREATMENT_CODE ; Compare with 16
        BGE     invalid_code            ; If code >= 16, it's invalid

        ; ======================================================================
        ; Step 3: Look up cost from treatment_cost_table
        ; cost = treatment_cost_table[code]
        ; Address = table_base + (code * 4) using LSL for multiply by 4
        ; ======================================================================
        LDR     R2, =treatment_cost_table       ; R2 = table base address
        LSL     R3, R1, #2              ; R3 = code * 4 (shift left by 2)
        LDR     R0, [R2, R3]            ; R0 = treatment_cost_table[code]

        ; ======================================================================
        ; Step 4: Store cost in patient's billing structure
        ; patient->billing.treatment_cost is at offset 0x184 + 0x00
        ; Use MOVW for 16-bit offset since 0x184 > 255
        ; ======================================================================
        MOVW    R5, #BILLING_OFF        ; R5 = 0x184 (388)
        ADD     R2, R4, R5              ; R2 = &patient->billing
        STR     R0, [R2, #TREATMENT_COST_OFF]   ; billing.treatment_cost = cost

        ; Return successfully
        B       compute_done

invalid_code
        ; ======================================================================
        ; Handle invalid treatment code: set cost to 0
        ; ======================================================================
        MOV     R0, #0                  ; R0 = 0
        MOVW    R5, #BILLING_OFF        ; R5 = 0x184 (388)
        ADD     R2, R4, R5              ; R2 = &patient->billing
        STR     R0, [R2, #TREATMENT_COST_OFF]   ; billing.treatment_cost = 0

compute_done
        POP     {R4-R5, PC}             ; Restore registers and return
        ENDP

        ALIGN
        END
