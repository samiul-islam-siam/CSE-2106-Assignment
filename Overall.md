# SmartCare-32: Healthcare Monitoring & Billing System
Complete Documentation for ARM Cortex-M4 Embedded System

## 📋 Table of Contents
- [System Overview](#system-overview)
- [Key Features](#key-features)
- [Architecture](#architecture)
- [Modules](#modules)
- [Module 1–10 (summary)](#module-1–10-summary)
- [Module 11 — Error Detection & Logging (detailed)](#module-11---error-detection--logging-detailed)
- [Memory Layout](#memory-layout)
- [Build & Deployment](#build--deployment)
- [Testing & Verification](#testing--verification)
- [System Health Dashboard](#system-health-dashboard)
- [Appendices](#appendices)
- [License & Credits](#license--credits)


## 🎯 System Overview
SmartCare-32 is a real-time patient monitoring and billing system designed for ARM Cortex-M4 microcontrollers. 
The system manages multiple patients, monitors vital signs, schedules medicine administration, calculates billing, and provides comprehensive error detection.

## Key Features
-  Real-time vital sign monitoring (HR, O2, BP)
-  Automated alert generation for abnormal vitals
-  Medicine dosage scheduling with time tracking
-  Multi-component billing system with overflow protection
-  Patient criticality sorting
-  UART/ITM report generation
-  Advanced error detection & logging (Module 11)
  - Sensor malfunction detection
  - Invalid dosage validation
  - Memory overflow protection
## Technical Specifications
-  Platform	ARM Cortex-M4 (ARMv7E-M)
-  IDE	Keil µVision 5
-  Language	ARM Assembly + C (hybrid)
-  Memory	RAM-based (simulated Flash for error log)
-  Max Patients	3 (expandable)
-  Vital Buffer	10 entries per patient (rolling)
-  Alert Buffer	20 entries per patient
-  Error Log	50 error records (simulated Flash)
## 🏗️ Architecture
#### System Diagram
```
┌─────────────────────────────────────────────────────────────┐
│                    SmartCare-32 System                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐               │
│  │ Patient 1│    │ Patient 2│    │ Patient 3│               │
│  │ (412 B)  │    │ (412 B)  │    │ (412 B)  │               │
│  └────┬─────┘    └────┬─────┘    └────┬─────┘               │
│       │               │               │                     │
│  ┌────▼───────────────▼───────────────▼─────┐               │
│  │         Patient Array (RAM)               │              │
│  └───────────────────────────────────────────┘              │
│                      │                                      │
│       ┌──────────────┼──────────────┐                       │
│       ▼              ▼              ▼                       │
│  ┌────────┐    ┌─────────┐    ┌──────────┐                  │
│  │Modules │    │ Modules │    │ Modules  │                  │
│  │ 1-4    │    │  5-8    │    │  9-11    │                  │
│  │Init &  │    │ Billing │    │Sort &    │                  │
│  │Vitals  │    │         │    │Output    │                  │
│  └────┬───┘    └────┬────┘    └────┬─────┘                  │
│       │             │              │                        │
│       └─────────────┼──────────────┘                        │
│                     ▼                                       │
│            ┌─────────────────┐                              │
│            │ UART/ITM Output │                              │
│            └─────────────────┘                              │   
└─────────────────────────────────────────────────────────────┘
```
#### Module Dependency Flow
```
Module 1 (Init) → Module 2 (Vitals) → Module 11a (Sensor Check)
                                    ↓
                 Module 3 (Alerts) → Module 4 (Medicine) → Module 11b (Dosage Check)
                                                         ↓
Module 5 (Treatment) → Module 6 (Room) → Module 7 (Medicine) → Module 8 (Total)
                                                              ↓
                                           Module 11c (Memory Check)
                                                              ↓
                            Module 9 (Sort) → Module 10 (UART + Error Log)
```
## 📦 Module Descriptions
#### Module 1: Patient Record Initialization
File: module1.s
Function: patient_record_initialization

Purpose: Initializes patient data structure with personal info, treatment details, and medicine list.

Parameters:
```
R0: Patient pointer
R1: Patient ID (32-bit)
R2: Name pointer
R3: Age (8-bit)
```

Stack: ward, treatment_code, room_rate, medicine_list_ptr, medicine_count, stay_days

Key Operations:
Stores all patient fields
Zeros vital buffer (40 bytes)
Zeros alert buffer (320 bytes)
Initializes billing structure
Memory Modified: 412 bytes per patient

#### Module 2: Vital Sign Data Acquisition
File: module2.s
Function: acquire_vital_signs

Purpose: Reads sensor data and stores in rolling buffer (10 entries).

Parameters:

R0: Patient pointer
Sensors Read:

Heart Rate (SENSOR_HR)
Oxygen Level (SENSOR_O2)
Systolic BP (SENSOR_SBP)
Diastolic BP (SENSOR_DBP)
Algorithm:

Code
1. Read all 4 sensors
2. Get current buffer index (0-9)
3. Calculate buffer address: vital_buffer + (index * 4)
4. Store 4 bytes (HR, O2, SBP, DBP)
5. Update index: (index + 1) % 10
Rolling Buffer: Maintains last 10 vital sign readings.

#### Module 3: Vital Threshold Alert Module
File: module3.s
Function: check_vital_thresholds

Purpose: Monitors vital signs and generates alerts for abnormal values.

Thresholds:

Vital	Threshold	Alert Trigger
Heart Rate	> 120 bpm	HIGH
Oxygen (SpO2)	< 92%	LOW
Systolic BP	> 160 or < 90 mmHg	HIGH/LOW
Alert Record (16 bytes):

Code
+0x00: vital_type (0=HR, 1=O2, 2=BP)
+0x01: actual_reading
+0x02: padding
+0x04: timestamp (system_clock)
+0x08: reserved
Actions:

Sets alert_flag = 1
Increments alert_count
Stores alert record in alert_buffer[20]

#### Module 4: Medicine Administration Scheduler
File: module4.s
Function: medicine_administration_scheduler

Purpose: Checks if medicine dosage is due based on time intervals.

Algorithm:

Code
For each medicine:
    next_due_time = last_administered_time + (interval_hours * 3600)
    if (system_clock >= next_due_time):
        dosage_due_flag = 1
        last_administered_time = system_clock
Medicine Structure (16 bytes):

Code
+0x00: medicine_id (1 byte)
+0x01: dosage_interval_hours (1 byte)
+0x04: last_administered_time (4 bytes)
+0x08: unit_price (4 bytes)
+0x0C: quantity (2 bytes)

#### Module 5: Treatment Cost Computation
File: module5.s
Function: compute_treatment_cost

Purpose: Looks up treatment cost from predefined table.

Treatment Cost Table (16 entries):

Code
Code 0:  5,000   (Basic checkup)
Code 1:  15,000  (Minor surgery)
Code 2:  50,000  (Major surgery)
Code 3:  8,000   (Diagnostic tests)
Code 4:  12,000  (Physical therapy)
Code 5:  25,000  (ICU admission)
Code 6:  30,000  (Emergency care)
... 
Code 15: 21,000  (Radiology)
Validation: Returns 0 if code >= 16.

#### Module 6: Daily Room Rent Calculation
File: module6.s
Function: compute_room_cost

Purpose: Calculates room charges with discount for long stays.

Formula:

Code
room_cost = room_daily_rate * stay_days

if (stay_days > 10):
    room_cost = room_cost * 0.95  // 5% discount
Implementation:

Assembly
MUL     R3, R1, R2          ; cost = rate * days
CMP     R2, #10
BLE     no_discount
MOV     R4, #95
MUL     R3, R3, R4
MOV     R4, #100
UDIV    R3, R3, R4          ; cost = cost * 95 / 100

#### Module 7: Medicine Billing Module
File: module7.s
Function: medicine_billing_module

Purpose: Calculates total medicine cost across all medicines.

Formula:

Code
total_medicine_cost = 0
for each medicine:
    med_cost = unit_price * quantity * stay_days
    total_medicine_cost += med_cost
Example:

Code
Medicine 1: Rs. 50 * 10 units * 7 days = Rs. 3,500
Medicine 2: Rs. 120 * 5 units * 7 days = Rs. 4,200
Medicine 3: Rs. 200 * 3 units * 7 days = Rs. 4,200
Total: Rs. 11,900

#### Module 8: Patient Bill Aggregator
File: module8.s
Function: aggregate_total_bill

Purpose: Sums all billing components with overflow detection.

Formula:

Code
total_bill = treatment_cost + room_cost + medicine_cost + lab_test_cost
Overflow Detection:

Assembly
ADDS    R5, R1, R2          ; total = treatment + room
CMP     R5, R1              ; Check if result < operand
BCC     overflow_detected   ; Carry clear = overflow

ADDS    R5, R5, R3          ; total += medicine
CMP     R5, R3
BCC     overflow_detected

ADDS    R5, R5, R4          ; total += lab
CMP     R5, R4
BCC     overflow_detected
On Overflow:

total_bill = 0xFFFFFFFF
overflow_flag = 1

#### Module 9: Sorting Patients by Criticality
File: module9.s
Function: sort_patients_by_criticality

Purpose: Sorts patient array by alert_count in descending order (highest first).

Algorithm: Bubble Sort

Pseudocode:

Code
for i = 0 to n-1:
    swapped = false
    for j = 0 to n-i-2:
        if patient[j]. alert_count < patient[j+1].alert_count:
            swap(patient[j], patient[j+1])
            swapped = true
    if not swapped:
        break
Swap Implementation:

Exchanges entire 412-byte patient structures
Uses word-by-word copying (103 words)
Result: Most critical patients (highest alerts) move to front of array.

#### Module 10: UART Summary Report Generator
Files: module10.s, main.c
Functions: Generate_All_Patient_Reports, Generate_UART_Reports

Purpose: Generates formatted patient reports via UART/ITM output.

Output Includes:

Patient ID, Name, Age, Ward
Latest vital signs (HR, O2, BP)
Total alerts with severity classification
Complete billing breakdown
Error log (Module 11 integration)
Report Format:

```
==================================================
    PATIENT SUMMARY REPORT
    SmartCare-32: Healthcare Monitoring System
==================================================
PATIENT INFORMATION:
--------------------------------------------------
  Patient ID       : 1003
  Age              : 67 years
  Ward Number      : 201
--------------------------------------------------
LATEST VITAL SIGNS:
--------------------------------------------------
  Heart Rate       : 165 bpm
  Blood Pressure   : 170/95 mmHg
  SpO2 (Oxygen)    : 85 %
--------------------------------------------------
ALERT SUMMARY:
--------------------------------------------------
  Total Alerts     : 3 (Critical condition)
--------------------------------------------------
BILLING SUMMARY:
--------------------------------------------------
  Total Bill       : $50500 USD
==================================================
    End of Report
==================================================
```
Implementation:

module10.s: Bridge between assembly and C
main.c: ITM-based output for Keil simulator

#### Module 11: Error Detection & Logging
File: module11.s

Purpose
Module 11 provides comprehensive system health monitoring and fault detection. It acts as a safety layer that detects abnormal conditions or failures that could compromise patient care.

# Error Types Detected
1. Sensor Malfunction Detection
Detection Criteria: Same sensor value repeated more than 10 consecutive times

Implementation:

Assembly
check_sensor_malfunction:
    - Maintains rolling history buffer (10 entries) for each sensor
    - Compares all 10 values for each sensor (HR, O2, SBP, DBP)
    - If all 10 values identical → sensor stuck/failed
    - Logs error with sensor type and stuck value
Error Codes:

0x01: Heart Rate sensor malfunction
0x02: Oxygen sensor malfunction
0x03: Blood Pressure sensor malfunction
Example Detection:

Code
Reading 1-10: HR = 125, 125, 125, 125, 125, 125, 125, 125, 125, 125
Result: SENSOR MALFUNCTION detected (HR stuck at 125)
2. Invalid Dosage Detection
Detection Criteria: Medicine with zero unit_price OR zero quantity

Implementation:

Assembly
check_invalid_dosage:
    For each medicine in patient's medicine_list:
        if (unit_price == 0):
            Log error (code 0x01: zero price)
        if (quantity == 0):
            Log error (code 0x02: zero quantity)
Error Codes:

0x01: Zero unit price
0x02: Zero quantity
Rationale: Prevents billing errors and ensures proper medication tracking.

3. Memory Overflow Detection
Detection Criteria:

Patient pointer address > PATIENT_ARRAY_MAX (0x20004D00)
Total bill value > 0xF0000000 (4,026,531,840)
Implementation:

Assembly
check_memory_overflow:
    if (patient_pointer >= PATIENT_ARRAY_MAX):
        Log error (code 0x01: address boundary)
    if (total_bill >= 0xF0000000):
        Log error (code 0x02: billing overflow)
Error Codes:

0x01: Address boundary violation
0x02: Billing overflow
Purpose: Detects memory corruption, pointer errors, or arithmetic overflow.

Error Record Structure
Each error is logged as a 16-byte record:

C
typedef struct {
    uint8_t  error_type;        // +0x00: 0x01/0x02/0x03
    uint8_t  patient_index;     // +0x01: 0-2
    uint8_t  error_code;        // +0x02: Specific error subtype
    uint8_t  padding;           // +0x03: Alignment
    uint32_t timestamp;         // +0x04: system_clock value
    uint32_t error_value;       // +0x08: Context-specific data
    uint32_t reserved;          // +0x0C: Future use
} ErrorRecord;
Error Log Storage
Simulated Flash Memory:

Code
Address: 0x20000XXX (in RAM, simulates Flash)
Capacity: 50 error records (800 bytes)
Format: Circular buffer (oldest overwritten if full)
Global Error Tracking:

C
uint32_t error_flag;           // 0 = OK, 1 = ERROR DETECTED
uint32_t error_count;          // Number of logged errors (0-50)
uint8_t  error_log_buffer[800]; // 50 records * 16 bytes
Integration Points
Module 11 checks are strategically placed in the execution flow:

```
┌────────────────────────────────────────────────────────┐
│ Module 1: Initialize Patient                           │
│ Module 2: Acquire Vital Signs                          │
│   └─► MODULE 11a: check_sensor_malfunction()           │ ✓ After each reading
│ Module 3: Check Vital Thresholds                       │
│ Module 4: Medicine Administration Scheduler            │
│   └─► MODULE 11b: check_invalid_dosage()               │ ✓ After scheduling
│ Module 5-7: Billing Components                         │
│ Module 8: Aggregate Total Bill                         │
│   └─► MODULE 11c: check_memory_overflow()              │ ✓ After billing
│ Module 9: Sort by Criticality                          │
│ Module 10: UART Output (includes error log)            │ ✓ Display errors
└────────────────────────────────────────────────────────┘
```
Example: Detected Errors in Production
From actual system run:

```
========================================
     SYSTEM ERROR LOG (Module 11)      
========================================
Total Errors: 4

Error #1
  Type: SENSOR MALFUNCTION
  Sensor: Heart Rate
  Stuck Value: 125
  Patient: 0
  Timestamp: 2700 sec
----------------------------------------
Error #2
  Type: INVALID DOSAGE
  Issue: Zero Unit Price
  Medicine Index: 0
  Patient: 1
  Timestamp: 3000 sec
----------------------------------------
Error #3
  Type: MEMORY OVERFLOW
  Code: Address Boundary
  Value: 0x536871548
  Patient: 1
  Timestamp: 3000 sec
----------------------------------------
Error #4
  Type: MEMORY OVERFLOW
  Code: Address Boundary
  Value: 0x536871960
  Patient: 2
  Timestamp: 3000 sec
----------------------------------------
========================================
```
## Error Analysis & Diagnosis
Error #1: Sensor Malfunction
Detected: HR sensor stuck at 125 bpm
Root Cause: Hardware failure or sensor disconnection
Impact: Inaccurate vital monitoring for Patient 0
Action Required: Replace/calibrate HR sensor

Memory Dump:

Code
error_log_buffer[0]:
  01 00 01 00    # Type=0x01 (sensor), Patient=0, Code=0x01 (HR)
  8C 0A 00 00    # Timestamp=2700 (0x0A8C)
  7D 00 00 00    # Value=125 (0x7D)
  00 00 00 00    # Reserved
Error #2: Invalid Dosage
Detected: Medicine #0 for Patient 1 has zero unit_price
Root Cause: Corrupted medicine database or configuration error
Impact: Incorrect billing calculation
Action Required: Verify and reload medicine data

Memory Dump:

Code
error_log_buffer[16]:
  02 01 01 00    # Type=0x02 (dosage), Patient=1, Code=0x01 (zero price)
  B8 0B 00 00    # Timestamp=3000 (0x0BB8)
  00 00 00 00    # Medicine index=0
  00 00 00 00    # Reserved
Error #3 & #4: Memory Overflow
Detected: Invalid patient pointers (0x536871548, 0x536871960)
Root Cause: Memory corruption or pointer arithmetic error
Impact: System instability, potential data corruption
Action Required: System restart, memory diagnostics

Memory Dump (Error #3):

Code
error_log_buffer[32]:
  03 01 01 00    # Type=0x03 (memory), Patient=1, Code=0x01 (address)
  B8 0B 00 00    # Timestamp=3000
  0C 87 FE 1F    # Bad address=0x1FFE870C (536871548)
  00 00 00 00    # Reserved
Module 11 Functions Reference
check_sensor_malfunction
Assembly
Parameters:
  R0 = patient_index (0-2)
Returns:
  R0 = 1 if malfunction detected, 0 otherwise
Side Effects:
  - Updates sensor_history buffer
  - Calls log_error_to_flash if malfunction found
  - Sets global error_flag
check_invalid_dosage
Assembly
Parameters:
  R0 = patient pointer
  R1 = patient_index
Returns:
  R0 = 1 if invalid dosage found, 0 otherwise
Side Effects:
  - Validates all medicines for patient
  - Logs error if unit_price=0 or quantity=0
check_memory_overflow
Assembly
Parameters:
  R0 = patient pointer
  R1 = patient_index
Returns:
  R0 = 1 if overflow detected, 0 otherwise
Side Effects:
  - Checks address boundary
  - Checks billing overflow
  - Logs error if violation found
log_error_to_flash
Assembly
Parameters:
  R0 = error_type (0x01/0x02/0x03)
  R1 = patient_index
  R2 = error_code
  R3 = error_value
Returns:
  None
Side Effects:
  - Sets error_flag = 1
  - Increments error_count
  - Writes 16-byte error record to error_log_buffer
  - Includes system_clock timestamp
## Module 11 Memory Layout
```
┌─────────────────────────────────────────────────────────┐
│ Global Error Tracking (RAM)                             │
├─────────────────────────────────────────────────────────┤
│ 0x20000XXX: error_flag        (4 bytes)  [0 or 1]       │
│ 0x20000XXX: error_count       (4 bytes)  [0-50]         │
│ 0x20000XXX: error_log_buffer  (800 bytes)               │
│             ├─ ErrorRecord[0]  (16 bytes)               │
│             ├─ ErrorRecord[1]  (16 bytes)               │
│             ├─ ...                                      │
│             └─ ErrorRecord[49] (16 bytes)               │
├─────────────────────────────────────────────────────────┤
│ Sensor History Buffers (RAM)                            │
├─────────────────────────────────────────────────────────┤
│ 0x20000XXX: hr_history        (10 bytes)                │
│ 0x20000XXX: o2_history        (10 bytes)                │
│ 0x20000XXX: sbp_history       (10 bytes)                │
│ 0x20000XXX: dbp_history       (10 bytes)                │
│ 0x20000XXX: sensor_history_index (1 byte)               │
└─────────────────────────────────────────────────────────┘
```
Testing Module 11
Test 1: Force Sensor Malfunction
Modify sensor input in main.s:

Assembly
; Set same sensor value 10+ times
vitals_loop_p1
    LDR     R0, =SENSOR_HR
    MOV     R1, #125        ; Always 125 (stuck!)
    STRB    R1, [R0]
    ... 
Expected Result: Error logged with type=0x01, code=0x01, value=125

Test 2: Force Invalid Dosage
Modify data. s:

Assembly
medicine_list_p1
    DCB 1
    DCB 6
    DCB 0,0
    DCD 0
    DCD 0           ; ← Set unit_price to 0
    DCW 10
    DCB 0,0
Expected Result: Error logged with type=0x02, code=0x01, medicine_index=0

Test 3: Force Memory Overflow
Modify module11.s:

Assembly
PATIENT_ARRAY_MAX    EQU    0x20000100  ; Very low boundary
Expected Result: Error logged with type=0x03, code=0x01, bad_address

Module 11 Verification Checklist
Test Case	Status	Details
Sensor malfunction (HR stuck)	✅ PASS	Detected HR=125 repeated 10x
Sensor malfunction (O2 stuck)	✅ PASS	Works for all 4 sensors
Invalid dosage (zero price)	✅ PASS	Detected medicine with price=0
Invalid dosage (zero quantity)	✅ PASS	Detected medicine with qty=0
Memory overflow (address)	✅ PASS	Detected pointer > boundary
Memory overflow (billing)	✅ PASS	Detected total_bill overflow
Error flag setting	✅ PASS	error_flag=1 when error found
Error count increment	✅ PASS	error_count increments correctly
Timestamp recording	✅ PASS	All errors have system_clock timestamp
Flash logging	✅ PASS	16-byte records written correctly
UART error output	✅ PASS	Errors displayed before reports
Multiple errors handling	✅ PASS	All 4 errors logged independently

# 💾 Complete Memory Verification
Final Sorted Order (After Module 9)
Position	Patient ID	Name	alert_count	Total Bill
0	1003	Bob Wilson	3	$50,500
1	1001	John Doe	2	$53,900
2	1002	Jane Smith	0	$122,200
Base Addresses (After Sorting)
Patient	RAM Address
Position 0 — Bob Wilson	0x200000E0
Position 1 — John Doe	0x2000027C
Position 2 — Jane Smith	0x20000418
Patient 0 — Bob Wilson (CRITICAL)
Base Address: 0x200000E0

Basic Information
Offset	Field	Value (Decimal)	Value (Hex)
+0x00	patient_id	1003	0x03EB
+0x04	name_ptr	→ "Bob Wilson"	0x20000074
+0x08	age	67	0x43
+0x09	treatment_code	6	0x06
+0x0A	ward_number	201	0x00C9
+0x0C	room_daily_rate	3000	0x00000BB8
+0x10	medicine_list_ptr	→ medicine_p3	0x20000080
+0x14	medicine_count	1	0x01
+0x15	alert_count	3	0x03
+0x16	stay_days	5	0x0005
Vital Signs
Offset	Field	Value	Hex
+0x18	heart_rate	165 bpm	0xA5
+0x19	oxygen_level	85%	0x55
+0x1A	systolic_bp	170 mmHg	0xAA
+0x1B	diastolic_bp	95 mmHg	0x5F
Billing
Offset	Field	Value	Hex
+0x184	treatment_cost	30,000	0x00007530
+0x188	room_cost	15,000	0x00003A98
+0x18C	medicine_cost	3,000	0x00000BB8
+0x190	lab_test_cost	2,500	0x000009C4
+0x194	total_bill	50,500	0x0000C544
+0x198	overflow_flag	0	0x00
Associated Errors
Code
Error #1: SENSOR MALFUNCTION
  - Sensor: Heart Rate
  - Stuck Value: 125 bpm
  - Timestamp: 2700 sec
Patient 1 — John Doe (MODERATE)
Base Address: 0x2000027C

Basic Information
Offset	Field	Value (Decimal)	Value (Hex)
+0x00	patient_id	1001	0x03E9
+0x04	name_ptr	→ "John Doe"	0x2000005C
+0x08	age	45	0x2D
+0x09	treatment_code	5	0x05
+0x0A	ward_number	101	0x0065
+0x0C	room_daily_rate	2000	0x000007D0
+0x10	medicine_list_ptr	→ medicine_p1	0x200000B0
+0x14	medicine_count	3	0x03
+0x15	alert_count	2	0x02
+0x16	stay_days	7	0x0007
Vital Signs
Offset	Field	Value	Hex
+0x18	heart_rate	125 bpm	0x7D
+0x19	oxygen_level	88%	0x58
+0x1A	systolic_bp	135 mmHg	0x87
+0x1B	diastolic_bp	85 mmHg	0x55
Billing
Offset	Field	Value	Hex
+0x184	treatment_cost	25,000	0x000061A8
+0x188	room_cost	14,000	0x000036B0
+0x18C	medicine_cost	11,900	0x00002E7C
+0x190	lab_test_cost	3,000	0x00000BB8
+0x194	total_bill	53,900	0x0000D28C
+0x198	overflow_flag	0	0x00
Associated Errors
Code
Error #2: INVALID DOSAGE
  - Issue: Zero Unit Price
  - Medicine Index: 0
  - Timestamp: 3000 sec

Error #3: MEMORY OVERFLOW
  - Code: Address Boundary
  - Value: 0x536871548
  - Timestamp: 3000 sec
Patient 2 — Jane Smith (STABLE)
Base Address: 0x20000418

Basic Information
Offset	Field	Value (Decimal)	Value (Hex)
+0x00	patient_id	1002	0x03EA
+0x04	name_ptr	→ "Jane Smith"	0x20000068
+0x08	age	32	0x20
+0x09	treatment_code	2	0x02
+0x0A	ward_number	102	0x0066
+0x0C	room_daily_rate	5000	0x00001388
+0x10	medicine_list_ptr	→ medicine_p2	0x200000D0
+0x14	medicine_count	2	0x02
+0x15	alert_count	0	0x00
+0x16	stay_days	12	0x000C
Vital Signs
Offset	Field	Value	Hex
+0x18	heart_rate	78 bpm	0x4E
+0x19	oxygen_level	98%	0x62
+0x1A	systolic_bp	120 mmHg	0x78
+0x1B	diastolic_bp	80 mmHg	0x50
Billing
Offset	Field	Value	Hex
+0x184	treatment_cost	50,000	0x0000C350
+0x188	room_cost	57,000	0x0000DEA8
+0x18C	medicine_cost	14,880	0x00003A20
+0x190	lab_test_cost	8,000	0x00001F40
+0x194	total_bill	129,880	0x0001FB58
+0x198	overflow_flag	0	0x00
Associated Errors
Code
Error #4: MEMORY OVERFLOW
  - Code: Address Boundary
  - Value: 0x536871960
  - Timestamp: 3000 sec
Quick Memory Verification Commands
In Keil Memory Window:

Code
// Sorted Patient IDs
0x200000E0         → EB 03 00 00  (1003 - Bob Wilson)
0x2000027C         → E9 03 00 00  (1001 - John Doe)
0x20000418         → EA 03 00 00  (1002 - Jane Smith)

// Alert Counts (Descending)
0x200000E0 + 0x15  → 03  (Bob: 3 alerts - CRITICAL)
0x2000027C + 0x15  → 02  (John: 2 alerts - MODERATE)
0x20000418 + 0x15  → 00  (Jane: 0 alerts - STABLE)

// Total Bills
0x200000E0 + 0x194 → 44 C5 00 00  ($50,500)
0x2000027C + 0x194 → 8C D2 00 00  ($53,900)
0x20000418 + 0x194 → 58 FB 01 00  ($129,880)

// Error Flag
&error_flag        → 01 00 00 00  (ERRORS DETECTED)

// Error Count
&error_count       → 04 00 00 00  (4 errors logged)

# 🏗️ Build & Deployment
Project Structure
```
SmartCare-32/
├── Source/
│   ├── main.s              # Main integration (all modules)
│   ├── data.s              # Data structures & constants
│   ├── module1.s           # Patient initialization
│   ├── module2.s           # Vital sign acquisition
│   ├── module3.s           # Threshold checking
│   ├── module4.s           # Medicine scheduler
│   ├── module5.s           # Treatment cost
│   ├── module6. s           # Room cost
│   ├── module7.s           # Medicine cost
│   ├── module8.s           # Bill aggregation
│   ├── module9.s           # Sorting by criticality
│   ├── module10.s          # UART bridge (ASM)
│   ├── module11.s          # Error detection & logging ✨
│   ├── main.c              # UART output (C)
│   ├── startup_ARMCM4.c    # System startup
│   └── system_ARMCM4.c     # System initialization
├── Objects/                # Build output
└── README.md               # This file
```
- Build Instructions
Open Keil µVision 5
Project → Open Project
Select SmartCare-32.uvprojx
Project → Rebuild all target files (F7)
Verify: 0 Error(s), 0-1 Warning(s)
Debug Configuration
Target Options (Alt+F7):

Target: ARM Cortex-M4
Use Simulator: ✅ Enabled
Use MicroLIB: ✅ Enabled
- Debug Settings:

Trace → Core Clock: 25 MHz
Trace → Trace Enable: ✅
Trace → ITM Port 0: ✅
- Running the System
Debug → Start/Stop Debug Session (Ctrl+F5)
View → Serial Windows → Debug (printf) Viewer
Run (F5)
Observe UART output with error log
- 🧪 Testing & Verification
Functional Testing
Test ID	Description	Expected Result	Status
T01	Patient initialization	All fields populated	✅ PASS
T02	Vital sign acquisition	10 readings stored	✅ PASS
T03	Alert generation (HR > 120)	alert_count incremented	✅ PASS
T04	Alert generation (O2 < 92)	alert_flag set	✅ PASS
T05	Medicine scheduling	dosage_due_flag set	✅ PASS
T06	Treatment cost lookup	Correct value from table	✅ PASS
T07	Room cost with discount	5% discount > 10 days	✅ PASS
T08	Medicine cost calculation	Sum of all medicines	✅ PASS
T09	Billing overflow detection	overflow_flag set	✅ PASS
T10	Patient sorting	Descending by alert_count	✅ PASS
T11	UART report generation	Formatted output	✅ PASS
T12	Sensor malfunction detection	Error logged	✅ PASS
T13	Invalid dosage detection	Error logged	✅ PASS
T14	Memory overflow detection	Error logged	✅ PASS
T15	Error log output	All errors displayed	✅ PASS
Performance Metrics
- Metric	Value
Code Size	12,744 bytes
Read-Only Data	2,284 bytes
Read-Write Data	1,376 bytes
Zero-Init Data	3,932 bytes
Execution Time (3 patients)	~0.001 sec (simulated)
Error Detection Overhead	< 5%
# 📊 System Health Dashboard
```
╔═══════════════════════════════════════════════════════════╗
║            SMARTCARE-32 SYSTEM STATUS                     ║
╠═══════════════════════════════════════════════════════════╣
║  Modules Operational:     11/11                           ║
║  Patients Monitored:      3                               ║
║  Total Alerts Generated:  5                               ║
║  Error Flag:              ⚠  ACTIVE (4 errors detected)   ║
╠═══════════════════════════════════════════════════════════╣
║  CRITICAL ISSUES:                                         ║
║    • Sensor Malfunction:     1 (HR sensor)                ║
║    • Invalid Dosage:         1 (Patient 1)                ║
║    • Memory Corruption:      2 (Patients 1, 2)            ║
╠═══════════════════════════════════════════════════════════╣
║  PATIENT PRIORITY:                                        ║
║    1. Bob Wilson   (ID: 1003)  [3 alerts] 🔴              ║
║    2. John Doe     (ID: 1001)  [2 alerts] 🟡               ║
║    3. Jane Smith   (ID: 1002)  [0 alerts] 🟢               ║
╠═══════════════════════════════════════════════════════════╣
║  RECOMMENDED ACTIONS:                                     ║
║    ✓ Replace/calibrate HR sensor                          ║
║    ✓ Verify medicine database                             ║
║    ✓ Investigate memory corruption                        ║
║    ✓ Run full system diagnostics                          ║
╚═══════════════════════════════════════════════════════════╝
```
## 📚 Appendix
#### A. Register Usage Convention
Register	Purpose	Preserved?
R0-R3	Function arguments & return values	No (caller-saved)
R4-R11	Local variables	Yes (callee-saved)
R12 (IP)	Intra-procedure scratch	No
R13 (SP)	Stack pointer	Yes
R14 (LR)	Link register	Contextual
R15 (PC)	Program counter	N/A
#### B. Error Codes Reference
Module 11 Error Types
Error Type	Code	Name
0x01	Sensor Malfunction	ERROR_SENSOR_MALFUNCTION
0x02	Invalid Dosage	ERROR_INVALID_DOSAGE
0x03	Memory Overflow	ERROR_MEMORY_OVERFLOW
Sensor Malfunction Subcodes
Subcode	Sensor
0x01	Heart Rate (HR)
0x02	Oxygen Level (O2)
0x03	Blood Pressure (SBP)
Invalid Dosage Subcodes
Subcode	Issue
0x01	Zero unit_price
0x02	Zero quantity
Memory Overflow Subcodes
Subcode	Issue
0x01	Address boundary violation
0x02	Billing overflow
#### C. Checkpoint Markers (R11 Values)
R11 Value	Checkpoint	Module
0x0001	System start	Main
0x0002-0x0006	Patient 1 billing	1, 5-8
0x0007-0x000B	Patient 2 billing	1, 5-8
0x000C-0x0010	Patient 3 billing	1, 5-8
0x0011-0x0013	Patient 1 vitals	2-4
0x0014-0x0016	Patient 2 vitals	2-4
0x0017-0x0019	Patient 3 vitals	2-4
0x001A	Sorting complete	9
0x001B	UART start	10
0x001C	UART complete	10
0x0020	Error check P1	11
0x0021	Error check P2	11
0x0022	Error check P3	11
0x0023	All error checks done	11
0xBEEFDEAD (R0)	Success indicator	Main
#### D. Memory Map
```
┌───────────────────────────────────────────┐
│ 0x00000000 - 0x000FFFFF: Flash (1 MB)     │
│   ├─ 0x00000000: Vector Table             │
│   ├─ 0x00000100: Code (Modules 1-11)      │
│   └─ 0x00003000: Read-only data           │
├───────────────────────────────────────────┤
│ 0x20000000 - 0x2001FFFF: SRAM (128 KB)    │
│   ├─ 0x20000000: Data section             │
│   │   ├─ Patient array (1236 bytes)       │
│   │   ├─ Medicine lists                   │
│   │   ├─ Treatment cost table             │
│   │   ├─ Sensor registers                 │
│   │   ├─ Error tracking (Module 11)       │
│   │   │   ├─ error_flag (4 bytes)         │
│   │   │   ├─ error_count (4 bytes)        │
│   │   │   ├─ error_log_buffer (800 bytes) │
│   │   │   └─ sensor_history (40 bytes)    │
│   │   └─ system_clock                     │
│   └─ 0x20001000: Stack                    │
├───────────────────────────────────────────┤
│ 0xE0000000 - 0xE00FFFFF: ITM/Debug        │
│   └─ 0xE0000000: ITM Stimulus Port 0      │
└───────────────────────────────────────────┘
```
#### E. Known Limitations
Simulation Only:

No real UART hardware
Uses ITM for printf output
Flash writes simulated in RAM
Fixed Patient Count:

Maximum 3 patients (configurable)
Medicine list size fixed per patient
Error Log Capacity:

Maximum 50 error records
Oldest overwritten if full (circular buffer)
Sensor History:

Shared across all patients
May cause false negatives if mixed readings
#### F. Future Enhancements
 Real UART hardware support (USART1)
 True Flash memory writing (STM32 internal Flash)
 Expanded error types (communication, battery, etc.)
 Error severity levels (Warning, Critical, Fatal)
 Remote error notification (WiFi/BLE)
 Historical trend analysis
 Predictive analytics for patient deterioration
 Multi-threaded execution with RTOS

## 📄 License & Credits
Project: SmartCare-32 Healthcare Monitoring System
Platform: ARM Cortex-M4 (Keil µVision 5)
Author: SmartCare Development Team
Version: 2.0 (with Module 11 Error Detection)
Last Updated: 2025-11-29

Educational Use: This system is designed for embedded systems education and demonstration purposes.