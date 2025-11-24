        AREA    |.text|, CODE, READONLY
        THUMB
		
		EXPORT  main
        EXPORT  init_scheduler
        EXPORT  update_next_due_for
        EXPORT  check_all_due
        EXPORT  mark_administered
        EXPORT  SysTick_Handler    ; exported interrupt handler name (linker/startup must use it)
;        EXPORT  uart_send_str

; -------------------------
; External hardware symbols you must provide/adjust per MCU:
; - UART_DR      : address of UART data register (write to send)
; - UART_SR      : address of UART status register (check TXE bit)
; - UART_TXE_BIT : bit mask for transmit-ready in SR
; These are placeholders; replace with your MCU's register addresses or use CMSIS names in C wrappers.
; -------------------------

; Global data (placed in separate data area)
        AREA    |.data|, DATA, READWRITE
        ALIGN

current_time     DCD 0                  ; seconds counter (uint32)
med_count        DCD 3                  ; how many records (example)
; --- medicine table: interval_hours, last_admin_ts, flags
med_table
; Med 0: interval 8 hours, last_admin = 0 (for demo), flags = 0
        DCD 8        ; interval_hours
        DCD 0        ; last_admin_ts
        DCD 0        ; flags
; Med 1: interval 6 hours
        DCD 6
        DCD 0
        DCD 0
; Med 2: interval 24 hours
        DCD 24
        DCD 0
        DCD 0

        AREA    |.text|, CODE, READONLY
        THUMB
        ALIGN

main
; -------------------------
; SysTick Handler
; Called every 1 second (configure SysTick externally to 1Hz)
; increments current_time
; -------------------------
SysTick_Handler
        PUSH    {r0, lr}
        LDR     r0, =current_time
        LDR     r1, [r0]
        ADDS    r1, r1, #1
        STR     r1, [r0]
        POP     {r0, pc}

; -------------------------
; init_scheduler
; (1) Optionally init SysTick in C (I recommend configuring SysTick in C using CMSIS).
; (2) Clears flags and computes initial next_due if desired (we compute on demand).
; Input: none
; -------------------------
init_scheduler
        PUSH    {r4, lr}
        ; clear all flags in med_table (med_count entries)
        LDR     r4, =med_count
        LDR     r4, [r4]            ; r4 = count
        LDR     r1, =med_table
        MOV     r2, #0
init_loop
        CMP     r4, #0
        BEQ     init_done
        ; flags at offset 8 (3rd word)
        LDR     r3, [r1, #8]        ; read flags
        MOVS    r3, #0
        STR     r3, [r1, #8]
        ADD     r1, r1, #12         ; next record
        SUBS    r4, r4, #1
        B       init_loop
init_done
        POP     {r4, pc}

; -------------------------
; update_next_due_for
; Compute next_due_time = last_admin_ts + interval_hours*3600
; Input:
;   r0 = index (0-based)
; Output:
;   r0 = next_due_time (in seconds)
; NOTE: this function DOES NOT store next_due_time; it returns it. The caller can compare to current_time.
; -------------------------
update_next_due_for
        PUSH    {r4, r5, r6, lr}
        MOV     r4, r0              ; index
        LDR     r5, =med_table
        MOVS    r6, #12
        MUL     r6, r6, r4          ; offset = index*12
        ADDS    r5, r5, r6          ; r5 -> record base
        LDR     r1, [r5]            ; r1 = interval_hours
        LDR     r2, [r5, #4]        ; r2 = last_admin_ts

        ; r1 * 3600 => compute r1*3600 = r1* (0xE10)
        ; do r1 * 3600 using 3 multiplies: r1*3600 = r1* (4096 - 496) = r1*4096 - r1*496
        ; simpler: r1 * 3600 = r1 * 3600 using MUL (32-bit)
        MOV     r3, #3600
        MUL     r0, r1, r3          ; r0 = interval_seconds
        ADDS    r0, r0, r2          ; r0 = next_due_time
        ; return in r0
        POP     {r4, r5, r6, pc}

; -------------------------
; check_all_due
; Iterate all meds, compute next_due and set DOSAGE_DUE flag when current_time >= next_due_time
; Input: none
; Output: none (updates flags in med_table)
; -------------------------
check_all_due
        PUSH    {r4, r5, r6, r7, lr}
        LDR     r4, =med_count
        LDR     r4, [r4]            ; r4 = count
        LDR     r5, =med_table
        LDR     r6, =current_time
        LDR     r6, [r6]            ; r6 = current_time
check_loop
        CMP     r4, #0
        BEQ     check_done
        ; load interval and last_admin
        LDR     r1, [r5]            ; interval_hours
        LDR     r2, [r5, #4]        ; last_admin_ts
        ; compute next_due = r2 + r1*3600
        MOV     r7, #3600
        MUL     r0, r1, r7          ; r0 = interval_seconds
        ADDS    r0, r0, r2          ; r0 = next_due

        ; compare current_time (r6) >= next_due (r0)
        CMP     r6, r0
        ; if current_time >= next_due, set flag bit0
        LDR     r3, [r5, #8]        ; flags
        BCC     not_due             ; unsigned compare: if current_time < next_due
        ORR     r3, r3, #1          ; set bit0 = DOSAGE_DUE
        STR     r3, [r5, #8]
        B       skip_store
not_due
        ; clear bit0
        BIC     r3, r3, #1
        STR     r3, [r5, #8]
skip_store
        ADD     r5, r5, #12         ; next record
        SUBS    r4, r4, #1
        B       check_loop
check_done
        POP     {r4, r5, r6, r7, pc}

; -------------------------
; mark_administered
; Update last_admin_ts for a medicine and clear DOSAGE_DUE flag
; Input:
;   r0 = index
;   r1 = timestamp_to_write (if r1==0 => use current_time)
; Output: none
; -------------------------
mark_administered
        PUSH    {r4, r5, r6, lr}
        MOV     r4, r0              ; index
        LDR     r5, =med_table
        MOVS    r6, #12
        MUL     r6, r6, r4
        ADDS    r5, r5, r6          ; r5 -> record base
        CMP     r1, #0
        BNE     use_r1
        LDR     r1, =current_time
        LDR     r1, [r1]
use_r1
        STR     r1, [r5, #4]        ; store last_admin_ts
        LDR     r2, [r5, #8]        ; load flags
        BIC     r2, r2, #1          ; clear DOSAGE_DUE bit
        STR     r2, [r5, #8]
        POP     {r4, r5, r6, pc}

; -------------------------
; uart_send_str (simple polling)
; Input:
;   r0 -> pointer to null-terminated ASCII string
; Uses placeholder registers UART_SR and UART_DR; you must provide correct addresses or replace with write-through CMSIS/UART driver.
; -------------------------
; uart_send_str
;        PUSH    {r1, r2, lr}
;.uart_loop
;        LDRB    r1, [r0], #1
;        CMP     r1, #0
;        BEQ     .uart_done
;        ; wait until UART TX ready: (poll)
;        ; Replace the following with your MCU's UART status check
;.wait_tx
;        LDR     r2, =UART_SR     ; placeholder: address of status register
;        LDR     r2, [r2]
;        TST     r2, #UART_TXE_BIT
;        BEQ     .wait_tx
;        ; write char
;        LDR     r2, =UART_DR
;        STRB    r1, [r2]
;        B       .uart_loop
;.uart_done
;        POP     {r1, r2, pc}

        END
