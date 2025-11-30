; ==============================================================================
; SmartCare-32: Healthcare Monitoring & Billing System
; File: data.s - Data Sections, Structures, and Constants
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
		
        EXPORT  medicine_list_p1
        EXPORT  medicine_list_p2
        EXPORT  medicine_list_p3

; ================================================================================
; STRUCTURE CONSTANTS
; ================================================================================

; Medicine structure Layout (byte offsets):
MED_ID_OFF             EQU 0x00
DOSAGE_INTERVAL_OFF    EQU 0x01
LAST_ADMIN_TIME_OFF    EQU 0x04
UNIT_PRICE_OFF         EQU 0x08
QUANTITY_OFF           EQU 0x0C
MED_PADDING_OFF        EQU 0x0E
MEDICINE_SIZE          EQU 0x10

; Patient Structure Layout (UPDATED for C compatibility):
; +0x00: patient_id (4 bytes)
; +0x04: age (4 bytes) - changed from 1 byte for alignment
; +0x08: ward_number (4 bytes) - changed from 2 bytes
; +0x0C: heart_rate (4 bytes) - ADDED for direct access
; +0x10: sbp (4 bytes) - ADDED for direct access
; +0x14: dbp (4 bytes) - ADDED for direct access
; +0x18: o2 (4 bytes) - ADDED for direct access
; +0x1C: temperature (4 bytes) - ADDED for direct access
; +0x20: name_ptr (4 bytes)
; +0x24: treatment_code (1 byte)
; +0x25: medicine_count (1 byte)
; +0x26: alert_count (1 byte)
; +0x27: padding (1 byte)
; +0x28: room_daily_rate (4 bytes)
; +0x2C: medicine_list_ptr (4 bytes)
; +0x30: stay_days (2 bytes)
; +0x32: padding (2 bytes)
; +0x34: vital_buffer[10] (40 bytes)
; +0x5C: vital_buffer_index (1 byte)
; +0x5D: alert_flag (1 byte)
; +0x5E: dosage_due_flag (1 byte)
; +0x5F: padding (1 byte)
; +0x60: alert_buffer[20] (320 bytes)
; +0x1A0: billing structure (24 bytes)
; Total: adjusted to 412 bytes

PATIENT_SIZE            EQU     412

; Updated offsets for C compatibility
PATIENT_ID_OFF          EQU     0x00
PATIENT_AGE_OFF         EQU     0x04
WARD_OFF                EQU     0x08
HR_OFF                  EQU     0x0C
SBP_OFF                 EQU     0x10
DBP_OFF                 EQU     0x14
O2_OFF                  EQU     0x18
TEMP_OFF                EQU     0x1C
NAME_PTR_OFF            EQU     0x20
TREATMENT_CODE_OFF      EQU     0x24
MEDICINE_COUNT_OFF      EQU     0x25
ALERT_COUNT_OFF         EQU     0x26
ROOM_DAILY_RATE_OFF     EQU     0x28
MEDICINE_LIST_PTR_OFF   EQU     0x2C
STAY_DAYS_OFF           EQU     0x30
VITAL_BUFFER_OFF        EQU     0x34
VITAL_BUFFER_INDEX_OFF  EQU     0x5C
ALERT_FLAG_OFF          EQU     0x5D
DOSAGE_DUE_FLAG_OFF     EQU     0x5E
ALERT_BUFFER_OFF        EQU     0x60
BILLING_OFF             EQU     0x1A0

; Keep these for backward compatibility with your other modules
AGE_OFF                 EQU     0x04
WARD_NUMBER_OFF         EQU     0x08

; Billing structure offsets
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
        DCD     5000                    ; Code 0
        DCD     15000                   ; Code 1
        DCD     50000                   ; Code 2
        DCD     8000                    ; Code 3
        DCD     12000                   ; Code 4
        DCD     25000                   ; Code 5
        DCD     30000                   ; Code 6
        DCD     10000                   ; Code 7
        DCD     20000                   ; Code 8
        DCD     18000                   ; Code 9
        DCD     22000                   ; Code 10
        DCD     27000                   ; Code 11
        DCD     16000                   ; Code 12
        DCD     14000                   ; Code 13
        DCD     19000                   ; Code 14
        DCD     21000                   ; Code 15


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
        DCB 1                   ; medicine_id
        DCB 6                   ; dosage_interval
        DCB 0,0                 ; padding
        DCD 0                   ; last_administered_time
        DCD 50                  ; unit_price
        DCW 10                  ; quantity
        DCB 0,0                 ; padding

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
; PATIENT ARRAY - 3 Patients (UPDATED STRUCTURE)
; ==============================================================================
        ALIGN   4
patient_array

; ------------------------------------------------------------------------------
; Patient 1: John Doe
; ------------------------------------------------------------------------------
patient1
        DCD     1001                    ; +0x00: patient_id
        DCD     45                      ; +0x04: age (now 4 bytes)
        DCD     101                     ; +0x08: ward_number (now 4 bytes)
        DCD     125                     ; +0x0C: heart_rate (ADDED)
        DCD     135                     ; +0x10: sbp (ADDED)
        DCD     85                      ; +0x14: dbp (ADDED)
        DCD     88                      ; +0x18: o2 (ADDED)
        DCD     38                      ; +0x1C: temperature (ADDED)
        DCD     patient1_name           ; +0x20: name_ptr
        DCB     5                       ; +0x24: treatment_code
        DCB     3                       ; +0x25: medicine_count
        DCB     2                       ; +0x26: alert_count
        DCB     0                       ; +0x27: padding
        DCD     2000                    ; +0x28: room_daily_rate
        DCD     medicine_list_p1        ; +0x2C: medicine_list_ptr
        DCW     7                       ; +0x30: stay_days
        DCW     0                       ; +0x32: padding
        SPACE   40                      ; +0x34: vital_buffer[10]
        DCB     0                       ; +0x5C: vital_buffer_index
        DCB     0                       ; +0x5D: alert_flag
        DCB     0                       ; +0x5E: dosage_due_flag
        DCB     0                       ; +0x5F: padding
        SPACE   320                     ; +0x60: alert_buffer[20]
        DCD     0                       ; +0x1A0: treatment_cost
        DCD     0                       ; room_cost
        DCD     0                       ; medicine_cost
        DCD     3000                    ; lab_test_cost
        DCD     0                       ; total_bill
        DCD     0                       ; overflow_flag


; ------------------------------------------------------------------------------
; Patient 2: Jane Smith
; ------------------------------------------------------------------------------
patient2
        DCD     1002                    ; +0x00: patient_id
        DCD     32                      ; +0x04: age
        DCD     102                     ; +0x08: ward_number
        DCD     78                      ; +0x0C: heart_rate
        DCD     120                     ; +0x10: sbp
        DCD     80                      ; +0x14: dbp
        DCD     98                      ; +0x18: o2
        DCD     37                      ; +0x1C: temperature
        DCD     patient2_name           ; +0x20: name_ptr
        DCB     2                       ; +0x24: treatment_code
        DCB     2                       ; +0x25: medicine_count
        DCB     0                       ; +0x26: alert_count
        DCB     0                       ; +0x27: padding
        DCD     5000                    ; +0x28: room_daily_rate
        DCD     medicine_list_p2        ; +0x2C: medicine_list_ptr
        DCW     12                      ; +0x30: stay_days
        DCW     0                       ; +0x32: padding
        SPACE   40                      ; +0x34: vital_buffer
        DCB     0                       ; +0x5C: vital_buffer_index
        DCB     0                       ; +0x5D: alert_flag
        DCB     0                       ; +0x5E: dosage_due_flag
        DCB     0                       ; +0x5F: padding
        SPACE   320                     ; +0x60: alert_buffer
        DCD     0                       ; +0x1A0: billing
        DCD     0
        DCD     0
        DCD     8000
        DCD     0
        DCD     0


; ------------------------------------------------------------------------------
; Patient 3: Bob Wilson
; ------------------------------------------------------------------------------
patient3
        DCD     1003                    ; +0x00: patient_id
        DCD     67                      ; +0x04: age
        DCD     201                     ; +0x08: ward_number
        DCD     165                     ; +0x0C: heart_rate
        DCD     170                     ; +0x10: sbp
        DCD     95                      ; +0x14: dbp
        DCD     85                      ; +0x18: o2
        DCD     39                      ; +0x1C: temperature
        DCD     patient3_name           ; +0x20: name_ptr
        DCB     6                       ; +0x24: treatment_code
        DCB     1                       ; +0x25: medicine_count
        DCB     5                       ; +0x26: alert_count
        DCB     0                       ; +0x27: padding
        DCD     3000                    ; +0x28: room_daily_rate
        DCD     medicine_list_p3        ; +0x2C: medicine_list_ptr
        DCW     5                       ; +0x30: stay_days
        DCW     0                       ; +0x32: padding
        SPACE   40                      ; +0x34: vital_buffer
        DCB     0                       ; +0x5C: vital_buffer_index
        DCB     0                       ; +0x5D: alert_flag
        DCB     0                       ; +0x5E: dosage_due_flag
        DCB     0                       ; +0x5F: padding
        SPACE   320                     ; +0x60: alert_buffer
        DCD     0                       ; +0x1A0: billing
        DCD     0
        DCD     0
        DCD     2500
        DCD     0
        DCD     0

        END
