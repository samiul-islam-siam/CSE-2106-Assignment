        AREA 	MODULE_4, CODE, READONLY
        THUMB
			
        IMPORT  system_clock
			
MEDICINE_LIST_PTR_OFF   EQU     0x10
MEDICINE_COUNT_OFF      EQU     0x14
DOSAGE_DUE_FLAG_OFF     EQU     0x42

        EXPORT  medicine_administration_scheduler

; void check_medicine_schedule(Patient *patient)

medicine_administration_scheduler
        PUSH    {r4-r7, lr}

        ; r0 = patient*
        ; load medicine_count (byte)
        LDRB    r1, [r0, #MEDICINE_COUNT_OFF]    ; r1 = medicine_count
        CMP     r1, #0
        BEQ     cms_done

        ; load medicine_list_ptr
        LDR     r2, [r0, #MEDICINE_LIST_PTR_OFF] ; r2 = med_list pointer

        ; clear dosage_due_flag = 0
        MOVS    r3, #0
        STRB    r3, [r0, #DOSAGE_DUE_FLAG_OFF]

        ; prepare loop: index in r4
        MOVS    r4, #0               ; index i = 0

cms_loop
        ; med_ptr = r2 + i * 16  (medicine struct size = 16)
        MOV     r5, r4
        LSL     r5, r5, #4           ; r5 = i * 16
        ADD     r5, r2, r5           ; r5 = &med[i]

        ; load last_administered_time -> r6
        LDR     r6, [r5, #4]

        ; load dosage_interval_hours (byte) -> r7
        LDRB    r7, [r5, #1]

        ; compute seconds_to_add = r7 * 3600
        ; Build 3600 as (0xE1 << 4) to avoid large imm issues:
        MOVS    r8, #0xE1
        LSLS    r8, r8, #4           ; r8 = 0xE10 = 3600
        MUL     r9, r7, r8           ; r9 = seconds_to_add

        ; next_due_time = last_administered_time + seconds_to_add
        ADDS    r9, r6, r9

        ; load system_clock
        LDR     r10, =system_clock
        LDR     r10, [r10]

        ; if system_clock < next_due_time -> not due
        CMP     r10, r9
        BLT     cms_not_due

        ; It's due: set dosage_due_flag = 1
        MOVS    r11, #1
        STRB    r11, [r0, #DOSAGE_DUE_FLAG_OFF]

        ; Update med->last_administered_time = system_clock
        STR     r10, [r5, #4]

cms_not_due
        ; i++
        ADDS    r4, r4, #1
        CMP     r4, r1
        BLT     cms_loop

cms_done
        POP     {r4-r7, pc}
        ALIGN
		END