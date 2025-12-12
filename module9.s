; ==============================================================================
; SmartCare-32: Module 9 - Sort Patients by Criticality
; File: module9.s
; ==============================================================================

        PRESERVE8
        THUMB
        AREA    Module9Code, CODE, READONLY
        
        EXPORT  sort_patients_by_criticality

; ==============================================================================
; CONSTANTS
; ==============================================================================
PATIENT_SIZE            EQU     252
ALERT_COUNT_OFF         EQU     0x15

; ==============================================================================
; FUNCTION: sort_patients_by_criticality
; Description: Sorts patient array by alert_count (descending) using bubble sort
; Parameters:
;   R0 = Pointer to patient array
;   R1 = Number of patients (n)
; Returns: None
; Algorithm: Bubble sort - swap entire 412-byte patient structures
; ==============================================================================
sort_patients_by_criticality PROC
        PUSH    {R4-R11, LR}
        
        ; Check if n <= 1
        CMP     R1, #1
        BLE     sort_done
        
        MOV     R4, R0                  ; R4 = base address of patient_array
        MOV     R5, R1                  ; R5 = n (number of patients)
        
outer_loop
        ; swapped = false (R6 = 0)
        MOVS    R6, #0
        
        ; for (i = 0; i < n-1; i++)
        MOVS    R7, #0                  ; R7 = i
        SUBS    R8, R5, #1              ; R8 = n - 1
        
inner_loop
        CMP     R7, R8
        BGE     check_swapped
        
        ; ======================================================================
        ; Calculate addresses of patient[i] and patient[i+1]
        ; ======================================================================
        MOV     R9, R7
        MOVW    R10, #PATIENT_SIZE
        MUL     R9, R9, R10             ; R9 = i * 412
        ADD     R9, R4, R9              ; R9 = &patient[i]
        
        ADD     R10, R7, #1             ; i + 1
        MOVW    R11, #PATIENT_SIZE
        MUL     R10, R10, R11           ; R10 = (i+1) * 412
        ADD     R10, R4, R10            ; R10 = &patient[i+1]
        
        ; ======================================================================
        ; Load alert_count from patient[i] and patient[i+1]
        ; ======================================================================
        LDRB    R0, [R9, #ALERT_COUNT_OFF]      ; R0 = patient[i]. alert_count
        LDRB    R1, [R10, #ALERT_COUNT_OFF]     ; R1 = patient[i+1].alert_count
        
        ; ======================================================================
        ; Compare: if patient[i].alert_count < patient[i+1].alert_count
        ; (We want descending order: higher alert_count comes first)
        ; ======================================================================
        CMP     R0, R1
        BGE     no_swap
        
        ; ======================================================================
        ; SWAP: Exchange entire patient structures (412 bytes)
        ; We'll swap word by word (4 bytes at a time) = 103 words
        ; ======================================================================
        PUSH    {R4, R5}                ; Preserve outer loop variables
        
        MOVS    R2, #0                  ; Word counter
        MOVW    R3, #103                ; 412 / 4 = 103 words
        
swap_loop
        LDR     R4, [R9, R2]            ; Load word from patient[i]
        LDR     R5, [R10, R2]           ; Load word from patient[i+1]
        STR     R5, [R9, R2]            ; Store patient[i+1] word to patient[i]
        STR     R4, [R10, R2]           ; Store patient[i] word to patient[i+1]
        
        ADDS    R2, R2, #4              ; Move to next word
        SUBS    R3, R3, #1
        BNE     swap_loop
        
        POP     {R4, R5}                ; Restore outer loop variables
        
        ; Mark that we swapped
        MOVS    R6, #1                  ; swapped = true
        
no_swap
        ; i++
        ADDS    R7, R7, #1
        B       inner_loop
        
check_swapped
        ; If no swaps occurred, array is sorted
        CMP     R6, #0
        BEQ     sort_done
        
        ; Continue outer loop
        B       outer_loop
        
sort_done
        POP     {R4-R11, PC}
        ENDP

        ALIGN
        END