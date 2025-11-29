; ==============================================================================
; SmartCare-32: Healthcare Monitoring & Billing System
; File: data_fixed.s - Data Sections, Structures, and Constants (FIXED)
; ARM Cortex-M4 Assembly for Keil uVision
; ==============================================================================
	
        AREA    PatientData, DATA, READWRITE
        ALIGN   4

; ================================================================================
; EXPORT DECLARATIONS
; ================================================================================
        EXPORT  patient_array
        EXPORT  treatment_cost_table
        EXPORT  SENSOR_HR
        EXPORT  SENSOR_O2
        EXPORT  SENSOR_SBP
        EXPORT  SENSOR_DBP
        EXPORT  system_clock
        EXPORT  patient_count
        EXPORT  patient1_name
        EXPORT  patient2_name
        EXPORT  patient3_name

; ================================================================================
; STRUCTURE CONSTANTS
; ================================================================================

; --- Medicine structure ---
; C structure:
; uint8_t  medicine_id
; uint8_t  dosage_interval_hours
; uint32_t last_administered_time
; uint32_t unit_price
; uint16_t quantity
; uint8_t  padding[3]

MED_ID_OFF             EQU     0x00
DOSAGE_INTERVAL_OFF    EQU     0x01
LAST_ADMIN_TIME_OFF    EQU     0x02
UNIT_PRICE_OFF         EQU     0x06
QUANTITY_OFF           EQU     0x0A
MED_PADDING_OFF        EQU     0x0C
MEDICINE_SIZE          EQU     0x10        ; 16 bytes

; --- Vital sign ---
VITAL_SIZE      EQU     4
VITAL_COUNT     EQU     10

; --- Alert record ---
ALERT_SIZE      EQU     16
ALERT_COUNT     EQU     20

; --- Billing ---
BILLING_SIZE    EQU     24

; --- Patient structure offsets ---
PATIENT_SIZE            EQU     412

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

; --- Billing subfields ---
TREATMENT_COST_OFF      EQU     0x00
ROOM_COST_OFF           EQU     0x04
MEDICINE_COST_OFF       EQU     0x08
LAB_TEST_COST_OFF       EQU     0x0C
TOTAL_BILL_OFF          EQU     0x10
OVERFLOW_FLAG_OFF       EQU     0x14


; ==============================================================================
; SIMULATED SENSOR MEMORY ADDRESSES
; ==============================================================================
        ALIGN   4
SENSOR_HR       SPACE   1
        ALIGN   4
SENSOR_O2       SPACE   1
        ALIGN   4
SENSOR_SBP      SPACE   1
        ALIGN   4
SENSOR_DBP      SPACE   1
        ALIGN   4


; ==============================================================================
; SYSTEM CLOCK COUNTER
; ==============================================================================
system_clock    DCD     0


; ==============================================================================
; PATIENT COUNT
; ==============================================================================
patient_count   DCD     3


; ==============================================================================
; TREATMENT COST TABLE
; ==============================================================================
        ALIGN   4
treatment_cost_table
        DCD     5000
        DCD     15000
        DCD     50000
        DCD     8000
        DCD     12000
        DCD     25000
        DCD     30000
        DCD     10000
        DCD     20000
        DCD     18000
        DCD     22000
        DCD     27000
        DCD     16000
        DCD     14000
        DCD     19000
        DCD     21000


; ==============================================================================
; PATIENT NAME STRINGS
; ==============================================================================
        ALIGN   4
patient1_name   DCB     "John Doe",0
        ALIGN   4
patient2_name   DCB     "Jane Smith",0
        ALIGN   4
patient3_name   DCB     "Bob Wilson",0
        ALIGN   4


; ==============================================================================
; MEDICINE LISTS (Option A) - FIXED: every entry = 16 bytes (padding 4 bytes)
; ==============================================================================

; -------------------------------
; Patient 1 Medicines (3 items = 48 bytes)
; -------------------------------
        ALIGN 4
medicine_list_p1

; Medicine 1 (16 bytes total)
        DCB 1                  ; medicine_id (1)
        DCB 6                  ; dosage interval (1)
        DCD 0                  ; last_administered_time (4)
        DCD 200                ; unit_price (4)
        DCW 10                 ; quantity (2)
        DCB 0,0,0,0            ; padding (4)

; Medicine 2 (16 bytes)
        DCB 2
        DCB 12
        DCD 0
        DCD 150
        DCW 5
        DCB 0,0,0,0

; Medicine 3 (16 bytes)
        DCB 3
        DCB 24
        DCD 0
        DCD 350
        DCW 20
        DCB 0,0,0,0


; -------------------------------
; Patient 2 Medicines (2 items = 32 bytes)
; -------------------------------
        ALIGN 4
medicine_list_p2

        DCB 4
        DCB 8
        DCD 0
        DCD 500
        DCW 30
        DCB 0,0,0,0

        DCB 5
        DCB 24
        DCD 0
        DCD 250
        DCW 12
        DCB 0,0,0,0


; -------------------------------
; Patient 3 Medicines (1 item = 16 bytes)
; -------------------------------
        ALIGN 4
medicine_list_p3

        DCB 6
        DCB 12
        DCD 0
        DCD 100
        DCW 8
        DCB 0,0,0,0


; ==============================================================================
; PATIENT ARRAY
; ==============================================================================
        ALIGN   4
patient_array

; -------------------------------
; Patient 1
; -------------------------------
patient1
        DCD     1001
        DCD     patient1_name
        DCB     45
        DCB     5
        DCW     101
        DCD     2000
        DCD     medicine_list_p1     ; medicine list pointer
        DCB     3                   ; medicine_count
        DCB     2                   ; alert_count
        DCW     7                   ; stay_days
        SPACE   40
        DCB     0
        DCB     0
        DCB     0
        DCB     0
        SPACE   320
        DCD     0
        DCD     0
        DCD     0
        DCD     3000
        DCD     0
        DCD     0


; -------------------------------
; Patient 2
; -------------------------------
patient2
        DCD     1002
        DCD     patient2_name
        DCB     32
        DCB     2
        DCW     102
        DCD     5000
        DCD     medicine_list_p2     ; medicine list pointer
        DCB     2                   ; medicine_count
        DCB     0                   ; alert_count
        DCW     12                  ; stay_days
        SPACE   40
        DCB     0
        DCB     0
        DCB     0
        DCB     0
        SPACE   320
        DCD     0
        DCD     0
        DCD     0
        DCD     8000
        DCD     0
        DCD     0


; -------------------------------
; Patient 3
; -------------------------------
patient3
        DCD     1003
        DCD     patient3_name
        DCB     67
        DCB     6
        DCW     201
        DCD     3000
        DCD     medicine_list_p3     ; medicine list pointer
        DCB     1                   ; medicine_count
        DCB     5                   ; alert_count
        DCW     5                   ; stay_days
        SPACE   40
        DCB     0
        DCB     0
        DCB     0
        DCB     0
        SPACE   320
        DCD     0
        DCD     0
        DCD     0
        DCD     2500
        DCD     0
        DCD     0

        END
