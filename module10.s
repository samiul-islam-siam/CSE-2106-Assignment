;===============================================================================
; SmartCare-32: Module 10 - UART Summary Report Generator
; Purpose: Bridge module that calls C functions from main.c
; This module serves as the interface between assembly and C code
;===============================================================================

    AREA module10, CODE, READONLY
    THUMB
    
    ; Export functions for other modules to call
    EXPORT UART_Init
    EXPORT Generate_Summary_Report
    EXPORT Generate_All_Patient_Reports
    
    ; Import C functions from main. c
    IMPORT Generate_UART_Reports      ; Main C function
    IMPORT UART_Init_C                ; C UART init function
    IMPORT PrintPatientReport_C       ; C report printing function

;-------------------------------------------------------------------------------
; UART_Init
; Purpose: Initialize UART by calling C function
; Input: None
; Output: None
;-------------------------------------------------------------------------------
UART_Init PROC
    PUSH    {LR}
    
    ; Call C function to initialize UART
    BL      UART_Init_C
    
    POP     {PC}
    ENDP

;-------------------------------------------------------------------------------
; Generate_Summary_Report
; Purpose: Generate summary report by calling C function
; Input: None
; Output: None
;-------------------------------------------------------------------------------
Generate_Summary_Report PROC
    PUSH    {LR}
    
    ; Call C function to generate reports
    BL      Generate_UART_Reports
    
    POP     {PC}
    ENDP

;-------------------------------------------------------------------------------
; Generate_All_Patient_Reports
; Purpose: Generate reports for all patients by calling C function
; Input: None
; Output: None
;-------------------------------------------------------------------------------
Generate_All_Patient_Reports PROC
    PUSH    {LR}
    
    ; Call C function to generate all reports
    BL      Generate_UART_Reports
    
    POP     {PC}
    ENDP

    END