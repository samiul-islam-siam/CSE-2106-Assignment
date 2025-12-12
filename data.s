; ================================================================================
; SmartCare-32: ARM-Based Healthcare Monitoring & Billing System
; File: data.s - FIXED: 16-byte alerts, 5 max, BILLING_OFF=0x94
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
; STRUCTURE CONSTANTS
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

ALERT_SIZE      EQU     16      ; CHANGED from 12
ALERT_COUNT     EQU     5       ; Keep 5 alerts

BILLING_SIZE    EQU     24

PATIENT_SIZE            EQU     184     ; CHANGED from 152

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
BILLING_OFF             EQU     0x94    ; MOVED from 0x80

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
; MEDICINE LISTS
; ==============================================================================
        ALIGN 4
medicine_list_p1
		DCB 1
        DCB 6
        DCB 0,0
        DCD 0
		DCD 50
		DCW 10
        DCB 0,0

        DCB 2
        DCB 8
        DCB 0,0
        DCD 0
        DCD 120
        DCW 5
        DCB 0,0

        DCB 3
        DCB 12
        DCB 0,0
        DCD 0
        DCD 200
        DCW 3
        DCB 0,0


        ALIGN 4
medicine_list_p2
        DCB 4
        DCB 4
        DCB 0,0
        DCD 0
        DCD 80
        DCW 8
        DCB 0,0

        DCB 5
        DCB 6
        DCB 0,0
        DCD 0
        DCD 150
        DCW 4
        DCB 0,0


        ALIGN 4
medicine_list_p3
        DCB 6
        DCB 24
        DCB 0,0
        DCD 0
        DCD 300
        DCW 2
        DCB 0,0


; ==============================================================================
; PATIENT ARRAY - 184 bytes each
; ==============================================================================
        ALIGN   4
patient_array

; ------------------------------------------------------------------------------
; Patient 1: John Doe
; ------------------------------------------------------------------------------
patient1
        DCD     1001                    ; +0x00: patient_id
        DCD     patient1_name           ; +0x04: name_ptr
        DCB     45                      ; +0x08: age
        DCB     5                       ; +0x09: treatment_code
        DCW     101                     ; +0x0A: ward_number
        DCD     2000                    ; +0x0C: room_daily_rate
        DCD     medicine_list_p1        ; +0x10: medicine_list_ptr
        DCB     3                       ; +0x14: medicine_count
        DCB     2                       ; +0x15: alert_count
        DCW     7                       ; +0x16: stay_days
        ; +0x18: vital_buffer[10] = 40 bytes
        SPACE   40
        ; +0x40: vital_buffer_index, alert_flag, dosage_due_flag, padding
        DCB     0,0,0,0
        ; +0x44: alert_buffer[5] = 80 bytes
        SPACE   80
        ; +0x94: Billing (24 bytes)
        DCD     0                       ; +0x94: treatment_cost
        DCD     0                       ; +0x98: room_cost
        DCD     0                       ; +0x9C: medicine_cost
        DCD     3000                    ; +0xA0: lab_test_cost
        DCD     0                       ; +0xA4: total_bill
        DCD     0                       ; +0xA8: overflow_flag


; ------------------------------------------------------------------------------
; Patient 2: Jane Smith
; ------------------------------------------------------------------------------
patient2
        DCD     1002
        DCD     patient2_name
        DCB     32
        DCB     2
        DCW     102
        DCD     5000
        DCD     medicine_list_p2
        DCB     2
        DCB     0
        DCW     12
        SPACE   40
        DCB     0,0,0,0
        SPACE   80
        DCD     0
        DCD     0
        DCD     0
        DCD     8000
        DCD     0
        DCD     0


; ------------------------------------------------------------------------------
; Patient 3: Bob Wilson
; ------------------------------------------------------------------------------
patient3
        DCD     1003
        DCD     patient3_name
        DCB     67
        DCB     6
        DCW     201
        DCD     3000
        DCD     medicine_list_p3
        DCB     1
        DCB     5
        DCW     5
        SPACE   40
        DCB     0,0,0,0
        SPACE   80
        DCD     0
        DCD     0
        DCD     0
        DCD     2500
        DCD     0
        DCD     0

; ==============================================================================
; MODULE 11: ERROR DETECTION DATA STRUCTURES
; ==============================================================================

ERROR_SENSOR_MALFUNCTION    EQU     0x01
ERROR_INVALID_DOSAGE        EQU     0x02
ERROR_MEMORY_OVERFLOW       EQU     0x03

ERROR_RECORD_SIZE           EQU     16
MAX_ERROR_RECORDS           EQU     50

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
