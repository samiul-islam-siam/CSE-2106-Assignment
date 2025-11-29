; ==============================================================================
; SmartCare-32: Module 1 - Patient Record Initialization (STACK FIX)
; File: module1. s
; ARM Cortex-M4 Assembly for Keil uVision
; ==============================================================================

        PRESERVE8
        THUMB

        AREA    Module1Code, CODE, READONLY
        
        EXPORT  patient_record_initialization

; ==============================================================================
; CONSTANTS
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
; ==============================================================================
patient_record_initialization PROC
        ; Save only what we absolutely need
        PUSH    {R4-R7, LR}             ; 5 registers × 4 = 20 bytes
        
        ; NOW load stack parameters (offset by 20 bytes)
        ; Original [SP+0] is now [SP+20]
        LDR     R4, [SP, #20]           ; ward
        LDR     R5, [SP, #24]           ; treatment_code
        LDR     R6, [SP, #28]           ; room_rate
        LDR     R7, [SP, #32]           ; medicine_list
        
        ; ======================================================================
        ; Write basic patient fields (R0-R3 are still intact)
        ; ======================================================================
        STR     R1, [R0, #PATIENT_ID_OFF]           ; patient_id
        STR     R2, [R0, #NAME_PTR_OFF]             ; name_ptr
        STRB    R3, [R0, #AGE_OFF]                  ; age
        STRB    R5, [R0, #TREATMENT_CODE_OFF]       ; treatment_code
        STRH    R4, [R0, #WARD_NUMBER_OFF]          ; ward_number
        STR     R6, [R0, #ROOM_DAILY_RATE_OFF]      ; room_daily_rate
        STR     R7, [R0, #MEDICINE_LIST_PTR_OFF]    ; medicine_list_ptr
        
        ; Load remaining stack params
        LDR     R4, [SP, #36]           ; medicine_count
        STRB    R4, [R0, #MEDICINE_COUNT_OFF]
        
        LDR     R4, [SP, #40]           ; stay_days
        STRH    R4, [R0, #STAY_DAYS_OFF]
        
        ; ======================================================================
        ; Initialize counters and flags to 0
        ; ======================================================================
        MOV     R1, #0
        STRB    R1, [R0, #ALERT_COUNT_OFF]
        STRB    R1, [R0, #VITAL_BUFFER_INDEX_OFF]
        STRB    R1, [R0, #ALERT_FLAG_OFF]
        STRB    R1, [R0, #DOSAGE_DUE_FLAG_OFF]
        
        ; ======================================================================
        ; Zero billing structure (24 bytes = 6 words)
        ; ======================================================================
        ADD     R2, R0, #BILLING_OFF
        MOV     R3, #0
        STR     R3, [R2, #0]
        STR     R3, [R2, #4]
        STR     R3, [R2, #8]
        ;STR     R3, [R2, #12]
        STR     R3, [R2, #16]
        STR     R3, [R2, #20]
        
        ; ======================================================================
        ; Zero vital_buffer (40 bytes = 10 words)
        ; ======================================================================
        ADD     R2, R0, #VITAL_BUFFER_OFF
        MOV     R1, #10
zero_vitals
        STR     R3, [R2], #4            ; Store 0, increment
        SUBS    R1, R1, #1
        BNE     zero_vitals
        
        ; ======================================================================
        ; Zero alert_buffer (320 bytes = 80 words)
        ; ======================================================================
        ADD     R2, R0, #ALERT_BUFFER_OFF
        MOV     R1, #80
zero_alerts
        STR     R3, [R2], #4
        SUBS    R1, R1, #1
        BNE     zero_alerts
        
        ; Return (LR is preserved in stack)
        POP     {R4-R7, PC}             ; Restore R4-R7, return to caller
        ENDP

        ALIGN
        END
