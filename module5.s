; =====================================================
; Module 5: Treatment Cost Computation
; ARM Cortex-M Assembly for Keil uVision
; =====================================================

    AREA    DataArea, DATA, READWRITE

; Patient Structure (32 bytes total)
; Offset 0x00-0x0F: Other patient data (16 bytes)
; Offset 0x10: Treatment code (4 bytes)
; Offset 0x14-0x1F: Additional data (12 bytes)
PatientStruct
    DCD     0, 0, 0, 0         ; Offsets 0x00-0x0F
    DCD     0x05               ; Offset 0x10: treatment_code = 0x05 (MRI)
    DCD     0, 0, 0            ; Offsets 0x14-0x1F

; Billing Structure (20 bytes total)
; Offset 0x00-0x07: Other billing data (8 bytes)
; Offset 0x08: Treatment cost (4 bytes)
; Offset 0x0C-0x13: Additional data (8 bytes)
BillingStruct
    DCD     0, 0               ; Offsets 0x00-0x07
    DCD     0                  ; Offset 0x08: treatment_cost (will be computed)
    DCD     0, 0               ; Offsets 0x0C-0x13

    AREA    TreatmentCost, CODE, READONLY
    EXPORT  main
    EXPORT  ComputeTreatmentCost

; Treatment Code to Cost Lookup Table
; Format: [Treatment_Code, Cost_Value] pairs
TreatmentTable
    DCD     0x01, 500      ; Code 01: Basic Consultation - $500
    DCD     0x02, 1200     ; Code 02: X-Ray Imaging - $1200
    DCD     0x03, 2500     ; Code 03: CT Scan - $2500
    DCD     0x04, 800      ; Code 04: Blood Test Panel - $800
    DCD     0x05, 3500     ; Code 05: MRI Scan - $3500
    DCD     0x06, 1500     ; Code 06: Ultrasound - $1500
    DCD     0x07, 5000     ; Code 07: Minor Surgery - $5000
    DCD     0x08, 15000    ; Code 08: Major Surgery - $15000
    DCD     0x09, 600      ; Code 09: Physical Therapy - $600
    DCD     0x0A, 2000     ; Code 0A: Emergency Care - $2000
    DCD     0xFF, 0        ; End marker

TABLE_SIZE EQU 10          ; Number of valid entries

; =====================================================
; Main Entry Point
; =====================================================
main
    ; Load structure addresses
    LDR     R0, =PatientStruct
    LDR     R1, =BillingStruct
    
    ; Call treatment cost computation
    BL      ComputeTreatmentCost
    
    ; Infinite loop (program end)
EndLoop
    B       EndLoop

; =====================================================
; Function: ComputeTreatmentCost
; Input:  R0 = Pointer to Patient Structure
;         R1 = Pointer to Billing Structure
; Output: R0 = Treatment cost (0 if not found)
; Modifies: R0-R5
; =====================================================
ComputeTreatmentCost
    PUSH    {R4-R5, LR}
    
    ; Load treatment code from patient structure
    ; Assuming offset 0x10 for treatment code field
    LDR     R2, [R0, #0x10]     ; R2 = treatment_code
    
    ; Initialize lookup
    LDR     R3, =TreatmentTable  ; R3 = table pointer
    MOV     R4, #0               ; R4 = loop counter
    
LookupLoop
    CMP     R4, #TABLE_SIZE      ; Check if end of table
    BGE     NotFound             ; If counter >= size, not found
    
    LDR     R5, [R3]             ; Load treatment code from table
    CMP     R5, R2               ; Compare with target code
    BEQ     FoundMatch           ; If match, retrieve cost
    
    ADD     R3, R3, #8           ; Move to next entry (2 words)
    ADD     R4, R4, #1           ; Increment counter
    B       LookupLoop
    
FoundMatch
    LDR     R0, [R3, #4]         ; Load cost value (second word)
    
    ; Store treatment cost in billing structure
    ; Assuming offset 0x08 for treatment_cost field
    STR     R0, [R1, #0x08]      ; billing->treatment_cost = cost
    
    POP     {R4-R5, PC}          ; Return with cost in R0
    
NotFound
    MOV     R0, #0               ; Return 0 if code not found
    STR     R0, [R1, #0x08]      ; Store 0 in billing structure
    
    POP     {R4-R5, PC}
    
    END
