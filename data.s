; ==============================================================================
; SmartCare-32: Healthcare Monitoring & Billing System
; File: data.s - Data Sections, Structures, and Constants
; ARM Cortex-M4 Assembly for Keil uVision
; ==============================================================================

        AREA    PatientData, DATA, READWRITE
        ALIGN   4

; ==============================================================================
; EXPORT DECLARATIONS
; ==============================================================================
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

; ==============================================================================
; CONSTANTS
; ==============================================================================
; Patient Structure Layout (byte offsets):
; +0x00: patient_id (4 bytes)
; +0x04: name_ptr (4 bytes)
; +0x08: age (1 byte)
; +0x09: treatment_code (1 byte)
; +0x0A: ward_number (2 bytes)
; +0x0C: room_daily_rate (4 bytes)
; +0x10: medicine_list_ptr (4 bytes)
; +0x14: medicine_count (1 byte)
; +0x15: alert_count (1 byte)
; +0x16: stay_days (2 bytes)
; +0x18: vital_buffer[10] (40 bytes) - 10 * 4 bytes per VitalSign
; +0x40: vital_buffer_index (1 byte)
; +0x41: alert_flag (1 byte)
; +0x42: dosage_due_flag (1 byte)
; +0x43: padding (1 byte)
; +0x44: alert_buffer[20] (320 bytes) - 20 * 16 bytes per AlertRecord
; +0x184: billing structure (24 bytes)
; Total: 0x19C = 412 bytes per patient

PATIENT_SIZE    EQU     412             ; Size of Patient structure in bytes
VITAL_SIZE      EQU     4               ; Size of VitalSign structure (4 bytes)
VITAL_COUNT     EQU     10              ; Number of vital sign entries in buffer
ALERT_SIZE      EQU     16              ; Size of AlertRecord structure
ALERT_COUNT     EQU     20              ; Number of alert records in buffer
BILLING_SIZE    EQU     24              ; Size of Billing structure

; Patient structure offsets
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

; Billing structure offsets (relative to billing start)
TREATMENT_COST_OFF      EQU     0x00
ROOM_COST_OFF           EQU     0x04
MEDICINE_COST_OFF       EQU     0x08
LAB_TEST_COST_OFF       EQU     0x0C
TOTAL_BILL_OFF          EQU     0x10
OVERFLOW_FLAG_OFF       EQU     0x14

; ==============================================================================
; SIMULATED SENSOR MEMORY ADDRESSES
; These represent hardware sensor registers in a real system
; ==============================================================================
        ALIGN   4
SENSOR_HR       SPACE   1               ; Heart Rate sensor (0-255 bpm)
        ALIGN   4
SENSOR_O2       SPACE   1               ; Oxygen saturation (0-100%)
        ALIGN   4
SENSOR_SBP      SPACE   1               ; Systolic Blood Pressure
        ALIGN   4
SENSOR_DBP      SPACE   1               ; Diastolic Blood Pressure
        ALIGN   4

; ==============================================================================
; SYSTEM CLOCK COUNTER
; ==============================================================================
        ALIGN   4
system_clock    DCD     0               ; Global system clock counter

; ==============================================================================
; PATIENT COUNT
; ==============================================================================
        ALIGN   4
patient_count   DCD     3               ; Number of patients in system

; ==============================================================================
; TREATMENT COST LOOKUP TABLE
; Maps treatment codes (0-15) to cost values
; ==============================================================================
        ALIGN   4
treatment_cost_table
        DCD     5000                    ; Code 0: Basic checkup
        DCD     15000                   ; Code 1: Minor surgery
        DCD     50000                   ; Code 2: Major surgery
        DCD     8000                    ; Code 3: Diagnostic tests
        DCD     12000                   ; Code 4: Physical therapy
        DCD     25000                   ; Code 5: ICU admission
        DCD     30000                   ; Code 6: Emergency care
        DCD     10000                   ; Code 7: Consultation
        DCD     20000                   ; Code 8: Imaging
        DCD     18000                   ; Code 9: Laboratory
        DCD     22000                   ; Code 10: Cardiology
        DCD     27000                   ; Code 11: Neurology
        DCD     16000                   ; Code 12: Orthopedics
        DCD     14000                   ; Code 13: Pediatrics
        DCD     19000                   ; Code 14: Oncology
        DCD     21000                   ; Code 15: Radiology

; ==============================================================================
; PATIENT NAME STRINGS
; ==============================================================================
        ALIGN   4
patient1_name   DCB     "John Doe", 0
        ALIGN   4
patient2_name   DCB     "Jane Smith", 0
        ALIGN   4
patient3_name   DCB     "Bob Wilson", 0
        ALIGN   4

; ==============================================================================
; PATIENT ARRAY - 3 Patients
; Each patient is 412 bytes
; ==============================================================================
        ALIGN   4
patient_array
; ------------------------------------------------------------------------------
; Patient 1: John Doe
; Treatment code: 5 (ICU admission)
; Alert count: 2 (simulating critical patient)
; ------------------------------------------------------------------------------
patient1
        DCD     1001                    ; +0x00: patient_id
        DCD     patient1_name           ; +0x04: name_ptr
        DCB     45                      ; +0x08: age
        DCB     5                       ; +0x09: treatment_code (ICU admission)
        DCW     101                     ; +0x0A: ward_number
        DCD     2000                    ; +0x0C: room_daily_rate
        DCD     0                       ; +0x10: medicine_list_ptr (NULL for now)
        DCB     3                       ; +0x14: medicine_count
        DCB     2                       ; +0x15: alert_count (HIGH - critical)
        DCW     7                       ; +0x16: stay_days
        ; +0x18: vital_buffer[10] - 40 bytes (10 x 4 bytes)
        SPACE   40
        DCB     0                       ; +0x40: vital_buffer_index
        DCB     0                       ; +0x41: alert_flag
        DCB     0                       ; +0x42: dosage_due_flag
        DCB     0                       ; +0x43: padding
        ; +0x44: alert_buffer[20] - 320 bytes (20 x 16 bytes)
        SPACE   320
        ; +0x184: billing structure - 24 bytes
        DCD     0                       ; treatment_cost
        DCD     0                       ; room_cost
        DCD     0                       ; medicine_cost
        DCD     3000                    ; lab_test_cost
        DCD     0                       ; total_bill
        DCD     0                       ; overflow_flag + padding

; ------------------------------------------------------------------------------
; Patient 2: Jane Smith
; Treatment code: 2 (Major surgery)
; Alert count: 0 (stable patient)
; ------------------------------------------------------------------------------
patient2
        DCD     1002                    ; +0x00: patient_id
        DCD     patient2_name           ; +0x04: name_ptr
        DCB     32                      ; +0x08: age
        DCB     2                       ; +0x09: treatment_code (Major surgery)
        DCW     102                     ; +0x0A: ward_number
        DCD     5000                    ; +0x0C: room_daily_rate
        DCD     0                       ; +0x10: medicine_list_ptr
        DCB     2                       ; +0x14: medicine_count
        DCB     0                       ; +0x15: alert_count (LOW - stable)
        DCW     12                      ; +0x16: stay_days
        ; +0x18: vital_buffer[10]
        SPACE   40
        DCB     0                       ; +0x40: vital_buffer_index
        DCB     0                       ; +0x41: alert_flag
        DCB     0                       ; +0x42: dosage_due_flag
        DCB     0                       ; +0x43: padding
        ; +0x44: alert_buffer[20]
        SPACE   320
        ; +0x184: billing structure
        DCD     0                       ; treatment_cost
        DCD     0                       ; room_cost
        DCD     0                       ; medicine_cost
        DCD     8000                    ; lab_test_cost
        DCD     0                       ; total_bill
        DCD     0                       ; overflow_flag + padding

; ------------------------------------------------------------------------------
; Patient 3: Bob Wilson
; Treatment code: 6 (Emergency care)
; Alert count: 5 (most critical patient)
; ------------------------------------------------------------------------------
patient3
        DCD     1003                    ; +0x00: patient_id
        DCD     patient3_name           ; +0x04: name_ptr
        DCB     67                      ; +0x08: age
        DCB     6                       ; +0x09: treatment_code (Emergency care)
        DCW     201                     ; +0x0A: ward_number
        DCD     3000                    ; +0x0C: room_daily_rate
        DCD     0                       ; +0x10: medicine_list_ptr
        DCB     1                       ; +0x14: medicine_count
        DCB     5                       ; +0x15: alert_count (HIGHEST - most critical)
        DCW     5                       ; +0x16: stay_days
        ; +0x18: vital_buffer[10]
        SPACE   40
        DCB     0                       ; +0x40: vital_buffer_index
        DCB     0                       ; +0x41: alert_flag
        DCB     0                       ; +0x42: dosage_due_flag
        DCB     0                       ; +0x43: padding
        ; +0x44: alert_buffer[20]
        SPACE   320
        ; +0x184: billing structure
        DCD     0                       ; treatment_cost
        DCD     0                       ; room_cost
        DCD     0                       ; medicine_cost
        DCD     2500                    ; lab_test_cost
        DCD     0                       ; total_bill
        DCD     0                       ; overflow_flag + padding

        END
