; ==============================================================================
; SmartCare-32: Module 1 - Patient Record Initialization
; File: module1.s
; ARM Cortex-M4 Assembly for Keil uVision
; ==============================================================================

        PRESERVE8
        THUMB

        AREA    Module1Code, CODE, READONLY
        
        EXPORT  patient_record_initialization

; ==============================================================================
; CONSTANTS - Patient structure offsets
; ==============================================================================
PATIENT_ID_OFF          EQU     0x00
NAME_PTR_OFF            EQU     0x04
AGE_OFF                 EQU     0x08
TREATMENT_CODE_OFF      EQU     0x09
WARD_NUMBER_OFF         EQU     0x0A
ROOM_DAILY_RATE_OFF     EQU     0x0C
MEDICINE_LIST_PTR_OFF   EQU     0x10
MEDICINE_COUNT_OFF      EQU     0x14
ALERT_COUNT_OFF         EQU     0x15
STAY_DAYS_OFF           EQU     0x16
VITAL_BUFFER_OFF        EQU     0x18
VITAL_BUFFER_INDEX_OFF  EQU     0x40
ALERT_FLAG_OFF          EQU     0x41
DOSAGE_DUE_FLAG_OFF     EQU     0x42
ALERT_BUFFER_OFF        EQU     0x44
BILLING_OFF             EQU     0x184

; ==============================================================================
; FUNCTION: patient_record_initialization
; Description: Initialize all fields of a Patient structure
; Parameters:
;   R0 = patient pointer
;   R1 = patient_id (32-bit)
;   R2 = name pointer
;   R3 = age (8-bit)
;   Stack parameters (BEFORE any PUSH):
;     [SP+0]  = ward (16-bit)
;     [SP+4]  = treatment_code (8-bit)
;     [SP+8]  = room_rate (32-bit)
;     [SP+12] = medicine_list pointer
;     [SP+16] = medicine_count (8-bit)
;     [SP+20] = stay_days (16-bit)
; Returns: None
; ==============================================================================
patient_record_initialization PROC
        ; Load ALL stack parameters FIRST (before PUSH changes SP)
        LDR     R4, [SP, #0]        ; ward
        LDR     R5, [SP, #4]        ; treatment_code
        LDR     R6, [SP, #8]        ; room_rate
        LDR     R7, [SP, #12]       ; med_list pointer
        LDR     R8, [SP, #16]       ; med_count
        LDR     R9, [SP, #20]       ; stay_days
        
        ; NOW save registers (R4-R11 must be preserved)
        PUSH    {R4-R11, LR}
        
        ; ======================================================================
        ; Write basic patient fields
        ; ======================================================================
        STR     R1, [R0, #PATIENT_ID_OFF]           ; patient_id
        STR     R2, [R0, #NAME_PTR_OFF]             ; name_ptr
        STRB    R3, [R0, #AGE_OFF]                  ; age
        STRB    R5, [R0, #TREATMENT_CODE_OFF]       ; treatment_code
        STRH    R4, [R0, #WARD_NUMBER_OFF]          ; ward_number
        STR     R6, [R0, #ROOM_DAILY_RATE_OFF]      ; room_daily_rate
        STR     R7, [R0, #MEDICINE_LIST_PTR_OFF]    ; medicine_list_ptr
        STRB    R8, [R0, #MEDICINE_COUNT_OFF]       ; medicine_count
        STRH    R9, [R0, #STAY_DAYS_OFF]            ; stay_days
        
        ; ======================================================================
        ; Initialize counters and flags to 0
        ; ======================================================================
        MOV     R10, #0
        STRB    R10, [R0, #ALERT_COUNT_OFF]
        STRB    R10, [R0, #VITAL_BUFFER_INDEX_OFF]
        STRB    R10, [R0, #ALERT_FLAG_OFF]
        STRB    R10, [R0, #DOSAGE_DUE_FLAG_OFF]
        
        ; ======================================================================
        ; Zero billing structure (24 bytes = 6 words)
        ; ======================================================================
        ADD     R11, R0, #BILLING_OFF
        MOV     R12, #0
        STR     R12, [R11, #0]      ; treatment_cost
        STR     R12, [R11, #4]      ; room_cost
        STR     R12, [R11, #8]      ; medicine_cost
        STR     R12, [R11, #12]     ; lab_test_cost
        STR     R12, [R11, #16]     ; total_bill
        STR     R12, [R11, #20]     ; overflow_flag + padding
        
        ; ======================================================================
        ; Zero vital_buffer (40 bytes = 10 words)
        ; ======================================================================
        ADD     R11, R0, #VITAL_BUFFER_OFF
        MOV     R4, #10
zero_vitals_loop
        STR     R12, [R11], #4
        SUBS    R4, R4, #1
        BNE     zero_vitals_loop
        
        ; ======================================================================
        ; Zero alert_buffer (320 bytes = 80 words)
        ; ======================================================================
        ADD     R11, R0, #ALERT_BUFFER_OFF
        MOV     R4, #80
zero_alert_loop
        STR     R12, [R11], #4
        SUBS    R4, R4, #1
        BNE     zero_alert_loop
        
        ; Restore registers and return
        POP     {R4-R11, PC}
        ENDP

        ALIGN
        END