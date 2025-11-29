; ==============================================================================
; SmartCare-32: Complete Integration (Modules 1, 2, 3, 4 & 5)
; File: main.s
; ARM Cortex-M4 Assembly for Keil uVision
; ==============================================================================

        PRESERVE8
        THUMB
        AREA    |. text|, CODE, READONLY

        IMPORT  patient_record_initialization   ; Module 1
        IMPORT  acquire_vital_signs             ; Module 2
        IMPORT  check_vital_thresholds          ; Module 3
        IMPORT  medicine_administration_scheduler ; Module 4
        IMPORT  compute_treatment_cost          ; Module 5
        IMPORT  patient_array
        IMPORT  patient1_name
        IMPORT  patient2_name
        IMPORT  patient3_name
        IMPORT  SENSOR_HR
        IMPORT  SENSOR_O2
        IMPORT  SENSOR_SBP
        IMPORT  SENSOR_DBP
        IMPORT  system_clock

        EXPORT  main

PATIENT_SIZE            EQU     412
DOSAGE_DUE_FLAG_OFF     EQU     0x42
BILLING_OFF             EQU     0x184

main    PROC
        ; ======================================================================
        ; CHECKPOINT 1: Initialize system_clock
        ; ======================================================================
        MOVW    R11, #0x0001
        
        LDR     R0, =system_clock
        MOVW    R1, #0
        MOVT    R1, #0                  ; system_clock = 0
        STR     R1, [R0]
        
        ; ======================================================================
        ; MODULE 1: Initialize Patient 1 (John Doe)
        ; ======================================================================
        MOV     R0, #7
        PUSH    {R0}
        MOV     R0, #3
        PUSH    {R0}
        MOV     R0, #0
        PUSH    {R0}
        MOVW    R0, #2000
        PUSH    {R0}
        MOV     R0, #5
        PUSH    {R0}
        MOV     R0, #101
        PUSH    {R0}
        
        LDR     R0, =patient_array
        MOVW    R1, #1001
        LDR     R2, =patient1_name
        MOV     R3, #45
        BL      patient_record_initialization
        ADD     SP, SP, #24
        
        MOVW    R11, #0x0002            ; Patient 1 initialized
        
        ; ======================================================================
        ; MODULE 5: Compute treatment cost for Patient 1
        ; ======================================================================
        LDR     R0, =patient_array
        BL      compute_treatment_cost  ; Lookup code 5 (ICU) = 25000
        
        MOVW    R11, #0x0003            ; Patient 1 cost computed
        
        ; ======================================================================
        ; MODULE 1: Initialize Patient 2 (Jane Smith)
        ; ======================================================================
        MOV     R0, #12
        PUSH    {R0}
        MOV     R0, #2
        PUSH    {R0}
        MOV     R0, #0
        PUSH    {R0}
        MOVW    R0, #5000
        PUSH    {R0}
        MOV     R0, #2
        PUSH    {R0}
        MOV     R0, #102
        PUSH    {R0}
        
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        ADD     R0, R0, R10
        MOVW    R1, #1002
        LDR     R2, =patient2_name
        MOV     R3, #32
        BL      patient_record_initialization
        ADD     SP, SP, #24
        
        MOVW    R11, #0x0004            ; Patient 2 initialized
        
        ; ======================================================================
        ; MODULE 5: Compute treatment cost for Patient 2
        ; ======================================================================
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        ADD     R0, R0, R10
        BL      compute_treatment_cost  ; Lookup code 2 (Major surgery) = 50000
        
        MOVW    R11, #0x0005            ; Patient 2 cost computed
        
        ; ======================================================================
        ; MODULE 1: Initialize Patient 3 (Bob Wilson)
        ; ======================================================================
        MOV     R0, #5
        PUSH    {R0}
        MOV     R0, #1
        PUSH    {R0}
        MOV     R0, #0
        PUSH    {R0}
        MOVW    R0, #3000
        PUSH    {R0}
        MOV     R0, #6
        PUSH    {R0}
        MOVW    R0, #201
        PUSH    {R0}
        
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        LSL     R10, R10, #1
        ADD     R0, R0, R10
        MOVW    R1, #1003
        LDR     R2, =patient3_name
        MOV     R3, #67
        BL      patient_record_initialization
        ADD     SP, SP, #24
        
        MOVW    R11, #0x0006            ; Patient 3 initialized
        
        ; ======================================================================
        ; MODULE 5: Compute treatment cost for Patient 3
        ; ======================================================================
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        LSL     R10, R10, #1
        ADD     R0, R0, R10
        BL      compute_treatment_cost  ; Lookup code 6 (Emergency) = 30000
        
        MOVW    R11, #0x0007            ; Patient 3 cost computed
        
        ; ======================================================================
        ; MODULE 2 & 3 & 4: Patient 1
        ; ======================================================================
        LDR     R0, =SENSOR_HR
        MOV     R1, #125
        STRB    R1, [R0]
        LDR     R0, =SENSOR_O2
        MOV     R1, #88
        STRB    R1, [R0]
        LDR     R0, =SENSOR_SBP
        MOV     R1, #135
        STRB    R1, [R0]
        LDR     R0, =SENSOR_DBP
        MOV     R1, #85
        STRB    R1, [R0]
        
        LDR     R0, =patient_array
        BL      acquire_vital_signs
        MOVW    R11, #0x0008
        
        LDR     R0, =patient_array
        BL      check_vital_thresholds
        MOVW    R11, #0x0009
        
        LDR     R0, =patient_array
        BL      medicine_administration_scheduler
        MOVW    R11, #0x000A
        
        ; ======================================================================
        ; MODULE 2 & 3 & 4: Patient 2
        ; ======================================================================
        LDR     R0, =SENSOR_HR
        MOV     R1, #78
        STRB    R1, [R0]
        LDR     R0, =SENSOR_O2
        MOV     R1, #98
        STRB    R1, [R0]
        LDR     R0, =SENSOR_SBP
        MOV     R1, #120
        STRB    R1, [R0]
        LDR     R0, =SENSOR_DBP
        MOV     R1, #80
        STRB    R1, [R0]
        
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        ADD     R0, R0, R10
        BL      acquire_vital_signs
        MOVW    R11, #0x000B
        
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        ADD     R0, R0, R10
        BL      check_vital_thresholds
        MOVW    R11, #0x000C
        
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        ADD     R0, R0, R10
        BL      medicine_administration_scheduler
        MOVW    R11, #0x000D
        
        ; ======================================================================
        ; MODULE 2 & 3 & 4: Patient 3
        ; ======================================================================
        LDR     R0, =SENSOR_HR
        MOV     R1, #165
        STRB    R1, [R0]
        LDR     R0, =SENSOR_O2
        MOV     R1, #85
        STRB    R1, [R0]
        LDR     R0, =SENSOR_SBP
        MOV     R1, #170
        STRB    R1, [R0]
        LDR     R0, =SENSOR_DBP
        MOV     R1, #95
        STRB    R1, [R0]
        
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        LSL     R10, R10, #1
        ADD     R0, R0, R10
        BL      acquire_vital_signs
        MOVW    R11, #0x000E
        
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        LSL     R10, R10, #1
        ADD     R0, R0, R10
        BL      check_vital_thresholds
        MOVW    R11, #0x000F
        
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        LSL     R10, R10, #1
        ADD     R0, R0, R10
        BL      medicine_administration_scheduler
        MOVW    R11, #0x0010
        
        ; ======================================================================
        ; SUCCESS! 
        ; ======================================================================
        MOVW    R0, #0xDEAD
        MOVT    R0, #0xBEEF             ; R0 = 0xBEEFDEAD
        
infinite_loop
        NOP
        B       infinite_loop
        
        ENDP
        ALIGN
        END
