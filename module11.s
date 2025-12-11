; ==============================================================================
; SmartCare-32: Module 11 - System Error Detection & Logging
; File: module11.s
; ==============================================================================

        PRESERVE8
        THUMB
        
; ==============================================================================
; DATA SECTION - Error Printing Strings
; ==============================================================================
        AREA    Module11_Code, DATA, READWRITE

; Error log printing strings
nl_err      DCB     0x0A,0
err_hdr1    DCB     "==============================================================",0
err_hdr2    DCB     "           SYSTEM ERROR LOG",0
err_total   DCB     "Total Errors: ",0
err_div     DCB     "--------------------------------------------------------------",0
err_no      DCB     "Error #",0
err_type_l  DCB     "  Type: ",0
err_sensor  DCB     "SENSOR MALFUNCTION",0
err_dosage  DCB     "INVALID DOSAGE",0
err_memory  DCB     "MEMORY OVERFLOW",0
err_sens_l  DCB     "  Sensor: ",0
sens_hr     DCB     "Heart Rate",0
sens_o2     DCB     "Oxygen",0
sens_bp     DCB     "Blood Pressure",0
err_val_l   DCB     "  Stuck Value: ",0
err_issue   DCB     "  Issue: ",0
iss_price   DCB     "Zero Unit Price",0
iss_qty     DCB     "Zero Quantity",0
err_med_l   DCB     "  Medicine Index: ",0
err_code_l  DCB     "  Code: ",0
code_addr   DCB     "Address Boundary",0
code_bill   DCB     "Billing Overflow",0
err_val2_l  DCB     "  Value: 0x",0
err_pid_l   DCB     "  Patient ID: ",0
err_time_l  DCB     "  Timestamp: ",0
err_sec     DCB     " sec",0
no_err_msg  DCB     "[NO ERRORS DETECTED]",0
int_buf     DCB     "                      ",0

; ==============================================================================
; CODE SECTION
; ==============================================================================
        AREA    Module11Code, CODE, READONLY
        
        EXPORT  check_sensor_malfunction
        EXPORT  check_invalid_dosage
        EXPORT  check_memory_overflow
        EXPORT  log_error_to_flash
        EXPORT  get_error_count
        EXPORT  Print_Error_Log

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
        IMPORT  patient_array
        IMPORT  ITM_SendChar_C

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

PATIENT_ARRAY_MAX           EQU     0x20000100
BILLING_OFF                 EQU     0x184
TOTAL_BILL_OFF              EQU     0x10
PATIENT_ID_OFF              EQU     0x00

; ==============================================================================
; FUNCTION: check_sensor_malfunction
; ==============================================================================
check_sensor_malfunction PROC
        PUSH    {R4-R11, LR}
        
        MOV     R10, R0
        
        LDR     R0, =SENSOR_HR
        LDRB    R4, [R0]
        
        LDR     R0, =SENSOR_O2
        LDRB    R5, [R0]
        
        LDR     R0, =SENSOR_SBP
        LDRB    R6, [R0]
        
        LDR     R0, =SENSOR_DBP
        LDRB    R7, [R0]
        
        LDR     R8, =sensor_history_index
        LDRB    R9, [R8]
        
        LDR     R0, =sensor_history
        STRB    R4, [R0, R9]
        ADD     R0, R0, #10
        STRB    R5, [R0, R9]
        ADD     R0, R0, #10
        STRB    R6, [R0, R9]
        ADD     R0, R0, #10
        STRB    R7, [R0, R9]
        
        ADD     R9, R9, #1
        CMP     R9, #10
        IT      HS
        MOVHS   R9, #0
        STRB    R9, [R8]
        
        LDR     R0, =sensor_history
        LDRB    R1, [R0]
        MOV     R2, #1
        
check_hr_loop
        CMP     R2, #10
        BGE     hr_malfunction
        LDRB    R3, [R0, R2]
        CMP     R1, R3
        BNE     check_o2
        ADD     R2, R2, #1
        B       check_hr_loop
        
hr_malfunction
        MOV     R0, #ERROR_SENSOR_MALFUNCTION
        MOV     R1, R10
        MOV     R2, #1
        MOV     R3, R4
        BL      log_error_to_flash
        MOV     R0, #1
        B       csm_done
        
check_o2
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
        MOV     R2, #2
        MOV     R3, R5
        BL      log_error_to_flash
        MOV     R0, #1
        B       csm_done
        
check_sbp
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
        MOV     R2, #3
        MOV     R3, R6
        BL      log_error_to_flash
        MOV     R0, #1
        B       csm_done
        
no_malfunction
        MOV     R0, #0
        
csm_done
        POP     {R4-R11, PC}
        LTORG
        ENDP

; ==============================================================================
; FUNCTION: check_invalid_dosage
; ==============================================================================
check_invalid_dosage PROC
        PUSH    {R4-R9, LR}
        
        MOV     R8, R0
        MOV     R9, R1
        
        LDRB    R4, [R8, #MEDICINE_COUNT_OFF]
        CMP     R4, #0
        BEQ     cid_no_error
        
        LDR     R5, [R8, #MEDICINE_LIST_PTR_OFF]
        CMP     R5, #0
        BEQ     cid_no_error
        
        MOV     R6, #0
        
cid_loop
        MOV     R0, R6
        MOV     R1, #MEDICINE_SIZE
        MUL     R0, R0, R1
        ADD     R7, R5, R0
        
        LDR     R0, [R7, #UNIT_PRICE_OFF]
        CMP     R0, #0
        BEQ     cid_invalid_price
        
        LDRH    R1, [R7, #QUANTITY_OFF]
        CMP     R1, #0
        BEQ     cid_invalid_quantity
        
        ADD     R6, R6, #1
        CMP     R6, R4
        BLT     cid_loop
        B       cid_no_error
        
cid_invalid_price
        MOV     R0, #ERROR_INVALID_DOSAGE
        MOV     R1, R9
        MOV     R2, #1
        MOV     R3, R6
        BL      log_error_to_flash
        MOV     R0, #1
        B       cid_done
        
cid_invalid_quantity
        MOV     R0, #ERROR_INVALID_DOSAGE
        MOV     R1, R9
        MOV     R2, #2
        MOV     R3, R6
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
; ==============================================================================
check_memory_overflow PROC
        PUSH    {R4-R6, LR}
        
        MOV     R4, R0
        MOV     R5, R1
        
        LDR     R6, =PATIENT_ARRAY_MAX
        CMP     R4, R6
        BHS     cmo_overflow
        
        ADD     R0, R4, #BILLING_OFF
        ADD     R0, R0, #TOTAL_BILL_OFF
        LDR     R1, [R0]
        
        LDR     R2, =0xF0000000
        CMP     R1, R2
        BHS     cmo_billing_overflow
        
        MOV     R0, #0
        B       cmo_done
        
cmo_overflow
        MOV     R0, #ERROR_MEMORY_OVERFLOW
        MOV     R1, R5
        MOV     R2, #1
        MOV     R3, R4
        BL      log_error_to_flash
        MOV     R0, #1
        B       cmo_done
        
cmo_billing_overflow
        MOV     R0, #ERROR_MEMORY_OVERFLOW
        MOV     R1, R5
        MOV     R2, #2
        MOV     R3, R1
        BL      log_error_to_flash
        MOV     R0, #1
        
cmo_done
        POP     {R4-R6, PC}
        LTORG
        ENDP

; ==============================================================================
; FUNCTION: log_error_to_flash
; ==============================================================================
log_error_to_flash PROC
        PUSH    {R4-R8, LR}
        
        MOV     R4, R0
        MOV     R5, R1
        MOV     R6, R2
        MOV     R7, R3
        
        LDR     R0, =error_flag
        MOV     R1, #1
        STR     R1, [R0]
        
        LDR     R0, =error_count
        LDR     R1, [R0]
        CMP     R1, #MAX_ERROR_RECORDS
        BGE     letf_full
        
        MOV     R2, #ERROR_RECORD_SIZE
        MUL     R3, R1, R2
        LDR     R8, =error_log_buffer
        ADD     R8, R8, R3
        
        STRB    R4, [R8, #0]
        STRB    R5, [R8, #1]
        STRB    R6, [R8, #2]
        
        LDR     R2, =system_clock
        LDR     R2, [R2]
        STR     R2, [R8, #4]
        
        STR     R7, [R8, #8]
        
        LDR     R2, =patient_array
        MOV     R3, #412
        MUL     R3, R5, R3
        ADD     R2, R2, R3
        LDR     R2, [R2, #PATIENT_ID_OFF]
        STR     R2, [R8, #12]
        
        ADD     R1, R1, #1
        STR     R1, [R0]
        
letf_full
        POP     {R4-R8, PC}
		DCB 	0x00, 0x00
        LTORG
        ENDP

; ==============================================================================
; FUNCTION: get_error_count
; ==============================================================================
get_error_count PROC
        LDR     R0, =error_count
        LDR     R0, [R0]
        BX      LR
		DCB 	0x00, 0x00
        LTORG
        ENDP

; ==============================================================================
; FUNCTION: Print_Error_Log
; ==============================================================================
Print_Error_Log PROC
        PUSH    {r4-r7, lr}
        PUSH    {r9-r11}
        
        LDR     r0, =error_count
        LDR     r10, [r0]
        
        CMP     r10, #0
        BEQ.W   no_errors_detected
        
        LDR     r0, =nl_err
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        LDR     r0, =err_hdr1
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        LDR     r0, =err_hdr2
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        LDR     r0, =err_hdr1
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        LDR     r0, =err_total
        BL      PrintErrString
        MOV     r0, r10
        BL      PrintErrInt
        LDR     r0, =nl_err
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        
        MOVS    r12, #0
		DCB 	0x00, 0x00, 0x00, 0x00
        LTORG

error_loop
        CMP     r12, r10
        BGE.W   error_done
        
        LDR     r0, =error_log_buffer
        MOVS    r1, #16
        MUL     r2, r12, r1
        ADD     r9, r0, r2
        
        LDR     r0, =err_div
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        LDR     r0, =err_no
        BL      PrintErrString
        MOV     r0, r12
        ADDS    r0, #1
        BL      PrintErrInt
        LDR     r0, =nl_err
        BL      PrintErrString
        
        LDRB    r4, [r9, #0]
        LDRB    r5, [r9, #2]
        LDR     r6, [r9, #8]
        LDR     r7, [r9, #12]
        
        LDR     r0, =err_type_l
        BL      PrintErrString
        CMP     r4, #ERROR_SENSOR_MALFUNCTION
        BEQ     print_sensor_err
        CMP     r4, #ERROR_INVALID_DOSAGE
        BEQ     print_dosage_err
        LDR     r0, =err_memory
        B       print_err_type
print_dosage_err
        LDR     r0, =err_dosage
        B       print_err_type
print_sensor_err
        LDR     r0, =err_sensor
print_err_type
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        
        CMP     r4, #ERROR_SENSOR_MALFUNCTION
        BEQ     handle_sensor
        CMP     r4, #ERROR_INVALID_DOSAGE
        BEQ     handle_dosage
        B       handle_memory
		DCB 	0x00, 0x00
        LTORG

handle_sensor
        LDR     r0, =err_sens_l
        BL      PrintErrString
        CMP     r5, #1
        BEQ     sens_hr_s
        CMP     r5, #2
        BEQ     sens_o2_s
        LDR     r0, =sens_bp
        B       print_sensor
sens_o2_s
        LDR     r0, =sens_o2
        B       print_sensor
sens_hr_s
        LDR     r0, =sens_hr
print_sensor
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        LDR     r0, =err_val_l
        BL      PrintErrString
        MOV     r0, r6
        BL      PrintErrInt
        B       print_common
        LTORG

handle_dosage
        LDR     r0, =err_issue
        BL      PrintErrString
        CMP     r5, #1
        BEQ     iss_pr
        LDR     r0, =iss_qty
        B       print_issue
iss_pr
        LDR     r0, =iss_price
print_issue
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        LDR     r0, =err_med_l
        BL      PrintErrString
        MOV     r0, r6
        BL      PrintErrInt
        B       print_common
        LTORG

handle_memory
        LDR     r0, =err_code_l
        BL      PrintErrString
        CMP     r5, #1
        BEQ     code_ad
        LDR     r0, =code_bill
        B       print_code
code_ad
        LDR     r0, =code_addr
print_code
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        LDR     r0, =err_val2_l
        BL      PrintErrString
        MOV     r0, r6
        BL      PrintErrInt
		DCB 	0x00, 0x00
        LTORG

print_common
        LDR     r0, =nl_err
        BL      PrintErrString
        LDR     r0, =err_pid_l
        BL      PrintErrString
        MOV     r0, r7
        BL      PrintErrInt
        LDR     r0, =nl_err
        BL      PrintErrString
        
        LDR     r0, =err_time_l
        BL      PrintErrString
        LDR     r0, [r9, #4]
        BL      PrintErrInt
        LDR     r0, =err_sec
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        LDR     r0, =err_div
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        
        ADDS    r12, #1
        B       error_loop
        LTORG

no_errors_detected
        LDR     r0, =nl_err
        BL      PrintErrString
        LDR     r0, =no_err_msg
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
		DCB 	0x00, 0x00
        LTORG

error_done
        LDR     r0, =err_hdr1
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        
        POP     {r9-r11}
        POP     {r4-r7, pc}
        ENDP

; ==============================================================================
; Helper Functions
; ==============================================================================

PrintErrString PROC
        PUSH    {r4, lr}
pes_loop
        LDRB    r1, [r0]
        CMP     r1, #0
        BEQ     pes_done
        MOV     r4, r0
        MOV     r0, r1
        BL      ITM_SendChar_C
        MOV     r0, r4
        ADDS    r0, #1
        B       pes_loop
pes_done
        POP     {r4, pc}
        ENDP

PrintErrInt PROC
        PUSH    {r4-r7, lr}
        MOV     r4, r0
        LDR     r5, =int_buf
        MOVS    r6, #0
        CMP     r4, #0
        BNE     pei_loop
        MOVS    r0, #48
        BL      ITM_SendChar_C
        POP     {r4-r7, pc}
pei_loop
        CMP     r4, #0
        BEQ     pei_print
        MOVS    r7, #10
        UDIV    r1, r4, r7
        MUL     r2, r1, r7
        SUBS    r2, r4, r2
        ADDS    r2, #48
        STRB    r2, [r5, r6]
        MOV     r4, r1
        ADDS    r6, #1
        B       pei_loop
pei_print
        SUBS    r6, #1
pei_print_loop
        CMP     r6, #0
        BLT     pei_done
        LDRB    r0, [r5, r6]
        BL      ITM_SendChar_C
        SUBS    r6, #1
        B       pei_print_loop
pei_done
        POP     {r4-r7, pc}
		DCB 	0x00, 0x00
        LTORG
        ENDP

        ALIGN
        END
