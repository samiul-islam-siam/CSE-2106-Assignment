;===============================================================================
; Module 10 - Patient Report Generator - FIXED
;===============================================================================

        THUMB
        AREA    Module10_code, DATA, READWRITE

; [Keep all string definitions - no changes]
nl          DCB     0x0A,0
int_dum     DCB     "                      ",0
line        DCB     "                                        ",0

hdr1        DCB     "==============================================================",0
hdr2        DCB     "    PATIENT SUMMARY REPORT",0
hdr3        DCB     "    SmartCare-32: Healthcare Monitoring System",0

info_hdr    DCB     "PATIENT INFORMATION:",0
divider     DCB     "--------------------------------------------------------------",0
pid_str     DCB     "  Patient ID       :                     ",0
age_str     DCB     "  Age              :                     years",0
ward_str    DCB     "  Ward Number      :                    ",0

vital_hdr   DCB     "LATEST VITAL SIGNS:",0
hr_str      DCB     "  Heart Rate       :                     bpm",0
bp_str      DCB     "  Blood Pressure   :           /         mmHg",0
o2_str      DCB     "  SpO2 (Oxygen)    :                     %",0

alert_hdr   DCB     "ALERT SUMMARY:",0
alert_str   DCB     "  Total Alerts     :                    ",0
status_ok   DCB     " (Patient Stable)",0
status_warn DCB     " (Attention Required)",0
status_crit DCB     " (Critical condition)",0

bill_hdr    DCB     "BILLING SUMMARY:",0
bill_str    DCB     "  Total Bill       :  $                   USD",0

end_rpt     DCB     "              End of Report",0

pid_tmpl    DCB     "  Patient ID       :                     ",0
age_tmpl    DCB     "  Age              :                     years",0
ward_tmpl   DCB     "  Ward Number      :                    ",0
hr_tmpl     DCB     "  Heart Rate       :                     bpm",0
bp_tmpl     DCB     "  Blood Pressure   :           /         mmHg",0
o2_tmpl     DCB     "  SpO2 (Oxygen)    :                     %",0
alert_tmpl  DCB     "  Total Alerts     :                    ",0
bill_tmpl   DCB     "  Total Bill       : $                   USD",0

        AREA    |. text|, CODE, READONLY
        EXPORT  Generate_Summary_Report
        EXPORT  Generate_All_Patient_Reports
        IMPORT  ITM_SendChar_C
        IMPORT  ITM_Init_C
        IMPORT  patient_array
        IMPORT  Print_Error_Log

; CONSTANTS - FIXED
PATIENT_SIZE    EQU     152         ; CHANGED from 412
PATIENT_ID_OFF  EQU     0x00
AGE_OFF         EQU     0x08
WARD_OFF        EQU     0x0A
VITALS_OFF      EQU     0x18
ALERT_CNT_OFF   EQU     0x15
TOTAL_BILL_OFF  EQU     0x90        ; CHANGED from 0x194 (0x80 + 0x10)

Generate_All_Patient_Reports PROC
        B       Generate_Summary_Report
        ENDP

Generate_Summary_Report PROC
        PUSH    {r4-r7, lr}
        PUSH    {r9-r11}
        
        BL      ITM_Init_C
        BL      Print_Error_Log
        
        LDR     r9, =patient_array
        MOVS    r10, #3
        MOVS    r11, #152           ; Use literal value
        MOVS    r12, #0
        B       check_loop

print_patient
        BL      reset_templates
        
        MOV     r5, r12
        MOV     r1, #152
        MUL     r5, r5, r1
        ADD     r5, r5, r9
        
        ; [Print header - same as before]
        LDR     r0, =hdr1
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        LDR     r0, =hdr2
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        LDR     r0, =hdr3
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        LDR     r0, =hdr1
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        LDR     r0, =info_hdr
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        LDR     r0, =divider
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ; Patient ID
        BL      reset_int_dum
        LDR     r2, [r5, #PATIENT_ID_OFF]
        LDR     r0, =int_dum
        MOVS    r7, #0
        BL      push_integer
        LDR     r0, =pid_str
        LDR     r2, =int_dum
        MOVS    r8, r7
        SUBS    r8, #1
        MOVS    r7, #21
        BL      push_string_rev
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ; Age
        BL      reset_int_dum
        LDRB    r2, [r5, #AGE_OFF]
        LDR     r0, =int_dum
        MOVS    r7, #0
        BL      push_integer
        LDR     r0, =age_str
        LDR     r2, =int_dum
        MOVS    r8, r7
        SUBS    r8, #1
        MOVS    r7, #21
        BL      push_string_rev
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ; Ward
        BL      reset_int_dum
        LDRH    r2, [r5, #WARD_OFF]
        LDR     r0, =int_dum
        MOVS    r7, #0
        BL      push_integer
        LDR     r0, =ward_str
        LDR     r2, =int_dum
        MOVS    r8, r7
        SUBS    r8, #1
        MOVS    r7, #21
        BL      push_string_rev
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ; Vitals section
        LDR     r0, =divider
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        LDR     r0, =vital_hdr
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        LDR     r0, =divider
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ; Heart Rate
        BL      reset_int_dum
        LDRB    r2, [r5, #VITALS_OFF]
        LDR     r0, =int_dum
        MOVS    r7, #0
        BL      push_integer
        LDR     r0, =hr_str
        LDR     r2, =int_dum
        MOVS    r8, r7
        SUBS    r8, #1
        MOVS    r7, #21
        BL      push_string_rev
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ; Blood Pressure
        BL      reset_int_dum
        ADD     r6, r5, #VITALS_OFF
        LDRB    r2, [r6, #2]
        LDR     r0, =int_dum
        MOVS    r7, #0
        BL      push_integer
        LDR     r0, =bp_str
        LDR     r2, =int_dum
        MOVS    r8, r7
        SUBS    r8, #1
        MOVS    r7, #21
        BL      push_string_rev
        
        MOVS    r1, #0x2F
        STRB    r1, [r0, #24]
        
        BL      reset_int_dum
        LDRB    r2, [r6, #3]
        LDR     r0, =int_dum
        MOVS    r7, #0
        BL      push_integer
        LDR     r0, =bp_str
        LDR     r2, =int_dum
        MOVS    r8, r7
        SUBS    r8, #1
        MOVS    r7, #26
        BL      push_string_rev
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ; O2
        BL      reset_int_dum
        LDRB    r2, [r6, #1]
        LDR     r0, =int_dum
        MOVS    r7, #0
        BL      push_integer
        LDR     r0, =o2_str
        LDR     r2, =int_dum
        MOVS    r8, r7
        SUBS    r8, #1
        MOVS    r7, #21
        BL      push_string_rev
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ; Alert section
        LDR     r0, =divider
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        LDR     r0, =alert_hdr
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        LDR     r0, =divider
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        BL      reset_int_dum
        LDRB    r2, [r5, #ALERT_CNT_OFF]
        MOV     r6, r2
        LDR     r0, =int_dum
        MOVS    r7, #0
        BL      push_integer
        LDR     r0, =alert_str
        LDR     r2, =int_dum
        MOVS    r8, r7
        SUBS    r8, #1
        MOVS    r7, #21
        BL      push_string_rev
        BL      PrintByteString
        
        CMP     r6, #0
        BEQ     print_stable
        CMP     r6, #3
        BLT     print_attention
        LDR     r0, =status_crit
        B       print_status
print_attention
        LDR     r0, =status_warn
        B       print_status
print_stable
        LDR     r0, =status_ok
print_status
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ; Billing section
        LDR     r0, =divider
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        LDR     r0, =bill_hdr
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        LDR     r0, =divider
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        BL      reset_int_dum
        LDR     r2, [r5, #TOTAL_BILL_OFF]       ; FIXED offset
        LDR     r0, =int_dum
        MOVS    r7, #0
        BL      push_integer
        LDR     r0, =bill_str
        LDR     r2, =int_dum
        MOVS    r8, r7
        SUBS    r8, #1
        MOVS    r7, #23
        BL      push_string_rev
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ; Footer
        LDR     r0, =hdr1
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        LDR     r0, =end_rpt
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        LDR     r0, =hdr1
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ADDS    r12, #1
        B       check_loop

check_loop
        CMP     r12, r10
        BEQ     finish
        B       print_patient

finish
        POP     {r9-r11}
        POP     {r4-r7, pc}
        ENDP

; [Keep all helper functions unchanged]
reset_templates PROC
        PUSH    {r0-r2, lr}
        LDR     r0, =pid_tmpl
        LDR     r1, =pid_str
        MOVS    r2, #40
        BL      copy_bytes
        LDR     r0, =age_tmpl
        LDR     r1, =age_str
        MOVS    r2, #45
        BL      copy_bytes
        LDR     r0, =ward_tmpl
        LDR     r1, =ward_str
        MOVS    r2, #40
        BL      copy_bytes
        LDR     r0, =hr_tmpl
        LDR     r1, =hr_str
        MOVS    r2, #43
        BL      copy_bytes
        LDR     r0, =bp_tmpl
        LDR     r1, =bp_str
        MOVS    r2, #48
        BL      copy_bytes
        LDR     r0, =o2_tmpl
        LDR     r1, =o2_str
        MOVS    r2, #41
        BL      copy_bytes
        LDR     r0, =alert_tmpl
        LDR     r1, =alert_str
        MOVS    r2, #40
        BL      copy_bytes
        LDR     r0, =bill_tmpl
        LDR     r1, =bill_str
        MOVS    r2, #45
        BL      copy_bytes
        POP     {r0-r2, pc}
        ENDP

copy_bytes PROC
cb_loop
        CMP     r2, #0
        BXEQ    lr
        LDRB    r3, [r0]
        STRB    r3, [r1]
        ADDS    r0, #1
        ADDS    r1, #1
        SUBS    r2, #1
        B       cb_loop
        ENDP

reset_int_dum PROC
        PUSH    {r0-r2, lr}
        LDR     r0, =int_dum
        MOVS    r1, #0x20
        MOVS    r2, #22
rid_loop
        CMP     r2, #0
        BEQ     rid_done
        STRB    r1, [r0]
        ADDS    r0, #1
        SUBS    r2, #1
        B       rid_loop
rid_done
        POP     {r0-r2, pc}
        ENDP

push_integer PROC
        PUSH    {r4, lr}
        CMP     r2, #0
        BNE     pi_nonzero
        MOVS    r1, #48
        STRB    r1, [r0, r7]
        ADDS    r7, #1
        POP     {r4, pc}
pi_nonzero
pi_loop
        CMP     r2, #0
        BEQ     pi_done
        MOVS    r4, #10
        UDIV    r1, r2, r4
        MUL     r3, r1, r4
        SUBS    r1, r2, r3
        ADDS    r1, #48
        STRB    r1, [r0, r7]
        UDIV    r2, r4
        ADDS    r7, #1
        B       pi_loop
pi_done
        POP     {r4, pc}
        ENDP

push_string_rev PROC
        PUSH    {r4, lr}
psr_loop
        CMP     r8, #0
        BLT     psr_done
        LDRB    r1, [r2, r8]
        STRB    r1, [r0, r7]
        SUBS    r8, #1
        ADDS    r7, #1
        B       psr_loop
psr_done
        MOVS    r1, #0x20
psr_fill
        CMP     r7, #38
        BGE     psr_end
        STRB    r1, [r0, r7]
        ADDS    r7, #1
        B       psr_fill
psr_end
        POP     {r4, pc}
        ENDP

PrintByteString PROC
        PUSH    {r4-r7, lr}
        PUSH    {r9-r12}
loop_pbs
        LDRB    r1, [r0]
        CMP     r1, #0
        BEQ     done_pbs
        MOV     r4, r0
        MOV     r0, r1
        BL      ITM_SendChar_C
        MOV     r0, r4
        ADD     r0, r0, #1
        B       loop_pbs
done_pbs
        POP     {r9-r12}
        POP     {r4-r7, pc}
        ENDP

        LTORG
        END
