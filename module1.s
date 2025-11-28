		AREA 	MODULE_1, CODE, READONLY
        THUMB

; Patient structure offsets
PATIENT_ID_OFF          EQU     0x00
NAME_PTR_OFF            EQU     0x04
AGE_OFF                 EQU     0x08
TREATMENT_CODE_OFF      EQU     0x09
WARD_NUMBER_OFF         EQU     0x0A
ROOM_DAILY_RATE_OFF     EQU     0x0C
MEDICINE_LIST_PTR_OFF   EQU     0x10
MEDICINE_COUNT_OFF      EQU     0x14
ALERT_COUNT_OFF         EQU     0x15
STAY_DAYS_OFF           EQU     0x16
VITAL_BUFFER_OFF        EQU     0x18
VITAL_BUFFER_INDEX_OFF  EQU     0x40
ALERT_FLAG_OFF          EQU     0x41
DOSAGE_DUE_FLAG_OFF     EQU     0x42
ALERT_BUFFER_OFF        EQU     0x44
BILLING_OFF             EQU     0x184

        EXPORT 	patient_record_initialization
			
; void initialize_patient(Patient *patient, uint32_t id, char *name, uint8_t age,
;                        uint16_t ward, uint8_t treatment_code,
;                        uint32_t room_rate, Medicine *med_list, uint8_t med_count,
;                        uint16_t stay_days)

patient_record_initialization
        ; r0 = patient*
        ; r1 = id
        ; r2 = name*
        ; r3 = age
        ; stack args:
        ; [sp]   = ward
        ; [sp+4] = treatment_code
        ; [sp+8] = room_rate
        ; [sp+12]= med_list
        ; [sp+16]= med_count
        ; [sp+20]= stay_days

        LDR     r4, [sp, #0]        ; ward
        LDR     r5, [sp, #4]        ; treatment_code
        LDR     r6, [sp, #8]        ; room_rate
        LDR     r7, [sp, #12]       ; med_list
        LDR     r8, [sp, #16]       ; med_count
        LDR     r9, [sp, #20]       ; stay_days

        PUSH    {r4-r7, lr}

        ; Write patient fields
        STR     r1, [r0, #PATIENT_ID_OFF]
        STR     r2, [r0, #NAME_PTR_OFF]
        STRB    r3, [r0, #AGE_OFF]
        STRB    r5, [r0, #TREATMENT_CODE_OFF]
        STRH    r4, [r0, #WARD_NUMBER_OFF]
        STR     r6, [r0, #ROOM_DAILY_RATE_OFF]
        STR     r7, [r0, #MEDICINE_LIST_PTR_OFF]
        STRB    r8, [r0, #MEDICINE_COUNT_OFF]

        ; alert_count = 0
        MOVS    r10, #0
        STRB    r10, [r0, #ALERT_COUNT_OFF]

        ; stay_days
        STRH    r9, [r0, #STAY_DAYS_OFF]

        ; Set flags = 0
        STRB    r10, [r0, #VITAL_BUFFER_INDEX_OFF]
        STRB    r10, [r0, #ALERT_FLAG_OFF]
        STRB    r10, [r0, #DOSAGE_DUE_FLAG_OFF]

        ; ---------------------------------------------------------
        ; Zero Billing (24 bytes)
        ; ---------------------------------------------------------
        ADD     r11, r0, #BILLING_OFF
        MOVS    r12, #0
        STR     r12, [r11, #0]
        STR     r12, [r11, #4]
        STR     r12, [r11, #8]
        STR     r12, [r11, #12]
        STR     r12, [r11, #16]
        STR     r12, [r11, #20]     ; includes overflow_flag

        ; ---------------------------------------------------------
        ; Zero vital_buffer (40 bytes = 10 words)
        ; ---------------------------------------------------------
        ADD     r11, r0, #VITAL_BUFFER_OFF
        MOVS    r4, #10
zero_vitals_loop
        STR     r12, [r11], #4
        SUBS    r4, r4, #1
        BNE     zero_vitals_loop

        ; ---------------------------------------------------------
        ; Zero alert_buffer (320 bytes = 80 words)
        ; ---------------------------------------------------------
        ADD     r11, r0, #ALERT_BUFFER_OFF
        MOVS    r4, #80
zero_alert_loop
        STR     r12, [r11], #4
        SUBS    r4, r4, #1
        BNE     zero_alert_loop

        POP     {r4-r7, pc}
        ALIGN
		END