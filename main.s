; ==============================================================================
; SmartCare-32: Complete Integration (Modules 1, 2, 3 & 4)
; File: main.s
; ARM Cortex-M4 Assembly for Keil uVision
; ==============================================================================

        PRESERVE8
        THUMB
        AREA    |.text|, CODE, READONLY

        IMPORT  patient_record_initialization   ; Module 1
        IMPORT  acquire_vital_signs             ; Module 2
        IMPORT  check_vital_thresholds          ; Module 3
        IMPORT  medicine_administration_scheduler ; Module 4
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

main    PROC
        ; ======================================================================
        ; CHECKPOINT 1: Initialize system_clock
        ; ======================================================================
        MOVW    R11, #0x0001
        
        LDR     R0, =system_clock
        MOVW    R1, #0
        MOVT    R1, #0                  ; system_clock = 0 (start time)
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
        
        MOVW    R11, #0x0003            ; Patient 2 initialized
        
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
        
        MOVW    R11, #0x0004            ; All patients initialized
        
        ; ======================================================================
        ; SIMULATION CYCLE 1: Time = 0
        ; ======================================================================
        
        ; MODULE 2: Acquire Vitals for Patient 1 (Critical)
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
        
        MOVW    R11, #0x0005            ; Patient 1 vitals acquired
        
        ; MODULE 3: Check thresholds for Patient 1
        LDR     R0, =patient_array
        BL      check_vital_thresholds
        
        MOVW    R11, #0x0006            ; Patient 1 alerts checked
        
        ; MODULE 4: Check medicine schedule for Patient 1
        LDR     R0, =patient_array
        BL      medicine_administration_scheduler
        
        MOVW    R11, #0x0007            ; Patient 1 medicine checked
        
        ; MODULE 2: Acquire Vitals for Patient 2 (Stable)
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
        
        MOVW    R11, #0x0008            ; Patient 2 vitals acquired
        
        ; MODULE 3: Check thresholds for Patient 2
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        ADD     R0, R0, R10
        BL      check_vital_thresholds
        
        MOVW    R11, #0x0009            ; Patient 2 alerts checked
        
        ; MODULE 4: Check medicine schedule for Patient 2
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        ADD     R0, R0, R10
        BL      medicine_administration_scheduler
        
        MOVW    R11, #0x000A            ; Patient 2 medicine checked
        
        ; MODULE 2: Acquire Vitals for Patient 3 (Critical)
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
        
        MOVW    R11, #0x000B            ; Patient 3 vitals acquired
        
        ; MODULE 3: Check thresholds for Patient 3
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        LSL     R10, R10, #1
        ADD     R0, R0, R10
        BL      check_vital_thresholds
        
        MOVW    R11, #0x000C            ; Patient 3 alerts checked
        
        ; MODULE 4: Check medicine schedule for Patient 3
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        LSL     R10, R10, #1
        ADD     R0, R0, R10
        BL      medicine_administration_scheduler
        
        MOVW    R11, #0x000D            ; Patient 3 medicine checked
        
        ; ======================================================================
        ; ADVANCE TIME: Simulate 6 hours = 21600 seconds
        ; ======================================================================
        LDR     R0, =system_clock
        LDR     R1, [R0]
        MOVW    R2, #0x5460             ; 21600 = 0x5460
        ADD     R1, R1, R2
        STR     R1, [R0]                ; system_clock = 21600
        
        MOVW    R11, #0x000E            ; Time advanced
        
        ; ======================================================================
        ; SIMULATION CYCLE 2: Time = 21600 (6 hours later)
        ; Check if medicines are due
        ; ======================================================================
        
        ; MODULE 4: Check medicine schedule for Patient 1 (should trigger if interval <= 6h)
        LDR     R0, =patient_array
        BL      medicine_administration_scheduler
        
        MOVW    R11, #0x000F            ; Patient 1 medicine re-checked
        
        ; Check dosage_due_flag for Patient 1
        LDR     R0, =patient_array
        LDRB    R1, [R0, #DOSAGE_DUE_FLAG_OFF]
        ; R1 now contains dosage_due_flag (0 or 1)
        
        ; MODULE 4: Check medicine schedule for Patient 2
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        ADD     R0, R0, R10
        BL      medicine_administration_scheduler
        
        MOVW    R11, #0x0010            ; Patient 2 medicine re-checked
        
        ; MODULE 4: Check medicine schedule for Patient 3
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        LSL     R10, R10, #1
        ADD     R0, R0, R10
        BL      medicine_administration_scheduler
        
        MOVW    R11, #0x0011            ; Patient 3 medicine re-checked
        
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
