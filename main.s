; ==============================================================================
; SmartCare-32: Healthcare Monitoring & Billing System
; File: main.s - Main Integration Program
; ARM Cortex-M4 Assembly for Keil uVision
; ==============================================================================
;
; Description: Main program that integrates all modules and demonstrates
;              the SmartCare-32 system functionality:
;              - Module 2: Vital Sign Data Acquisition
;              - Module 5: Treatment Cost Computation
;              - Module 9: Patient Sorting by Criticality
;
; System Flow:
;   1. Initialize system
;   2. Set up simulated sensor values
;   3. For each patient:
;      a. Acquire vital signs (Module 2) - 10 times to fill buffer
;      b. Compute treatment cost (Module 5)
;   4. Sort patients by criticality (Module 9)
;   5. Enter infinite loop (system ready state)
;
; ==============================================================================

        AREA    MainCode, CODE, READONLY
        ALIGN   4

; ==============================================================================
; IMPORT DECLARATIONS - External Functions and Data
; ==============================================================================
        ; Module functions
        IMPORT  acquire_vital_signs         ; From module2.s
        IMPORT  compute_treatment_cost      ; From module5.s
        IMPORT  sort_patients_by_criticality ; From module9.s

        ; Data from data.s
        IMPORT  patient_array
        IMPORT  patient_count
        IMPORT  SENSOR_HR
        IMPORT  SENSOR_O2
        IMPORT  SENSOR_SBP
        IMPORT  SENSOR_DBP
        IMPORT  system_clock

; ==============================================================================
; CONSTANTS
; ==============================================================================
PATIENT_SIZE            EQU     412     ; Size of Patient structure in bytes
VITAL_ACQUISITIONS      EQU     10      ; Number of times to acquire vitals

; Simulated sensor values for 3 patients
; Patient 1 (John): High HR, Low O2 - Critical
; Patient 2 (Jane): Normal values - Stable
; Patient 3 (Bob): Critical HR, Critical O2, High BP - Most Critical

; ==============================================================================
; ENTRY POINT
; ==============================================================================
        EXPORT  __main
        ENTRY

__main  PROC
        ; ======================================================================
        ; System Initialization
        ; ======================================================================
        ; Initialize stack pointer (typically done by startup code)
        ; LDR     SP, =__initial_sp       ; Uncomment if needed

        ; Initialize system clock to 0
        LDR     R0, =system_clock
        MOV     R1, #0
        STR     R1, [R0]

        ; ======================================================================
        ; Process Patient 1 (John Doe)
        ; Treatment code: 5 (ICU admission), Expected cost: 25000
        ; Simulated vitals: HR=125, O2=88, SBP=135, DBP=85
        ; ======================================================================
        ; Set up sensor values for Patient 1
        LDR     R0, =SENSOR_HR
        MOV     R1, #125                ; High heart rate (triggers alert)
        STRB    R1, [R0]
        
        LDR     R0, =SENSOR_O2
        MOV     R1, #88                 ; Low oxygen (triggers alert)
        STRB    R1, [R0]
        
        LDR     R0, =SENSOR_SBP
        MOV     R1, #135                ; Normal systolic BP
        STRB    R1, [R0]
        
        LDR     R0, =SENSOR_DBP
        MOV     R1, #85                 ; Normal diastolic BP
        STRB    R1, [R0]

        ; Get Patient 1 address
        LDR     R4, =patient_array      ; R4 = base of patient array

        ; Acquire vital signs 10 times to fill the buffer
        MOV     R5, #VITAL_ACQUISITIONS
patient1_vitals_loop
        MOV     R0, R4                  ; R0 = &patients[0]
        BL      acquire_vital_signs
        
        ; Increment system clock (simulate 5 minutes = 300 seconds)
        LDR     R0, =system_clock
        LDR     R1, [R0]
        ADD     R1, R1, #300
        STR     R1, [R0]
        
        SUBS    R5, R5, #1
        BNE     patient1_vitals_loop

        ; Compute treatment cost for Patient 1
        MOV     R0, R4                  ; R0 = &patients[0]
        BL      compute_treatment_cost

        ; ======================================================================
        ; Process Patient 2 (Jane Smith)
        ; Treatment code: 2 (Major surgery), Expected cost: 50000
        ; Simulated vitals: HR=78, O2=98, SBP=120, DBP=80 (all normal)
        ; ======================================================================
        ; Set up sensor values for Patient 2
        LDR     R0, =SENSOR_HR
        MOV     R1, #78                 ; Normal heart rate
        STRB    R1, [R0]
        
        LDR     R0, =SENSOR_O2
        MOV     R1, #98                 ; Normal oxygen
        STRB    R1, [R0]
        
        LDR     R0, =SENSOR_SBP
        MOV     R1, #120                ; Normal systolic BP
        STRB    R1, [R0]
        
        LDR     R0, =SENSOR_DBP
        MOV     R1, #80                 ; Normal diastolic BP
        STRB    R1, [R0]

        ; Get Patient 2 address (patient_array + PATIENT_SIZE)
        LDR     R4, =patient_array
        MOVW    R6, #PATIENT_SIZE       ; MOVW for 16-bit immediate (412)
        ADD     R4, R4, R6              ; R4 = &patients[1]

        ; Acquire vital signs 10 times
        MOV     R5, #VITAL_ACQUISITIONS
patient2_vitals_loop
        MOV     R0, R4                  ; R0 = &patients[1]
        BL      acquire_vital_signs
        
        ; Increment system clock
        LDR     R0, =system_clock
        LDR     R1, [R0]
        ADD     R1, R1, #300
        STR     R1, [R0]
        
        SUBS    R5, R5, #1
        BNE     patient2_vitals_loop

        ; Compute treatment cost for Patient 2
        MOV     R0, R4                  ; R0 = &patients[1]
        BL      compute_treatment_cost

        ; ======================================================================
        ; Process Patient 3 (Bob Wilson)
        ; Treatment code: 6 (Emergency care), Expected cost: 30000
        ; Simulated vitals: HR=165, O2=85, SBP=170, DBP=95 (most critical)
        ; ======================================================================
        ; Set up sensor values for Patient 3
        LDR     R0, =SENSOR_HR
        MOV     R1, #165                ; Critical heart rate
        STRB    R1, [R0]
        
        LDR     R0, =SENSOR_O2
        MOV     R1, #85                 ; Critical oxygen
        STRB    R1, [R0]
        
        LDR     R0, =SENSOR_SBP
        MOV     R1, #170                ; High systolic BP
        STRB    R1, [R0]
        
        LDR     R0, =SENSOR_DBP
        MOV     R1, #95                 ; High diastolic BP
        STRB    R1, [R0]

        ; Get Patient 3 address (patient_array + 2 * PATIENT_SIZE)
        LDR     R4, =patient_array
        MOVW    R6, #PATIENT_SIZE       ; MOVW for 16-bit immediate (412)
        ADD     R4, R4, R6              ; R4 = &patients[1]
        ADD     R4, R4, R6              ; R4 = &patients[2]

        ; Acquire vital signs 10 times
        MOV     R5, #VITAL_ACQUISITIONS
patient3_vitals_loop
        MOV     R0, R4                  ; R0 = &patients[2]
        BL      acquire_vital_signs
        
        ; Increment system clock
        LDR     R0, =system_clock
        LDR     R1, [R0]
        ADD     R1, R1, #300
        STR     R1, [R0]
        
        SUBS    R5, R5, #1
        BNE     patient3_vitals_loop

        ; Compute treatment cost for Patient 3
        MOV     R0, R4                  ; R0 = &patients[2]
        BL      compute_treatment_cost

        ; ======================================================================
        ; Sort Patients by Criticality (Module 9)
        ; After sorting, order should be: Bob (5 alerts), John (2 alerts), Jane (0 alerts)
        ; ======================================================================
        LDR     R0, =patient_array      ; R0 = patients array
        MOV     R1, #3                  ; R1 = number of patients
        BL      sort_patients_by_criticality

        ; ======================================================================
        ; System Ready - Enter Infinite Loop
        ; In a real system, this would be replaced with a main processing loop
        ; that handles interrupts, updates displays, etc.
        ; ======================================================================
system_ready
        B       system_ready            ; Infinite loop

        ENDP

; ==============================================================================
; Stack Configuration (for standalone operation)
; ==============================================================================
        AREA    STACK, NOINIT, READWRITE, ALIGN=3
stack_mem       SPACE   0x400           ; 1KB stack
__initial_sp

        END
