; ================================================================================
; SmartCare-32: ARM-Based Healthcare Monitoring & Billing System
; File: data.s - Data Sections, Structures, and Constants (MODIFIED FOR VIVA)
; ================================================================================
	
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
		
		EXPORT	medicine_list_p1
		EXPORT	medicine_list_p2
		EXPORT	medicine_list_p3

; =================================================================================
; STRUCTURE CONSTANTS (SAME AS ORIGINAL)
; =================================================================================

MED_ID_OFF             EQU 0x00
DOSAGE_INTERVAL_OFF    EQU 0x01
LAST_ADMIN_TIME_OFF    EQU 0x04
UNIT_PRICE_OFF         EQU 0x08
QUANTITY_OFF           EQU 0x0C
MED_PADDING_OFF        EQU 0x0E
MEDICINE_SIZE          EQU 0x10

VITAL_SIZE      EQU     4
VITAL_COUNT     EQU     10
ALERT_SIZE      EQU     16
ALERT_COUNT     EQU     10
BILLING_SIZE    EQU     24
PATIENT_SIZE            EQU     252

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
BILLING_OFF             EQU     0xE4

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
; TREATMENT COST TABLE (MODIFIED - SIMPLE VALUES)
; ==============================================================================
        ALIGN   4
treatment_cost_table
        DCD     1000                    ; Code 0
        DCD     2000                    ; Code 1
        DCD     3000                    ; Code 2
        DCD     4000                    ; Code 3
        DCD     5000                    ; Code 4
        DCD     6000                    ; Code 5
        DCD     7000                    ; Code 6
        DCD     8000                    ; Code 7
        DCD     9000                    ; Code 8
        DCD     1500                    ; Code 9
        DCD     2500                    ; Code 10
        DCD     3500                    ; Code 11
        DCD     4500                    ; Code 12
        DCD     5500                    ; Code 13
        DCD     6500                    ; Code 14
        DCD     7500                    ; Code 15

; ==============================================================================
; PATIENT NAME STRINGS (MODIFIED - SIMPLE NAMES)
; ==============================================================================
        ALIGN   4
patient1_name   DCB     "Alice",0
        ALIGN   4
patient2_name   DCB     "Bob",0
        ALIGN   4
patient3_name   DCB     "Carol",0
        ALIGN   4

; ==============================================================================
; MEDICINE LISTS (MODIFIED - SIMPLE VALUES)
; ==============================================================================

        ALIGN 4
medicine_list_p1
; Medicine 1
		DCB 1
        DCB 6
        DCB 0,0
        DCD 0
		DCD 5
		DCW 2
        DCB 0,0
; Medicine 2
        DCB 2
        DCB 8
        DCB 0,0
        DCD 0
        DCD 3
        DCW 4
        DCB 0,0

        ALIGN 4
medicine_list_p2
; Medicine 1
        DCB 3
        DCB 4
        DCB 0,0
        DCD 0
        DCD 7
        DCW 1
        DCB 0,0
; Medicine 2
        DCB 4
        DCB 6
        DCB 0,0
        DCD 0
        DCD 9
        DCW 3
        DCB 0,0

        ALIGN 4
medicine_list_p3
        DCB 5
        DCB 8
        DCB 0,0
        DCD 0
        DCD 4
        DCW 5
        DCB 0,0

; ==============================================================================
; PATIENT ARRAY (MODIFIED - SIMPLE VALUES)
; ==============================================================================
        ALIGN   4
patient_array

; Patient 1: Alice (ID=101, Age=25, Ward=5, Treatment=2, Alert=1)
patient1
        DCD     101
        DCD     patient1_name
        DCB     25
        DCB     2
        DCW     5
        DCD     100
        DCD     medicine_list_p1
        DCB     2
        DCB     1
        DCW     8
        SPACE   40
        DCB     0,0,0,0
        SPACE   160
        DCD     0,0,0
        DCD     200
        DCD     0,0

; Patient 2: Bob (ID=202, Age=45, Ward=7, Treatment=5, Alert=3)
patient2
        DCD     202
        DCD     patient2_name
        DCB     45
        DCB     5
        DCW     7
        DCD     150
        DCD     medicine_list_p2
        DCB     2
        DCB     3
        DCW     6
        SPACE   40
        DCB     0,0,0,0
        SPACE   160
        DCD     0,0,0
        DCD     300
        DCD     0,0

; Patient 3: Carol (ID=303, Age=35, Ward=3, Treatment=0, Alert=0)
patient3
        DCD     303
        DCD     patient3_name
        DCB     35
        DCB     0
        DCW     3
        DCD     80
        DCD     medicine_list_p3
        DCB     1
        DCB     0
        DCW     9
        SPACE   40
        DCB     0,0,0,0
        SPACE   160
        DCD     0,0,0
        DCD     100
        DCD     0,0

; ==============================================================================
; MODULE 11: ERROR DETECTION DATA STRUCTURES
; ==============================================================================

ERROR_SENSOR_MALFUNCTION    EQU     0x01
ERROR_INVALID_DOSAGE        EQU     0x02
ERROR_MEMORY_OVERFLOW       EQU     0x03

ERROR_RECORD_SIZE           EQU     16
MAX_ERROR_RECORDS           EQU     20

        ALIGN   4
error_flag      DCD     0

        ALIGN   4
error_log_buffer
        SPACE   (ERROR_RECORD_SIZE * MAX_ERROR_RECORDS)

        ALIGN   4
error_count     DCD     0

        ALIGN   4
sensor_history
hr_history      SPACE   10
o2_history      SPACE   10
sbp_history     SPACE   10
dbp_history     SPACE   10

sensor_history_index    DCB     0
        ALIGN   4

        EXPORT  error_flag
        EXPORT  error_log_buffer
        EXPORT  error_count
        EXPORT  sensor_history
        EXPORT  sensor_history_index

        END