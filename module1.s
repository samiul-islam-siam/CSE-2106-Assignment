        AREA    module1_code, CODE, READONLY
        EXPORT  main
        THUMB

; ---------------------------------------------------------
; Predefined RAM location for the Patient Record
PATIENT_BASE   	EQU     0x20000000      ; Start of patient record structure

; Test values
PATIENT_ID     	EQU     0x12345678
NAME_PTR       	EQU     0x20001000      ; Address of the name
AGE_VALUE      	EQU     25
WARD_NUMBER    	EQU     0x0032          
TREATMENT_CODE 	EQU     0x07
ROOM_RATE      	EQU     3500
MED_LIST_PTR   	EQU     0x20002000      ; Address of the medical list

; ---------------------------------------------------------
main
        ; Load base pointer to R0
        LDR     R0, =PATIENT_BASE

        ; -------------------------------------------------
        ; Store Patient ID (32-bit)
        LDR     R1, =PATIENT_ID
        STR     R1, [R0, #0]

        ; Store Name Pointer (32-bit)
        LDR     R1, =NAME_PTR
        STR     R1, [R0, #4]

        ; Store Age (8-bit)
        MOV     R1, #AGE_VALUE
        STRB    R1, [R0, #8]

        ; Store Ward Number (16-bit)
        LDR     R1, =WARD_NUMBER
        STRH    R1, [R0, #10]

        ; Store Treatment Code (8-bit)
        MOV     R1, #TREATMENT_CODE
        STRB    R1, [R0, #12]

        ; Store Room Daily Rate (32-bit)
        LDR     R1, =ROOM_RATE
        STR     R1, [R0, #16]

        ; Store Medicine List Pointer (32-bit)
        LDR     R1, =MED_LIST_PTR
        STR     R1, [R0, #20]

STOP
        B       STOP

        END
