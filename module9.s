; ==============================================================================
; SmartCare-32: Healthcare Monitoring & Billing System
; File: module9.s - Patient Sorting by Criticality
; ARM Cortex-M4 Assembly for Keil uVision
; ==============================================================================
;
; Function: sort_patients_by_criticality
; Description: Sorts an array of patient structures in descending order
;              based on alert_count using bubble sort algorithm.
;              Patients with more alerts are prioritized (ICU triage).
;
; C Reference:
; void sort_patients_by_criticality(Patient *patients, uint8_t count) {
;     for (uint8_t i = 0; i < count - 1; i++) {
;         for (uint8_t j = 0; j < count - i - 1; j++) {
;             if (patients[j].alert_count < patients[j + 1].alert_count) {
;                 Patient temp = patients[j];
;                 patients[j] = patients[j + 1];
;                 patients[j + 1] = temp;
;             }
;         }
;     }
; }
;
; ==============================================================================

        AREA    Module9Code, CODE, READONLY
        ALIGN   4

; ==============================================================================
; EXPORT/IMPORT DECLARATIONS
; ==============================================================================
        EXPORT  sort_patients_by_criticality

; ==============================================================================
; CONSTANTS - Patient Structure Offsets
; ==============================================================================
; Patient structure offset:
;   +0x15: alert_count (1 byte)

ALERT_COUNT_OFF         EQU     0x15    ; Offset to alert_count in Patient
PATIENT_STRUCT_SIZE     EQU     412     ; Size of Patient structure in bytes

; ==============================================================================
; Function: sort_patients_by_criticality
; Description: Bubble sort patients by alert_count (descending order)
;
; Input:  R0 = Pointer to patient array
;         R1 = Number of patients (count)
; Output: None (sorts array in place)
; Modifies: R0-R12
;
; Algorithm: Bubble Sort (descending by alert_count)
;   for i = 0 to count-2:
;       for j = 0 to count-i-2:
;           if patients[j].alert_count < patients[j+1].alert_count:
;               swap patients[j] and patients[j+1]
; ==============================================================================
sort_patients_by_criticality PROC
        PUSH    {R4-R11, LR}            ; Preserve registers

        ; Validate input: if count <= 1, nothing to sort
        CMP     R1, #2                  ; Need at least 2 patients to sort
        BLT     sort_done               ; If count < 2, exit

        ; Initialize registers
        MOV     R4, R0                  ; R4 = patients array base pointer
        MOV     R5, R1                  ; R5 = count

        ; ======================================================================
        ; Outer loop: for i = 0 to count - 2
        ; R6 = outer loop counter (i)
        ; ======================================================================
        MOV     R6, #0                  ; i = 0

outer_loop
        ; Check outer loop condition: i < count - 1
        SUB     R7, R5, #1              ; R7 = count - 1
        CMP     R6, R7
        BGE     sort_done               ; If i >= count-1, sorting complete

        ; ======================================================================
        ; Inner loop: for j = 0 to count - i - 2
        ; R8 = inner loop counter (j)
        ; ======================================================================
        MOV     R8, #0                  ; j = 0

inner_loop
        ; Calculate inner loop limit: count - i - 1
        SUB     R7, R5, R6              ; R7 = count - i
        SUB     R7, R7, #1              ; R7 = count - i - 1
        CMP     R8, R7
        BGE     inner_done              ; If j >= count-i-1, inner loop done

        ; ======================================================================
        ; Calculate addresses of patients[j] and patients[j+1]
        ; Address = base + (index * PATIENT_STRUCT_SIZE)
        ; ======================================================================
        ; Calculate patients[j] address
        MOVW    R9, #PATIENT_STRUCT_SIZE ; MOVW for 16-bit immediate (412)
        MUL     R10, R8, R9             ; R10 = j * PATIENT_STRUCT_SIZE
        ADD     R10, R4, R10            ; R10 = &patients[j]

        ; Calculate patients[j+1] address
        ADD     R11, R8, #1             ; R11 = j + 1
        MUL     R11, R11, R9            ; R11 = (j+1) * PATIENT_STRUCT_SIZE
        ADD     R11, R4, R11            ; R11 = &patients[j+1]

        ; ======================================================================
        ; Compare alert_count values
        ; if patients[j].alert_count < patients[j+1].alert_count, swap
        ; ======================================================================
        LDRB    R0, [R10, #ALERT_COUNT_OFF]  ; R0 = patients[j].alert_count
        LDRB    R1, [R11, #ALERT_COUNT_OFF]  ; R1 = patients[j+1].alert_count

        CMP     R0, R1                  ; Compare alert counts
        BGE     no_swap                 ; If patients[j] >= patients[j+1], no swap

        ; ======================================================================
        ; Swap entire patient structures
        ; Since Patient structure is large (412 bytes), we need to swap
        ; word by word (using memcpy-like logic)
        ; ======================================================================
        PUSH    {R4-R6, R8}             ; Save loop variables
        
        ; R10 = &patients[j]
        ; R11 = &patients[j+1]
        ; Swap 412 bytes using word-by-word copy
        
        MOV     R0, R10                 ; R0 = source1 (&patients[j])
        MOV     R1, R11                 ; R1 = source2 (&patients[j+1])
        MOVW    R2, #PATIENT_STRUCT_SIZE ; R2 = bytes to swap (MOVW for 16-bit)
        
        ; Swap loop: swap 4 bytes at a time
swap_loop
        CMP     R2, #0
        BLE     swap_done
        
        ; Load words from both structures
        LDR     R3, [R0]                ; R3 = temp1 from patients[j]
        LDR     R4, [R1]                ; R4 = temp2 from patients[j+1]
        
        ; Store swapped values
        STR     R4, [R0]                ; patients[j] word = patients[j+1] word
        STR     R3, [R1]                ; patients[j+1] word = patients[j] word
        
        ; Move to next word
        ADD     R0, R0, #4              ; Advance source1 pointer
        ADD     R1, R1, #4              ; Advance source2 pointer
        SUB     R2, R2, #4              ; Decrement byte counter
        
        B       swap_loop

swap_done
        POP     {R4-R6, R8}             ; Restore loop variables

no_swap
        ; ======================================================================
        ; Increment inner loop counter and continue
        ; ======================================================================
        ADD     R8, R8, #1              ; j++
        B       inner_loop

inner_done
        ; ======================================================================
        ; Increment outer loop counter and continue
        ; ======================================================================
        ADD     R6, R6, #1              ; i++
        B       outer_loop

sort_done
        POP     {R4-R11, PC}            ; Restore registers and return
        ENDP

        ALIGN
        END
