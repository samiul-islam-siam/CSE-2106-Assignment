; ==============================================================================
; SmartCare-32: Healthcare Monitoring & Billing System
; File: main.s - Main Integration Program (Module 1 Only)
; ARM Cortex-M4 Assembly for Keil uVision
; ==============================================================================

        PRESERVE8
        THUMB

        AREA    |. text|, CODE, READONLY

; ==============================================================================
; IMPORTS FROM MODULE 1
; ==============================================================================
        IMPORT  patient_record_initialization

; ==============================================================================
; IMPORTS FROM DATA SECTION
; ==============================================================================
        IMPORT  patient_array
        IMPORT  patient1_name
        IMPORT  patient2_name
        IMPORT  patient3_name

; ==============================================================================
; EXPORTS
; ==============================================================================
        EXPORT  main

; ==============================================================================
; CONSTANTS
; ==============================================================================
PATIENT_SIZE    EQU     412             ; Size of each patient structure

; ==============================================================================
; MAIN ENTRY POINT - Testing Module 1
; ==============================================================================
main    PROC
        ; ======================================================================
        ; TEST MODULE 1: Initialize Patient 1 (John Doe)
        ; ======================================================================
        ; Prepare stack parameters (push in REVERSE order - last param first)
        MOV     R0, #7                  ; stay_days = 7
        PUSH    {R0}
        
        MOV     R0, #3                  ; medicine_count = 3
        PUSH    {R0}
        
        MOV     R0, #0                  ; medicine_list_ptr = NULL
        PUSH    {R0}
        
        MOV     R0, #2000               ; room_daily_rate = 2000
        PUSH    {R0}
        
        MOV     R0, #5                  ; treatment_code = 5 (ICU)
        PUSH    {R0}
        
        MOV     R0, #101                ; ward_number = 101
        PUSH    {R0}
        
        ; Prepare register parameters
        LDR     R0, =patient_array      ; R0 = patient pointer
        MOV     R1, #1001               ; R1 = patient_id = 1001
        MOVW    R1, #1001               ; Use MOVW for clarity
        LDR     R2, =patient1_name      ; R2 = name pointer
        MOV     R3, #45                 ; R3 = age = 45
        
        ; Call initialization function
        BL      patient_record_initialization
        
        ; Clean up stack (6 parameters × 4 bytes = 24 bytes)
        ADD     SP, SP, #24
        
        ; ======================================================================
        ; TEST MODULE 1: Initialize Patient 2 (Jane Smith)
        ; ======================================================================
        ; Push stack parameters for Patient 2
        MOV     R0, #12                 ; stay_days = 12
        PUSH    {R0}
        
        MOV     R0, #2                  ; medicine_count = 2
        PUSH    {R0}
        
        MOV     R0, #0                  ; medicine_list_ptr = NULL
        PUSH    {R0}
        
        MOV     R0, #5000               ; room_daily_rate = 5000
        PUSH    {R0}
        
        MOV     R0, #2                  ; treatment_code = 2 (Major surgery)
        PUSH    {R0}
        
        MOV     R0, #102                ; ward_number = 102
        PUSH    {R0}
        
        ; Register parameters for Patient 2
        LDR     R0, =patient_array
        ADD     R0, R0, #PATIENT_SIZE   ; R0 = &patient_array[1]
        MOVW    R1, #1002               ; patient_id = 1002
        LDR     R2, =patient2_name
        MOV     R3, #32                 ; age = 32
        
        BL      patient_record_initialization
        
        ; Clean up stack
        ADD     SP, SP, #24
        
        ; ======================================================================
        ; TEST MODULE 1: Initialize Patient 3 (Bob Wilson)
        ; ======================================================================
        ; Push stack parameters for Patient 3
        MOV     R0, #5                  ; stay_days = 5
        PUSH    {R0}
        
        MOV     R0, #1                  ; medicine_count = 1
        PUSH    {R0}
        
        MOV     R0, #0                  ; medicine_list_ptr = NULL
        PUSH    {R0}
        
        MOV     R0, #3000               ; room_daily_rate = 3000
        PUSH    {R0}
        
        MOV     R0, #6                  ; treatment_code = 6 (Emergency)
        PUSH    {R0}
        
        MOV     R0, #201                ; ward_number = 201
        PUSH    {R0}
        
        ; Register parameters for Patient 3
        LDR     R0, =patient_array
        MOV     R1, #PATIENT_SIZE
        LSL     R1, R1, #1              ; R1 = PATIENT_SIZE * 2
        ADD     R0, R0, R1              ; R0 = &patient_array[2]
        MOVW    R1, #1003               ; patient_id = 1003
        LDR     R2, =patient3_name
        MOV     R3, #67                 ; age = 67
        
        BL      patient_record_initialization
        
        ; Clean up stack
        ADD     SP, SP, #24
        
        ; ======================================================================
        ; ALL THREE PATIENTS INITIALIZED!
        ; You can now inspect memory at patient_array to verify
        ; ======================================================================
        
        ; Set a marker value in R0 to indicate success
        MOVW    R0, #0xAAAA
        MOVT    R0, #0x5555             ; R0 = 0x5555AAAA (success marker)
        
        ; ======================================================================
        ; INFINITE LOOP - Stay here for debugging
        ; ======================================================================
infinite_loop
        NOP                             ; Breakpoint here to check memory
        NOP
        B       infinite_loop
        
        ENDP

        ALIGN
        END