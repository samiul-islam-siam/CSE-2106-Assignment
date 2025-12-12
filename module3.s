; ==============================================================================
; SmartCare-32: Module 3 – Vital Threshold Alert Module
; File: module3.s - OPTIMIZED: 5 alerts max, 12-byte records
; ==============================================================================

		AREA    Module3_code, CODE, READONLY
        ALIGN   2
        EXPORT  check_vital_thresholds
        THUMB
		IMPORT  system_clock

; Offsets
VITAL_BUFFER_OFF        EQU     0x18
VITAL_BUFFER_INDEX_OFF  EQU     0x40
ALERT_COUNT_OFF         EQU     0x15
ALERT_FLAG_OFF          EQU     0x41
ALERT_BUFFER_OFF        EQU     0x44

; Alert record - OPTIMIZED
ALERT_RECORD_SIZE       EQU     12      ; CHANGED from 16
ALERT_BUFFER_MAX        EQU     5       ; CHANGED from 20

; Alert record structure (12 bytes):
; +0x00: vital_type (1 byte)
; +0x01: actual_reading (1 byte)
; +0x02: reserved (2 bytes)
; +0x04: timestamp (4 bytes)
; +0x08: reserved (4 bytes)

check_vital_thresholds
        PUSH    {LR}

        ; Get latest vital index
        LDRB    R1, [R0, #VITAL_BUFFER_INDEX_OFF]
        CMP     R1, #0
        BNE     index_nonzero
        MOVS    R1, #9
        B       got_index
index_nonzero
        SUBS    R1, R1, #1
got_index

        ; Calculate vital buffer address
        LDR     R2, =VITAL_BUFFER_OFF
        LDR     R3, =VITAL_BUFFER_OFF
        MOV     R4, R1
        LSL     R4, R4, #2
        ADD     R4, R4, #VITAL_BUFFER_OFF
        ADD     R4, R0, R4

        ; Load vitals
        LDRB    R5, [R4, #0]          ; heart_rate
        LDRB    R6, [R4, #1]          ; oxygen_level
        LDRB    R7, [R4, #2]          ; systolic_bp

        ; Load system_clock
        LDR     R8, =system_clock
        LDR     R8, [R8]

        ; Check HR > 120
        MOVS    R9, #0
        CMP     R5, #120
        BLE     check_o2
        MOVS    R9, #0
        MOV     R10, R5
        BL      create_alert_record

check_o2
        ; Check O2 < 92
        CMP     R6, #92
        BGE     check_sbp
        MOVS    R9, #1
        MOV     R10, R6
        BL      create_alert_record

check_sbp
        ; Check SBP > 160 or < 90
        CMP     R7, #160
        BGT     sbp_high
        CMP     R7, #90
        BGE     done_checks

sbp_low
        MOVS    R9, #2
        MOV     R10, R7
        BL      create_alert_record
        B       done_checks

sbp_high
        MOVS    R9, #2
        MOV     R10, R7
        BL      create_alert_record

done_checks
        POP     {PC}

; ---------------------------------------------------------
; create_alert_record - OPTIMIZED (12-byte records, max 5)
; ---------------------------------------------------------
create_alert_record
        ; Set alert flag
        MOVS    R11, #1
        STRB    R11, [R0, #ALERT_FLAG_OFF]

        ; Load alert_count
        LDRB    R11, [R0, #ALERT_COUNT_OFF]

        ; Cap at 5 alerts - CHANGED
        CMP     R11, #ALERT_BUFFER_MAX
        BCS     ret_from_create

        ; Calculate record address:  base + alert_count * 12
        MOV     R12, R11
        LSL     R1, R12, #2             ; * 4
        ADD     R2, R1, R12, LSL #1     ; + * 2 = * 6
        LSL     R2, R2, #1              ; * 2 = * 12
        ADD     R2, R2, #ALERT_BUFFER_OFF
        ADD     R12, R0, R2

        ; Zero 12 bytes (3 words)
        MOVS    R1, #0
        STR     R1, [R12, #0]
        STR     R1, [R12, #4]
        STR     R1, [R12, #8]

        ; Store data
        STRB    R9, [R12, #0]           ; vital_type
        STRB    R10, [R12, #1]          ; actual_reading
        STR     R8, [R12, #4]           ; timestamp

        ; Increment alert_count
        ADDS    R11, R11, #1
        STRB    R11, [R0, #ALERT_COUNT_OFF]

ret_from_create
        BX      LR

        ALIGN   2
        END
