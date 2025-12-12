; ==============================================================================
; SmartCare-32: Module Integration
; File: main.s - FIXED:  Billing offset issue
; ==============================================================================

        PRESERVE8
        THUMB
        AREA    main_code, CODE, READONLY

        IMPORT  patient_record_initialization
        IMPORT  acquire_vital_signs
        IMPORT  check_vital_thresholds
        IMPORT  medicine_administration_scheduler
        IMPORT  compute_treatment_cost
        IMPORT  compute_room_cost
        IMPORT  medicine_billing_module
        IMPORT  aggregate_total_bill
        IMPORT  sort_patients_by_criticality
        IMPORT  patient_array
        IMPORT  patient1_name
        IMPORT  patient2_name
        IMPORT  patient3_name
        IMPORT  SENSOR_HR
        IMPORT  SENSOR_O2
        IMPORT  SENSOR_SBP
        IMPORT  SENSOR_DBP
        IMPORT  system_clock
        IMPORT  medicine_list_p1
        IMPORT  medicine_list_p2
        IMPORT  medicine_list_p3
		IMPORT  check_sensor_malfunction
        IMPORT  check_invalid_dosage
        IMPORT  check_memory_overflow
        IMPORT  Generate_All_Patient_Reports

        EXPORT  main

PATIENT_SIZE            EQU     152
PATIENT_ID_OFF          EQU     0x00
ALERT_COUNT_OFF         EQU     0x15

main    PROC
        MOVW    R11, #0x0001
        
        LDR     R0, =system_clock
        MOVW    R1, #0
        MOVT    R1, #0
        STR     R1, [R0]
        
        ; ======================================================================
        ; Initialize Patient 1
        ; ======================================================================
        MOV     R0, #7
        PUSH    {R0}                    ; stay_days
        MOV     R0, #3
        PUSH    {R0}                    ; medicine_count
        LDR     R0, =medicine_list_p1
        PUSH    {R0}                    ; medicine_list_ptr
        MOVW    R0, #2000
        PUSH    {R0}                    ; room_rate
        MOV     R0, #5
        PUSH    {R0}                    ; treatment_code
        MOVW    R0, #101
        PUSH    {R0}                    ; ward
        
        LDR     R0, =patient_array
        MOVW    R1, #1001
        LDR     R2, =patient1_name
        MOV     R3, #45
        BL      patient_record_initialization
        ADD     SP, SP, #24
        
        MOVW    R11, #0x0002
        
        LDR     R0, =patient_array
        BL      compute_treatment_cost
        MOVW    R11, #0x0003
        
        LDR     R0, =patient_array
        BL      compute_room_cost
        MOVW    R11, #0x0004
        
        LDR     R0, =patient_array
        BL      medicine_billing_module
        MOVW    R11, #0x0005
        
        LDR     R0, =patient_array
        BL      aggregate_total_bill
        MOVW    R11, #0x0006
        
        ; ======================================================================
        ; Initialize Patient 2
        ; ======================================================================
        MOV     R0, #12
        PUSH    {R0}                    ; stay_days
        MOV     R0, #2
        PUSH    {R0}                    ; medicine_count
        LDR     R0, =medicine_list_p2
        PUSH    {R0}                    ; medicine_list_ptr
        MOVW    R0, #5000
        PUSH    {R0}                    ; room_rate
        MOV     R0, #2
        PUSH    {R0}                    ; treatment_code
        MOVW    R0, #102
        PUSH    {R0}                    ; ward
        
        LDR     R0, =patient_array
        MOV     R10, #152              ; Use literal value
        ADD     R0, R0, R10
        MOVW    R1, #1002
        LDR     R2, =patient2_name
        MOV     R3, #32
        BL      patient_record_initialization
        ADD     SP, SP, #24
        
        MOVW    R11, #0x0007
        
        LDR     R0, =patient_array
        MOV     R10, #152
        ADD     R0, R0, R10
        BL      compute_treatment_cost
        MOVW    R11, #0x0008
        
        LDR     R0, =patient_array
        MOV     R10, #152
        ADD     R0, R0, R10
        BL      compute_room_cost
        MOVW    R11, #0x0009
        
        LDR     R0, =patient_array
        MOV     R10, #152
        ADD     R0, R0, R10
        BL      medicine_billing_module
        MOVW    R11, #0x000A
        
        LDR     R0, =patient_array
        MOV     R10, #152
        ADD     R0, R0, R10
        BL      aggregate_total_bill
        MOVW    R11, #0x000B
        
        ; ======================================================================
        ; Initialize Patient 3
        ; ======================================================================
        MOV     R0, #5
        PUSH    {R0}                    ; stay_days
        MOV     R0, #1
        PUSH    {R0}                    ; medicine_count
        LDR     R0, =medicine_list_p3
        PUSH    {R0}                    ; medicine_list_ptr
        MOVW    R0, #3000
        PUSH    {R0}                    ; room_rate
        MOV     R0, #6
        PUSH    {R0}                    ; treatment_code
        MOVW    R0, #201
        PUSH    {R0}                    ; ward
        
        LDR     R0, =patient_array
        MOV     R10, #304              ; 152 * 2
        ADD     R0, R0, R10
        MOVW    R1, #1003
        LDR     R2, =patient3_name
        MOV     R3, #67
        BL      patient_record_initialization
        ADD     SP, SP, #24
        
        MOVW    R11, #0x000C
        
        LDR     R0, =patient_array
        MOV     R10, #304
        ADD     R0, R0, R10
        BL      compute_treatment_cost
        MOVW    R11, #0x000D
        
        LDR     R0, =patient_array
        MOV     R10, #304
        ADD     R0, R0, R10
        BL      compute_room_cost
        MOVW    R11, #0x000E
        
        LDR     R0, =patient_array
        MOV     R10, #304
        ADD     R0, R0, R10
        BL      medicine_billing_module
        MOVW    R11, #0x000F
        
        LDR     R0, =patient_array
        MOV     R10, #304
        ADD     R0, R0, R10
        BL      aggregate_total_bill
        MOVW    R11, #0x0010
        
        ; ======================================================================
        ; Vitals for Patient 1 (10 readings for sensor history)
        ; ======================================================================
        MOVS    R12, #0
        
vitals_loop_p1
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
        
        MOV     R0, #0
        BL      check_sensor_malfunction
        
        LDR     R0, =system_clock
        LDR     R1, [R0]
        ADD     R1, R1, #300
        STR     R1, [R0]
        
        ADD     R12, R12, #1
        CMP     R12, #10
        BLT     vitals_loop_p1
        
        MOVW    R11, #0x0011
 
        LDR     R0, =patient_array
        BL      check_vital_thresholds
        MOVW    R11, #0x0012
        
        LDR     R0, =patient_array
        BL      medicine_administration_scheduler
        MOVW    R11, #0x0013
		
        LDR     R0, =patient_array
        MOV     R1, #0
        BL      check_invalid_dosage
        MOVW    R11, #0x0020
        
        ; ======================================================================
        ; Vitals for Patient 2
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
        MOV     R10, #152
        ADD     R0, R0, R10
        BL      acquire_vital_signs
        MOVW    R11, #0x0014
		
        MOV     R0, #1
        BL      check_sensor_malfunction
        
        LDR     R0, =patient_array
        MOV     R10, #152
        ADD     R0, R0, R10
        BL      check_vital_thresholds
        MOVW    R11, #0x0015
        
        LDR     R0, =patient_array
        MOV     R10, #152
        ADD     R0, R0, R10
        BL      medicine_administration_scheduler
        MOVW    R11, #0x0016
		
        LDR     R0, =patient_array
        MOV     R10, #152
        ADD     R0, R0, R10
        MOV     R1, #1
        BL      check_invalid_dosage
        MOVW    R11, #0x0021
        
        ; ======================================================================
        ; Vitals for Patient 3
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
        MOV     R10, #304
        ADD     R0, R0, R10
        BL      acquire_vital_signs
        MOVW    R11, #0x0017
        
        MOV     R0, #2
        BL      check_sensor_malfunction
        
        LDR     R0, =patient_array
        MOV     R10, #304
        ADD     R0, R0, R10
        BL      check_vital_thresholds
        MOVW    R11, #0x0018
        
        LDR     R0, =patient_array
        MOV     R10, #304
        ADD     R0, R0, R10
        BL      medicine_administration_scheduler
        MOVW    R11, #0x0019
        
        LDR     R0, =patient_array
        MOV     R10, #304
        ADD     R0, R0, R10
        MOV     R1, #2
        BL      check_invalid_dosage
        MOVW    R11, #0x0022
		
        ; ======================================================================
        ; Module 11c: Check memory overflow
        ; ======================================================================
        LDR     R0, =patient_array
        MOV     R1, #0
        BL      check_memory_overflow
        
        LDR     R0, =patient_array
        MOV     R10, #152
        ADD     R0, R0, R10
        MOV     R1, #1
        BL      check_memory_overflow
        
        LDR     R0, =patient_array
        MOV     R10, #304
        ADD     R0, R0, R10
        MOV     R1, #2
        BL      check_memory_overflow
        MOVW    R11, #0x0023
		
        ; ======================================================================
        ; Module 9: Sort patients
        ; ======================================================================
        LDR     R0, =patient_array
        MOV     R1, #3
        BL      sort_patients_by_criticality
        MOVW    R11, #0x001A
        
        ; ======================================================================
        ; Module 10: Generate reports
        ; ======================================================================
        MOVW    R11, #0x001B
        BL      Generate_All_Patient_Reports
        MOVW    R11, #0x001C
        
        ; Success indicator
        MOVW    R0, #0xDEAD
        MOVT    R0, #0xBEEF
        
infinite_loop
        NOP
        B       infinite_loop
        
        ENDP
        ALIGN

        END
