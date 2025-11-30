        AREA 	|.text|, CODE, READONLY
        EXPORT 	main

; -----------------------------------------------------------------------------
; ITM Register Addresses (CoreSight)
; -----------------------------------------------------------------------------
ITM_BASE        EQU     0xE0000000
ITM_PORT0       EQU     (ITM_BASE + 0x000)
ITM_TER         EQU     (ITM_BASE + 0xE00)
ITM_TCR         EQU     (ITM_BASE + 0xE80)

; -----------------------------------------------------------------------------
; main
; -----------------------------------------------------------------------------
main
        ; Enable ITM (needed for Keil "Serial Window UART1")
        LDR     R0, =ITM_TCR
        LDR     R1, =0x0001000D   ; Enable ITM + Trace
        STR     R1, [R0]

        ; Enable stimulus port 0
        LDR     R0, =ITM_TER
        MOV     R1, #1
        STR     R1, [R0]

        ; Pointer to message
        LDR     R4, =message

next_char
        LDRB    R0, [R4], #1
        CMP     R0, #0
        BEQ     done

send_char
        LDR     R1, =ITM_PORT0
wait_u
        LDR     R2, [R1]
        TST     R2, #1            ; Check if ITM is ready
        BEQ     wait_u

        STR     R0, [R1]          ; Send byte
        B       next_char

done
        B       done              ; Loop forever

; -----------------------------------------------------------------------------
; Text message
; -----------------------------------------------------------------------------
        AREA 	|.rodata|, DATA, READONLY
message
        DCB 	"Hello from ARM Cortex-M4 UART1!", 0x0D,0x0A, 0

        END
			
; 0x0D: carriage return (CR), ASCII code 13.
; Moves the cursor to the beginning of the line.

; 0x0A: line feed (LF), ASCII code 10.
; Moves the cursor down to the next line.

; 0x0D 0x0A = CR + LF
; This is the standard new line in serial terminals (Windows-style).