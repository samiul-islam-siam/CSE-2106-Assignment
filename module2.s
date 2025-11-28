; ==============================================================================
; SmartCare-32: Healthcare Monitoring & Billing System
; File: module2.s - Vital Sign Data Acquisition
; ARM Cortex-M4 Assembly for Keil uVision
; ==============================================================================
;
; Function: acquire_vital_signs
; Description: Reads simulated vital values (HR, BP, O2) from fixed memory
;              addresses and stores them in a rolling buffer of 10 entries
;              per patient. Implements circular buffer with modulo arithmetic.
;
; C Reference:
; void acquire_vital_signs(Patient *patient) {
;     uint8_t hr = *SENSOR_HR;
;     uint8_t o2 = *SENSOR_O2;
;     uint8_t sbp = *SENSOR_SBP;
;     uint8_t dbp = *SENSOR_DBP;
;     
;     uint8_t index = patient->vital_buffer_index;
;     patient->vital_buffer[index].heart_rate = hr;
;     patient->vital_buffer[index].oxygen_level = o2;
;     patient->vital_buffer[index].systolic_bp = sbp;
;     patient->vital_buffer[index].diastolic_bp = dbp;
;     
;     patient->vital_buffer_index = (index + 1) % 10;
; }
;
; ==============================================================================

        AREA    Module2Code, CODE, READONLY
        ALIGN   4

; ==============================================================================
; EXPORT/IMPORT DECLARATIONS
; ==============================================================================
        EXPORT  acquire_vital_signs

        ; Import sensor addresses and data from data.s
        IMPORT  SENSOR_HR
        IMPORT  SENSOR_O2
        IMPORT  SENSOR_SBP
        IMPORT  SENSOR_DBP

; ==============================================================================
; CONSTANTS - Patient Structure Offsets
; ==============================================================================
; VitalSign structure (4 bytes total):
;   heart_rate (1 byte) + oxygen_level (1 byte) + systolic_bp (1 byte) + diastolic_bp (1 byte)

VITAL_BUFFER_OFF        EQU     0x18    ; Offset to vital_buffer[10] in Patient
VITAL_BUFFER_INDEX_OFF  EQU     0x40    ; Offset to vital_buffer_index in Patient
VITAL_SIZE              EQU     4       ; Size of one VitalSign entry
BUFFER_SIZE             EQU     10      ; Circular buffer size (10 entries)

; ==============================================================================
; Function: acquire_vital_signs
; Input:  R0 = Pointer to Patient structure
; Output: None (modifies patient structure in place)
; Modifies: R0-R7
; ==============================================================================
acquire_vital_signs PROC
        PUSH    {R4-R7, LR}             ; Preserve registers as per ARM calling convention

        ; Save patient pointer for later use
        MOV     R4, R0                  ; R4 = patient pointer

        ; ======================================================================
        ; Step 1: Read vital values from simulated sensors
        ; ======================================================================
        ; Read Heart Rate from SENSOR_HR
        LDR     R0, =SENSOR_HR          ; Load address of SENSOR_HR
        LDRB    R5, [R0]                ; R5 = heart_rate (byte read)

        ; Read Oxygen Level from SENSOR_O2
        LDR     R0, =SENSOR_O2          ; Load address of SENSOR_O2
        LDRB    R6, [R0]                ; R6 = oxygen_level (byte read)

        ; Read Systolic Blood Pressure from SENSOR_SBP
        LDR     R0, =SENSOR_SBP         ; Load address of SENSOR_SBP
        LDRB    R7, [R0]                ; R7 = systolic_bp (byte read)

        ; Read Diastolic Blood Pressure from SENSOR_DBP
        LDR     R0, =SENSOR_DBP         ; Load address of SENSOR_DBP
        LDRB    R0, [R0]                ; R0 = diastolic_bp (byte read)

        ; ======================================================================
        ; Step 2: Get current buffer index from patient structure
        ; ======================================================================
        ; patient->vital_buffer_index is at offset 0x40
        ADD     R1, R4, #VITAL_BUFFER_INDEX_OFF
        LDRB    R2, [R1]                ; R2 = current index (0-9)

        ; ======================================================================
        ; Step 3: Calculate address of vital_buffer[index]
        ; Address = patient_base + VITAL_BUFFER_OFF + (index * VITAL_SIZE)
        ; ======================================================================
        LSL     R3, R2, #2              ; R3 = index * 4 (shift left 2 = multiply by 4)
        ADD     R3, R4, R3              ; R3 = patient + (index * 4)
        ADD     R3, R3, #VITAL_BUFFER_OFF ; R3 = &patient->vital_buffer[index]

        ; ======================================================================
        ; Step 4: Store vital signs in the buffer entry
        ; VitalSign structure layout:
        ;   +0: heart_rate (1 byte)
        ;   +1: oxygen_level (1 byte)
        ;   +2: systolic_bp (1 byte)
        ;   +3: diastolic_bp (1 byte)
        ; ======================================================================
        STRB    R5, [R3, #0]            ; vital_buffer[index].heart_rate = hr
        STRB    R6, [R3, #1]            ; vital_buffer[index].oxygen_level = o2
        STRB    R7, [R3, #2]            ; vital_buffer[index].systolic_bp = sbp
        STRB    R0, [R3, #3]            ; vital_buffer[index].diastolic_bp = dbp

        ; ======================================================================
        ; Step 5: Update buffer index with modulo arithmetic
        ; new_index = (index + 1) % 10
        ; Since division is expensive on Cortex-M4 without DSP, use comparison
        ; ======================================================================
        ADD     R2, R2, #1              ; R2 = index + 1
        CMP     R2, #BUFFER_SIZE        ; Compare with 10
        BLT     index_no_wrap           ; If index < 10, no wrap needed
        MOV     R2, #0                  ; Wrap around to 0
index_no_wrap
        ; Store updated index back to patient structure
        ADD     R1, R4, #VITAL_BUFFER_INDEX_OFF
        STRB    R2, [R1]                ; patient->vital_buffer_index = new_index

        ; ======================================================================
        ; Step 6: Return
        ; ======================================================================
        POP     {R4-R7, PC}             ; Restore registers and return
        ENDP

        ALIGN
        END
