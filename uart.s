; ================================================================================
; SmartCare-32: ARM-Based Healthcare Monitoring & Billing System
; File: uart.s - UART simulation helper function
; ================================================================================    
	
	AREA 	UART_Code, CODE, READONLY
    THUMB
    EXPORT 	ITM_SendChar
    EXPORT 	ITM_Init

; ---------------------------
; void ITM_SendChar(char ch)
; parameter: r0 = character (lower 8 bits)
; ---------------------------
ITM_SendChar
    PUSH    {lr}

_wait_port0
    LDR     r1, =0xE0000000    ; address of ITM_PORT0
    LDR     r2, [r1]           ; read ITM_PORT0
    ANDS    r2, r2, #1         ; test bit0 (ready)
    BEQ     _wait_port0        ; loop while not ready

    STR     r0, [r1]           ; write 32-bit value to ITM_PORT0

    POP     {lr}
    BX      lr

; ---------------------------
; void ITM_Init(void)
; ---------------------------
ITM_Init
    PUSH    {lr}

    LDR     r1, =0xE0000E80    ; address of ITM_TCR
    LDR     r0, =0x0001000D    ; value for TCR
    STR     r0, [r1]

    LDR     r1, =0xE0000E00    ; address of ITM_TER
    LDR     r0, =0x00000001    ; value for TER
    STR     r0, [r1]

    POP     {lr}
    BX      lr

    END
