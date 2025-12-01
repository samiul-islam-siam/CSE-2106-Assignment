; ==============================================================================
; SmartCare-32: Module 11 - System Error Detection & Logging
; File: module11.s
; ARM Cortex-M4 Assembly for Keil uVision
; ==============================================================================

        PRESERVE8
        THUMB
        AREA    Module11Code, CODE, READONLY
        
        EXPORT  check_sensor_malfunction
        EXPORT  check_invalid_dosage
        EXPORT  check_memory_overflow
        EXPORT  log_error_to_flash
        EXPORT  get_error_count

; ==============================================================================
; IMPORTS
; ==============================================================================
        IMPORT  system_clock
        IMPORT  error_flag
        IMPORT  error_log_buffer
        IMPORT  error_count
        IMPORT  sensor_history
        IMPORT  sensor_history_index
        IMPORT  SENSOR_HR
        IMPORT  SENSOR_O2
        IMPORT  SENSOR_SBP
        IMPORT  SENSOR_DBP

; ==============================================================================
; CONSTANTS
; ==============================================================================
ERROR_SENSOR_MALFUNCTION    EQU     0x01
ERROR_INVALID_DOSAGE        EQU     0x02
ERROR_MEMORY_OVERFLOW       EQU     0x03

ERROR_RECORD_SIZE           EQU     16
MAX_ERROR_RECORDS           EQU     50

MEDICINE_LIST_PTR_OFF       EQU     0x10
MEDICINE_COUNT_OFF          EQU     0x14
UNIT_PRICE_OFF              EQU     0x08
QUANTITY_OFF                EQU     0x0C
MEDICINE_SIZE               EQU     0x10

PATIENT_ARRAY_MAX           EQU     0x20000100  ; Safe upper boundary
BILLING_OFF                 EQU     0x184
TOTAL_BILL_OFF              EQU     0x10

; ==============================================================================
; FUNCTION: check_sensor_malfunction
; Description: Detects if same sensor value repeated > 10 times
; Parameters:
;   R0 = patient index (0-2)
; Returns: 
;   R0 = 1 if malfunction detected, 0 otherwise
; ==============================================================================
check_sensor_malfunction PROC
        PUSH    {R4-R11, LR}
        
        MOV     R10, R0                 ; Save patient index
        
        ; ======================================================================
        ; Read current sensor values
        ; ======================================================================
        LDR     R0, =SENSOR_HR
        LDRB    R4, [R0]                ; R4 = current HR
        
        LDR     R0, =SENSOR_O2
        LDRB    R5, [R0]                ; R5 = current O2
        
        LDR     R0, =SENSOR_SBP
        LDRB    R6, [R0]                ; R6 = current SBP
        
        LDR     R0, =SENSOR_DBP
        LDRB    R7, [R0]                ; R7 = current DBP
        
        ; ======================================================================
        ; Update sensor history (rolling buffer of 10 entries)
        ; ======================================================================
        LDR     R8, =sensor_history_index
        LDRB    R9, [R8]                ; R9 = current index
        
        ; Store current values in history
        LDR     R0, =sensor_history
        STRB    R4, [R0, R9]            ; hr_history[index]
        ADD     R0, R0, #10
        STRB    R5, [R0, R9]            ; o2_history[index]
        ADD     R0, R0, #10
        STRB    R6, [R0, R9]            ; sbp_history[index]
        ADD     R0, R0, #10
        STRB    R7, [R0, R9]            ; dbp_history[index]
        
        ; Update index (modulo 10)
        ADD     R9, R9, #1
        CMP     R9, #10
        IT      HS
        MOVHS   R9, #0
        STRB    R9, [R8]
        
        ; ======================================================================
        ; Check if all 10 values in history are identical
        ; ======================================================================
        ; Check HR history
        LDR     R0, =sensor_history
        LDRB    R1, [R0]                ; First HR value
        MOV     R2, #1                  ; Counter
        
check_hr_loop
        CMP     R2, #10
        BGE     hr_malfunction          ; All 10 are same! 
        LDRB    R3, [R0, R2]
        CMP     R1, R3
        BNE     check_o2                ; Different value found, check next sensor
        ADD     R2, R2, #1
        B       check_hr_loop
        
hr_malfunction
        ; Log HR sensor malfunction
        MOV     R0, #ERROR_SENSOR_MALFUNCTION
        MOV     R1, R10                 ; patient index
        MOV     R2, #1                  ; error_code: 1 = HR sensor
        MOV     R3, R4                  ; error_value = HR reading
        BL      log_error_to_flash
        MOV     R0, #1                  ; Return 1 (malfunction detected)
        B       csm_done
        
check_o2
        ; Check O2 history
        LDR     R0, =sensor_history
        ADD     R0, R0, #10
        LDRB    R1, [R0]
        MOV     R2, #1
        
check_o2_loop
        CMP     R2, #10
        BGE     o2_malfunction
        LDRB    R3, [R0, R2]
        CMP     R1, R3
        BNE     check_sbp
        ADD     R2, R2, #1
        B       check_o2_loop
        
o2_malfunction
        MOV     R0, #ERROR_SENSOR_MALFUNCTION
        MOV     R1, R10
        MOV     R2, #2                  ; error_code: 2 = O2 sensor
        MOV     R3, R5
        BL      log_error_to_flash
        MOV     R0, #1
        B       csm_done
        
check_sbp
        ; Check SBP history
        LDR     R0, =sensor_history
        ADD     R0, R0, #20
        LDRB    R1, [R0]
        MOV     R2, #1
        
check_sbp_loop
        CMP     R2, #10
        BGE     sbp_malfunction
        LDRB    R3, [R0, R2]
        CMP     R1, R3
        BNE     no_malfunction
        ADD     R2, R2, #1
        B       check_sbp_loop
        
sbp_malfunction
        MOV     R0, #ERROR_SENSOR_MALFUNCTION
        MOV     R1, R10
        MOV     R2, #3                  ; error_code: 3 = SBP sensor
        MOV     R3, R6
        BL      log_error_to_flash
        MOV     R0, #1
        B       csm_done
        
no_malfunction
        MOV     R0, #0                  ; No malfunction
        
csm_done
        POP     {R4-R11, PC}
        ENDP

; ==============================================================================
; FUNCTION: check_invalid_dosage
; Description: Checks if medicine has zero unit_price or quantity
; Parameters:
;   R0 = pointer to Patient structure
;   R1 = patient index
; Returns:
;   R0 = 1 if invalid dosage found, 0 otherwise
; ==============================================================================
check_invalid_dosage PROC
        PUSH    {R4-R9, LR}
        
        MOV     R8, R0                  ; R8 = patient pointer
        MOV     R9, R1                  ; R9 = patient index
        
        ; Load medicine count and list pointer
        LDRB    R4, [R8, #MEDICINE_COUNT_OFF]
        CMP     R4, #0
        BEQ     cid_no_error            ; No medicines, no error
        
        LDR     R5, [R8, #MEDICINE_LIST_PTR_OFF]
        CMP     R5, #0
        BEQ     cid_no_error            ; NULL pointer, skip check
        
        MOV     R6, #0                  ; Medicine index
        
cid_loop
        ; Calculate medicine address: med_list + (index * MEDICINE_SIZE)
        MOV     R0, R6
        MOV     R1, #MEDICINE_SIZE
        MUL     R0, R0, R1
        ADD     R7, R5, R0              ; R7 = &medicine[index]
        
        ; Check unit_price (at offset 0x08)
        LDR     R0, [R7, #UNIT_PRICE_OFF]
        CMP     R0, #0
        BEQ     cid_invalid_price
        
        ; Check quantity (at offset 0x0C, 2 bytes)
        LDRH    R1, [R7, #QUANTITY_OFF]
        CMP     R1, #0
        BEQ     cid_invalid_quantity
        
        ; Next medicine
        ADD     R6, R6, #1
        CMP     R6, R4
        BLT     cid_loop
        B       cid_no_error
        
cid_invalid_price
        ; Log invalid dosage error (zero price)
        MOV     R0, #ERROR_INVALID_DOSAGE
        MOV     R1, R9                  ; patient index
        MOV     R2, #1                  ; error_code: 1 = zero price
        MOV     R3, R6                  ; error_value = medicine index
        BL      log_error_to_flash
        MOV     R0, #1
        B       cid_done
        
cid_invalid_quantity
        ; Log invalid dosage error (zero quantity)
        MOV     R0, #ERROR_INVALID_DOSAGE
        MOV     R1, R9
        MOV     R2, #2                  ; error_code: 2 = zero quantity
        MOV     R3, R6                  ; medicine index
        BL      log_error_to_flash
        MOV     R0, #1
        B       cid_done
        
cid_no_error
        MOV     R0, #0
        
cid_done
        POP     {R4-R9, PC}
        ENDP

; ==============================================================================
; FUNCTION: check_memory_overflow
; Description: Checks if patient array address exceeds safe boundary
; Parameters:
;   R0 = pointer to Patient structure
;   R1 = patient index
; Returns:
;   R0 = 1 if overflow detected, 0 otherwise
; ==============================================================================
check_memory_overflow PROC
        PUSH    {R4-R6, LR}
        
        MOV     R4, R0                  ; R4 = patient pointer
        MOV     R5, R1                  ; R5 = patient index
        
        ; Check if patient pointer exceeds boundary
        LDR     R6, =PATIENT_ARRAY_MAX
        CMP     R4, R6
        BHS     cmo_overflow            ; Address >= max boundary
        
        ; Check billing total_bill field
        ADD     R0, R4, #BILLING_OFF
        ADD     R0, R0, #TOTAL_BILL_OFF
        LDR     R1, [R0]
        
        ; Check if total_bill is unreasonably high (potential overflow)
        LDR     R2, =0xF0000000
        CMP     R1, R2
        BHS     cmo_billing_overflow
        
        MOV     R0, #0                  ; No overflow
        B       cmo_done
        
cmo_overflow
        ; Log memory overflow error
        MOV     R0, #ERROR_MEMORY_OVERFLOW
        MOV     R1, R5                  ; patient index
        MOV     R2, #1                  ; error_code: 1 = address overflow
        MOV     R3, R4                  ; error_value = bad address
        BL      log_error_to_flash
        MOV     R0, #1
        B       cmo_done
        
cmo_billing_overflow
        MOV     R0, #ERROR_MEMORY_OVERFLOW
        MOV     R1, R5
        MOV     R2, #2                  ; error_code: 2 = billing overflow
        MOV     R3, R1                  ; error_value = total_bill
        BL      log_error_to_flash
        MOV     R0, #1
        
cmo_done
        POP     {R4-R6, PC}
        ENDP

; ==============================================================================
; FUNCTION: log_error_to_flash
; Description: Logs error record to simulated Flash memory
; Parameters:
;   R0 = error_type
;   R1 = patient_index
;   R2 = error_code
;   R3 = error_value
; Returns: None
; ==============================================================================
log_error_to_flash PROC
        PUSH    {R4-R8, LR}
        
        MOV     R4, R0                  ; Save error_type
        MOV     R5, R1                  ; Save patient_index
        MOV     R6, R2                  ; Save error_code
        MOV     R7, R3                  ; Save error_value
        
        ; Set global error flag
        LDR     R0, =error_flag
        MOV     R1, #1
        STR     R1, [R0]
        
        ; Check if error log is full
        LDR     R0, =error_count
        LDR     R1, [R0]
        CMP     R1, #MAX_ERROR_RECORDS
        BGE     letf_full
        
        ; Calculate error record address
        MOV     R2, #ERROR_RECORD_SIZE
        MUL     R3, R1, R2              ; R3 = error_count * 16
        LDR     R8, =error_log_buffer
        ADD     R8, R8, R3              ; R8 = &error_log[error_count]
        
        ; Write error record
        STRB    R4, [R8, #0]            ; error_type
        STRB    R5, [R8, #1]            ; patient_index
        STRB    R6, [R8, #2]            ; error_code
        
        ; Get timestamp
        LDR     R2, =system_clock
        LDR     R2, [R2]
        STR     R2, [R8, #4]            ; timestamp
        
        STR     R7, [R8, #8]            ; error_value
        
        ; Increment error_count
        ADD     R1, R1, #1
        STR     R1, [R0]
        
letf_full
        POP     {R4-R8, PC}
        ENDP

; ==============================================================================
; FUNCTION: get_error_count
; Description: Returns current error count
; Parameters: None
; Returns:
;   R0 = error count
; ==============================================================================
get_error_count PROC
        LDR     R0, =error_count
        LDR     R0, [R0]
        BX      LR
        ENDP

        ALIGN
        END
