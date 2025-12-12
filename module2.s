; ==============================================================================
; SmartCare-32: Module 2 - Vital Sign Data Acquisition
; File: module2.s
; ==============================================================================

        PRESERVE8
        THUMB

        AREA    Module2_Code, CODE, READONLY
        
        EXPORT  acquire_vital_signs

; ==============================================================================
; IMPORTS
; ==============================================================================
        IMPORT  SENSOR_HR
        IMPORT  SENSOR_O2
        IMPORT  SENSOR_SBP
        IMPORT  SENSOR_DBP

; ==============================================================================
; CONSTANTS
; ==============================================================================
VITAL_BUFFER_OFF        EQU     0x18    ; Offset to vital_buffer in Patient
VITAL_BUFFER_INDEX_OFF  EQU     0x40    ; Offset to vital_buffer_index
VITAL_SIZE              EQU     4       ; Size of VitalSign structure

; ==============================================================================
; FUNCTION: acquire_vital_signs
; Description: Reads sensor data and stores in rolling buffer (10 entries)
; Parameters:
;   R0 = Pointer to Patient structure
; Returns: None
; Modifies: R0-R7
; ==============================================================================
acquire_vital_signs PROC
        PUSH    {R4-R7, LR}             ; Preserve registers
        
        MOV     R4, R0                  ; R4 = patient pointer (preserve)
        
        ; ======================================================================
        ; STEP 1: Read sensor values
        ; ======================================================================
        LDR     R0, =SENSOR_HR
        LDRB    R5, [R0]                ; R5 = Heart Rate
        
        LDR     R0, =SENSOR_O2
        LDRB    R6, [R0]                ; R6 = Oxygen Level
        
        LDR     R0, =SENSOR_SBP
        LDRB    R7, [R0]                ; R7 = Systolic BP
        
        LDR     R0, =SENSOR_DBP
        LDRB    R3, [R0]                ; R3 = Diastolic BP
        
        ; ======================================================================
        ; STEP 2: Get current buffer index
        ; ======================================================================
        ADD     R0, R4, #VITAL_BUFFER_INDEX_OFF
        LDRB    R1, [R0]                ; R1 = current index (0-9)
        
        ; ======================================================================
        ; STEP 3: Calculate buffer position
        ; vital_buffer[index] offset = VITAL_BUFFER_OFF + (index * 4)
        ; ======================================================================
        LSL     R2, R1, #2              ; R2 = index * 4 (multiply by VITAL_SIZE)
        ADD     R2, R2, #VITAL_BUFFER_OFF ; R2 = complete offset
        ADD     R0, R4, R2              ; R0 = address of vital_buffer[index]
        
        ; ======================================================================
        ; STEP 4: Store vital signs (4 bytes)
        ; VitalSign structure:
        ;   +0: heart_rate (1 byte)
        ;   +1: oxygen_level (1 byte)
        ;   +2: systolic_bp (1 byte)
        ;   +3: diastolic_bp (1 byte)
        ; ======================================================================
        STRB    R5, [R0, #0]            ; Store heart_rate
        STRB    R6, [R0, #1]            ; Store oxygen_level
        STRB    R7, [R0, #2]            ; Store systolic_bp
        STRB    R3, [R0, #3]            ; Store diastolic_bp
        
        ; ======================================================================
        ; STEP 5: Update index with modulo 10 (rolling buffer)
        ; new_index = (index + 1) % 10
        ; ======================================================================
        ADD     R1, R1, #1              ; index = index + 1
        
        ; Modulo 10 using repeated subtraction
        CMP     R1, #10                 ; if (index >= 10)
        BLT     no_wrap
        SUB     R1, R1, #10             ;     index = index - 10
no_wrap
        ; R1 now contains (index + 1) % 10
        
        ; ======================================================================
        ; STEP 6: Store updated index
        ; ======================================================================
        ADD     R0, R4, #VITAL_BUFFER_INDEX_OFF
        STRB    R1, [R0]                ; Update vital_buffer_index
        
        POP     {R4-R7, PC}             ; Restore and return
        ENDP

        ALIGN
        END
