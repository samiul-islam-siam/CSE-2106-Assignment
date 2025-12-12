; ==============================================================================
; SmartCare-32: Module 4 - Medicine Administration Scheduler
; File: module4.s
; ==============================================================================

		AREA    Module4_code, CODE, READONLY
        THUMB
            
        IMPORT  system_clock
            
MEDICINE_LIST_PTR_OFF   EQU     0x10
MEDICINE_COUNT_OFF      EQU     0x14
DOSAGE_DUE_FLAG_OFF     EQU     0x42
    
DOSAGE_INTERVAL_OFF     EQU     0x01
LAST_ADMIN_TIME_OFF     EQU     0x04   ; 4-byte aligned

        EXPORT  medicine_administration_scheduler

; void check_medicine_schedule(Patient *patient)

medicine_administration_scheduler
        PUSH    {R4-R7, LR}

        ; R0 = patient*
        LDRB    R1, [R0, #MEDICINE_COUNT_OFF]    ; R1 = medicine_count
        CMP     R1, #0
        BEQ     cms_done

        LDR     R2, [R0, #MEDICINE_LIST_PTR_OFF] ; R2 = medicine list pointer
        MOVS    R3, #0
        STRB    R3, [R0, #DOSAGE_DUE_FLAG_OFF]   ; clear flag

        MOVS    R4, #0                            ; index = 0

cms_loop
        ADD     R5, R2, R4, LSL #4               ; med_ptr = R2 + i*16
        LDR     R6, [R5, #LAST_ADMIN_TIME_OFF]   ; last administered
        LDRB    R7, [R5, #DOSAGE_INTERVAL_OFF]   ; interval hours

        MOVS    R8, #0xE1
        LSLS    R8, R8, #4                        ; R8 = 3600
        MUL     R9, R7, R8                        ; seconds_to_add
        ADDS    R9, R6, R9                        ; next_due_time

        LDR     R10, =system_clock
        LDR     R10, [R10]                        ; current time
        CMP     R10, R9
        BLT     cms_not_due

        MOVS    R11, #1
        STRB    R11, [R0, #DOSAGE_DUE_FLAG_OFF]  ; set DOSAGE_DUE flag
        STR     R10, [R5, #LAST_ADMIN_TIME_OFF]  ; update last_administered_time

cms_not_due
        ADDS    R4, R4, #1
        CMP     R4, R1
        BLT     cms_loop

cms_done
        POP     {R4-R7, PC}

        ALIGN
        END
