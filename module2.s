        AREA VitalSigns, CODE, READONLY
        EXPORT main

; Memory addresses for simulated sensors
SENSOR_HR_ADDR  EQU 0x20001000    ; Heart Rate sensor
SENSOR_BP_ADDR  EQU 0x20001004    ; Blood Pressure sensor
SENSOR_O2_ADDR  EQU 0x20001008    ; Oxygen saturation sensor

; Buffer storage addresses (10 entries × 4 bytes = 40 bytes each)
BUFFER_HR_BASE  EQU 0x20002000
BUFFER_BP_BASE  EQU 0x20002028    ; 0x20002000 + 40
BUFFER_O2_BASE  EQU 0x20002050    ; 0x20002028 + 40

; Buffer index storage addresses
INDEX_HR_ADDR   EQU 0x20003000
INDEX_BP_ADDR   EQU 0x20003004
INDEX_O2_ADDR   EQU 0x20003008

BUFFER_SIZE     EQU 10            ; Circular buffer size

main
        ; Initialize all buffer indices to 0
        MOV     R0, #0
        LDR     R1, =INDEX_HR_ADDR
        STR     R0, [R1]
        LDR     R1, =INDEX_BP_ADDR
        STR     R0, [R1]
        LDR     R1, =INDEX_O2_ADDR
        STR     R0, [R1]

        ; === ACQUIRE HEART RATE ===
        ; Read HR value from sensor
        LDR     R0, =SENSOR_HR_ADDR
        LDR     R1, [R0]              ; R1 = HR sensor value

        ; Load current buffer index
        LDR     R2, =INDEX_HR_ADDR
        LDR     R3, [R2]              ; R3 = current index

        ; Calculate buffer position: base + (index * 4)
        MOV     R4, #4
        MUL     R5, R3, R4            ; R5 = index * 4
        LDR     R6, =BUFFER_HR_BASE
        ADD     R7, R6, R5            ; R7 = buffer address

        ; Store HR value in buffer
        STR     R1, [R7]

        ; Update index with modulo arithmetic: (index + 1) % 10
        ADD     R3, R3, #1            ; index++
        CMP     R3, #BUFFER_SIZE
        BLT     hr_no_wrap
        MOV     R3, #0                ; Wrap to 0 if index >= 10
hr_no_wrap
        STR     R3, [R2]              ; Store updated index

        ; === ACQUIRE BLOOD PRESSURE ===
        ; Read BP value from sensor
        LDR     R0, =SENSOR_BP_ADDR
        LDR     R1, [R0]              ; R1 = BP sensor value

        ; Load current buffer index
        LDR     R2, =INDEX_BP_ADDR
        LDR     R3, [R2]              ; R3 = current index

        ; Calculate buffer position
        MOV     R4, #4
        MUL     R5, R3, R4            ; R5 = index * 4
        LDR     R6, =BUFFER_BP_BASE
        ADD     R7, R6, R5            ; R7 = buffer address

        ; Store BP value in buffer
        STR     R1, [R7]

        ; Update index with modulo
        ADD     R3, R3, #1
        CMP     R3, #BUFFER_SIZE
        BLT     bp_no_wrap
        MOV     R3, #0
bp_no_wrap
        STR     R3, [R2]

        ; === ACQUIRE OXYGEN SATURATION ===
        ; Read O2 value from sensor
        LDR     R0, =SENSOR_O2_ADDR
        LDR     R1, [R0]              ; R1 = O2 sensor value

        ; Load current buffer index
        LDR     R2, =INDEX_O2_ADDR
        LDR     R3, [R2]              ; R3 = current index

        ; Calculate buffer position
        MOV     R4, #4
        MUL     R5, R3, R4            ; R5 = index * 4
        LDR     R6, =BUFFER_O2_BASE
        ADD     R7, R6, R5            ; R7 = buffer address

        ; Store O2 value in buffer
        STR     R1, [R7]

        ; Update index with modulo
        ADD     R3, R3, #1
        CMP     R3, #BUFFER_SIZE
        BLT     o2_no_wrap
        MOV     R3, #0
o2_no_wrap
        STR     R3, [R2]

        ; End of acquisition cycle
stop    B       stop

        ALIGN
        END
