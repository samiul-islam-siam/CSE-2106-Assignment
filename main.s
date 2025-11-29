; ==============================================================================
; SmartCare-32: Complete Integration (Modules 1 & 2)
; File: main.s
; ARM Cortex-M4 Assembly for Keil uVision
; ==============================================================================

        PRESERVE8
        THUMB
        AREA    |. text|, CODE, READONLY

        IMPORT  patient_record_initialization
        IMPORT  acquire_vital_signs
        IMPORT  patient_array
        IMPORT  patient1_name
        IMPORT  patient2_name
        IMPORT  patient3_name
        IMPORT  SENSOR_HR
        IMPORT  SENSOR_O2
        IMPORT  SENSOR_SBP
        IMPORT  SENSOR_DBP

        EXPORT  main

PATIENT_SIZE    EQU     412

main    PROC
        ; ======================================================================
        ; CHECKPOINT 1: Start
        ; ======================================================================
        MOVW    R11, #0x0001
        
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
        
        MOVW    R11, #0x0002            ; Checkpoint: Patient 1 initialized
        
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
        
        MOVW    R11, #0x0003            ; Checkpoint: Patient 2 initialized
        
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
        
        MOVW    R11, #0x0004            ; Checkpoint: All patients initialized
        
        ; ======================================================================
        ; MODULE 2: Acquire Vitals for Patient 1 (Critical)
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
        
        MOVW    R11, #0x0005            ; Checkpoint: Patient 1 vitals acquired
        
        ; ======================================================================
        ; MODULE 2: Acquire Vitals for Patient 2 (Stable)
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
        
        MOVW    R11, #0x0006            ; Checkpoint: Patient 2 vitals acquired
        
        ; ======================================================================
        ; MODULE 2: Acquire Vitals for Patient 3 (Critical)
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
        
        MOVW    R11, #0x0007            ; Checkpoint: All vitals acquired
        
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
