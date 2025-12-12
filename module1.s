; ==============================================================================
; SmartCare-32: Module 1 - Patient Record Initialization
; File: module1.s - FIXED: Don't overwrite lab_test_cost from data. s
; ==============================================================================

        PRESERVE8
        THUMB

        AREA    Module1_Code, CODE, READONLY
        
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
BILLING_OFF             EQU     0x80

; Billing offsets
TREATMENT_COST_OFF      EQU     0x00
ROOM_COST_OFF           EQU     0x04
MEDICINE_COST_OFF       EQU     0x08
LAB_TEST_COST_OFF       EQU     0x0C
TOTAL_BILL_OFF          EQU     0x10

; ==============================================================================
; FUNCTION:  patient_record_initialization
; ==============================================================================
patient_record_initialization PROC
        PUSH    {R4-R7, LR}
        
        ; Load stack parameters
        LDR     R4, [SP, #20]           ; ward
        LDR     R5, [SP, #24]           ; treatment_code
        LDR     R6, [SP, #28]           ; room_rate
        LDR     R7, [SP, #32]           ; medicine_list
        
        ; ======================================================================
        ; Write basic patient fields
        ; ======================================================================
        STR     R1, [R0, #PATIENT_ID_OFF]
        STR     R2, [R0, #NAME_PTR_OFF]
        STRB    R3, [R0, #AGE_OFF]
        STRB    R5, [R0, #TREATMENT_CODE_OFF]
        STRH    R4, [R0, #WARD_NUMBER_OFF]
        STR     R6, [R0, #ROOM_DAILY_RATE_OFF]
        STR     R7, [R0, #MEDICINE_LIST_PTR_OFF]
        
        LDR     R4, [SP, #36]           ; medicine_count
        STRB    R4, [R0, #MEDICINE_COUNT_OFF]
        
        LDR     R4, [SP, #40]           ; stay_days
        STRH    R4, [R0, #STAY_DAYS_OFF]
        
        ; ======================================================================
        ; Initialize counters and flags to 0
        ; ======================================================================
        MOV     R1, #0
        ; DON'T overwrite alert_count - it's set in data.s
        STRB    R1, [R0, #VITAL_BUFFER_INDEX_OFF]
        STRB    R1, [R0, #ALERT_FLAG_OFF]
        STRB    R1, [R0, #DOSAGE_DUE_FLAG_OFF]
        
        ; ======================================================================
        ; Zero ONLY treatment, room, medicine costs + total_bill
        ; PRESERVE lab_test_cost from data.s initialization
        ; ======================================================================
        ADD     R2, R0, #BILLING_OFF
        MOV     R3, #0
        STR     R3, [R2, #TREATMENT_COST_OFF]   ; Zero treatment_cost
        STR     R3, [R2, #ROOM_COST_OFF]        ; Zero room_cost
        STR     R3, [R2, #MEDICINE_COST_OFF]    ; Zero medicine_cost
        ; SKIP:  lab_test_cost (preserve from data.s)
        STR     R3, [R2, #TOTAL_BILL_OFF]       ; Zero total_bill
        STR     R3, [R2, #TOTAL_BILL_OFF+4]     ; Zero overflow_flag
        
        ; ======================================================================
        ; Zero vital_buffer (40 bytes = 10 words)
        ; ======================================================================
        ADD     R2, R0, #VITAL_BUFFER_OFF
        MOV     R1, #10
zero_vitals
        STR     R3, [R2], #4
        SUBS    R1, R1, #1
        BNE     zero_vitals
        
        ; ======================================================================
        ; Zero alert_buffer (60 bytes = 15 words)
        ; ======================================================================
        ADD     R2, R0, #ALERT_BUFFER_OFF
        MOV     R1, #15
zero_alerts
        STR     R3, [R2], #4
        SUBS    R1, R1, #1
        BNE     zero_alerts
        
        POP     {R4-R7, PC}
        ENDP

        ALIGN
        END
