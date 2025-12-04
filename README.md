# **SmartCare-32: Healthcare Monitoring & Billing System**

### **Complete Documentation for ARM Cortex-M4 Embedded System**

## 📋 **Table of Contents**

* [System Overview](#-system-overview)
* [Key Features](#key-features)
* [Technical Specifications](#technical-specifications)
* [Architecture](#-architecture)
* [Module Descriptions](#-module-descriptions)
* [Module 1–10 (summary)](#summary)
* [Module 11 — Error Detection & Logging](#module-11--error-detection--logging)
* [Memory Layout](#memory-layout)
* [Build & Deployment](#build--deployment)
* [Testing & Verification](#testing--verification)
* [System Health Dashboard](#system-health-dashboard)
* [Appendices](#appendices)
* [License & Credits](#license-&-credits)

## 🎯 **System Overview**

SmartCare-32 is a real-time patient monitoring and billing system designed for ARM Cortex-M4 microcontrollers.
The system manages multiple patients, monitors vital signs, schedules medicine administration, calculates billing, and provides comprehensive error detection.

## **Key Features**

* Real-time vital sign monitoring (HR, O₂, BP)
* Automated alert generation for abnormal vitals
* Medicine dosage scheduling with time tracking
* Multi-component billing system with overflow protection
* Patient criticality sorting
* UART/ITM report generation
* Advanced error detection & logging (Module 11)

    * Sensor malfunction detection
    * Invalid dosage validation
    * Memory overflow protection

## **Technical Specifications**

| Feature          | Specification                             |
| ---------------- | ----------------------------------------- |
| **Platform**     | ARM Cortex-M4 (ARMv7E-M)                  |
| **IDE**          | Keil µVision 5                            |
| **Language**     | ARM Assembly + C (hybrid)                 |
| **Memory**       | RAM-based (simulated Flash for error log) |
| **Max Patients** | 3 (expandable)                            |
| **Vital Buffer** | 10 entries per patient                    |
| **Alert Buffer** | 20 entries per patient                    |
| **Error Log**    | 50 error records (simulated Flash)        |

## 🏗️ **Architecture**

### **System Diagram**

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
            │  ┌────▼───────────────▼───────────────▼──────┐              │
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

### **Module Dependency Flow**

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

## 📦 **Module Descriptions**

### **Module 1: Patient Record Initialization**

**File:** `module1.s`
**Function:** `patient_record_initialization`

**Purpose:** Initializes patient data structure with personal info, treatment details, and medicine list.

**Parameters:**

```
R0: Patient pointer
R1: Patient ID (32-bit)
R2: Name pointer
R3: Age (8-bit)
```

**Key Operations**

* Stores patient fields
* Zeros vital buffer (40 bytes)
* Zeros alert buffer (320 bytes)
* Initializes billing structure
* **Memory Modified:** 412 bytes per patient

### **Module 2: Vital Sign Data Acquisition**

**File:** `module2.s`
**Function:** `acquire_vital_signs`

Reads sensor data and stores in the 10-entry rolling buffer.

**Algorithm**

```
1. Read sensors (HR, O2, SBP, DBP)
2. Get current buffer index
3. Store readings at vital_buffer[index]
4. Increment index (0–9)
```

### **Module 3: Vital Threshold Alert Module**

**File:** `module3.s`
**Function:** `check_vital_thresholds`

#### **Threshold Table**

| Vital       | Condition   | Trigger  |
| ----------- | ----------- | -------- |
| Heart Rate  | > 120 bpm   | HIGH     |
| Oxygen      | < 92%       | LOW      |
| Systolic BP | >160 or <90 | HIGH/LOW |

**Alert Record (16 bytes)**

```
+0x00: vital_type
+0x01: actual_reading
+0x04: timestamp
+0x08: reserved
```

### **Module 4: Medicine Administration Scheduler**

**File:** `module4.s`
**Function:** `medicine_administration_scheduler`

```
next_due_time = last_admin_time + interval_hours * 3600
if system_clock >= next_due_time:
    dosage_due_flag = 1
    last_admin_time = system_clock
```

### **Module 5: Treatment Cost Computation**

**File:** `module5.s`
**Function:** `compute_treatment_cost`

Example from table:

```
Code 0: 5,000
Code 1: 15,000
Code 2: 50,000
...
```

### **Module 6: Daily Room Rent Calculation**

**File:** `module6.s`
**Function:** `compute_room_cost`

**Assembly Implementation**

```asm
MUL     R3, R1, R2          ; cost = rate * days
CMP     R2, #10
BLE     no_discount
MOV     R4, #95
MUL     R3, R3, R4
MOV     R4, #100
UDIV    R3, R3, R4
```

### **Module 7: Medicine Billing Module**

```
total_cost = Σ(unit_price * quantity * stay_days)
```

### **Module 8: Patient Bill Aggregator**

With overflow detection:

```asm
ADDS R5, R1, R2
CMP  R5, R1
BCC  overflow_detected
```

### **Module 9: Sorting Patients by Criticality**

Bubble sort of 412-byte patient structures.

### **Module 10: UART Summary Report Generator**

Generates formatted UART/ITM reports.

**Sample Output**

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

## **Module 11: Error Detection & Logging**

**File:** `module11.s`

## **Purpose**

Module 11 provides comprehensive system health monitoring and fault detection.
It acts as a safety layer that detects abnormal conditions or failures that could compromise patient care.

## 🚨 **Error Types Detected**

### **1. Sensor Malfunction Detection**

**Detection Criteria:**
Sensor value is identical for **10 consecutive readings** (HR, O₂, SBP, DBP).

### **Implementation**

```asm
check_sensor_malfunction:
    ; Maintains rolling history buffer (10 entries)
    ; Compares all 10 sensor values
    ; If all identical → sensor stuck
    ; Logs error with sensor type + stuck value
```

### **Error Codes**

| Code     | Meaning                           |
| -------- | --------------------------------- |
| **0x01** | Heart Rate sensor malfunction     |
| **0x02** | Oxygen sensor malfunction         |
| **0x03** | Blood Pressure sensor malfunction |

### **Example Detection**

```
Reading 1–10:
HR = 125, 125, 125, 125, 125, 125, 125, 125, 125, 125

Result:
SENSOR MALFUNCTION detected (HR stuck at 125)
```

### **2. Invalid Dosage Detection**

**Detection Criteria:**

* `unit_price == 0`
* `quantity == 0`

### **Implementation**

```asm
check_invalid_dosage:
    For each medicine:
        if (unit_price == 0):
            Log error (0x01: zero price)
        if (quantity == 0):
            Log error (0x02: zero quantity)
```

### **Error Codes**

| Code     | Description     |
| -------- | --------------- |
| **0x01** | Zero unit price |
| **0x02** | Zero quantity   |

**Rationale:** Prevents billing errors & invalid medication records.

### **3. Memory Overflow Detection**

**Detection Criteria**

* `patient_pointer > PATIENT_ARRAY_MAX (0x20004D00)`
* `total_bill > 0xF0000000`

### **Implementation**

```asm
check_memory_overflow:
    if (patient_pointer >= PATIENT_ARRAY_MAX):
        Log error (0x01: address boundary)

    if (total_bill >= 0xF0000000):
        Log error (0x02: billing overflow)
```

### **Error Codes**

| Code     | Fault                      |
| -------- | -------------------------- |
| **0x01** | Address boundary violation |
| **0x02** | Billing overflow           |

## **🗃️ Error Record Structure**

Each error is a **16-byte record**:

```c
typedef struct {
    uint8_t  error_type;        // +0x00: 0x01/0x02/0x03
    uint8_t  patient_index;     // +0x01: 0-2
    uint8_t  error_code;        // +0x02
    uint8_t  padding;           // +0x03

    uint32_t timestamp;         // +0x04: system_clock
    uint32_t error_value;       // +0x08: context-specific
    uint32_t reserved;          // +0x0C
} ErrorRecord;
```

## **💾 Error Log Storage**

### **Simulated Flash (in RAM)**

```
Start Address: 0x20000XXX  
Capacity: 50 error records (800 bytes)  
Format: Circular buffer  
```

### **Global Tracking Variables**

```c
uint32_t error_flag;             // 0 = OK, 1 = error detected
uint32_t error_count;            // 0–50
uint8_t  error_log_buffer[800];  // 50 × 16 bytes
```

## 🔁 **Integration Points**

```
┌────────────────────────────────────────────────────────┐
│ Module 1: Initialize Patient                           │
│ Module 2: Acquire Vital Signs                          │
│   └─► MODULE 11a: check_sensor_malfunction()           │ ✓ After each reading
│ Module 3: Check Vital Thresholds                       │
│ Module 4: Medicine Scheduler                           │
│   └─► MODULE 11b: check_invalid_dosage()               │ ✓ After scheduling
│ Module 5–7: Billing Modules                            │
│ Module 8: Aggregate Billing                            │
│   └─► MODULE 11c: check_memory_overflow()              │ ✓ After billing
│ Module 9: Sorting                                      │
│ Module 10: UART Output (with error log)                │ ✓ Display errors
└────────────────────────────────────────────────────────┘
```

## 📝 **Example: Detected Errors in Production**

```
==================================================
           SYSTEM ERROR LOG                                               
==================================================
Total Errors: 4

--------------------------------------------------
Error #1
  Type: SENSOR MALFUNCTION
  Sensor: Heart Rate
  Stuck Value: 125
  Patient ID: 1001
  Timestamp: 2700 sec
--------------------------------------------------
--------------------------------------------------
Error #2
  Type: INVALID DOSAGE
  Issue: Zero Unit Price
  Medicine Index: 0
  Patient ID: 1002
  Timestamp: 3000 sec
--------------------------------------------------
--------------------------------------------------
Error #3
  Type: MEMORY OVERFLOW
  Code: Address Boundary
  Value: 0x536871548
  Patient ID: 1002
  Timestamp: 3000 sec
--------------------------------------------------
--------------------------------------------------
Error #4
  Type: MEMORY OVERFLOW
  Code: Address Boundary
  Value: 0x536871960
  Patient ID: 1003
  Timestamp: 3000 sec
--------------------------------------------------
==================================================
```

## 🔍 **Error Analysis & Diagnosis**

### **Error #1 — Sensor Malfunction**

* HR stuck at **125 bpm**
* Impact: Inaccurate vital monitoring
* Action: Replace/diagnose HR sensor

### Memory Dump

```
01 00 01 00    # Type=0x01, Patient=0, Code=0x01 (HR)
8C 0A 00 00    # Timestamp=2700
7D 00 00 00    # Value=125
00 00 00 00    # Reserved
```

### **Error #2 — Invalid Dosage**

* Medicine #0 for Patient 1 has **unit_price = 0**
* Impact: Incorrect billing
* Action: Fix medicine data table

### Memory Dump

```
02 01 01 00    # Type=0x02, Patient=1, Code=0x01
B8 0B 00 00    # Timestamp=3000
00 00 00 00    # Medicine index 0
00 00 00 00
```

### **Error #3 & #4 — Memory Overflow**

* Bad patient pointers written:

    * **0x536871548**
    * **0x536871960**

### Memory Dump

```
03 01 01 00    # Type=0x03, Patient=1, Code=0x01
B8 0B 00 00
0C 87 FE 1F    # Bad address
00 00 00 00
```

## 🔧 **Module 11 Function Reference**

### **check_sensor_malfunction**

```asm
; R0 = patient_index
; Returns R0 = 1 if malfunction
; Updates history, sets error_flag, logs error
```

### **check_invalid_dosage**

```asm
; R0 = patient pointer
; R1 = patient_index
; Returns R0 = 1 if invalid
; Logs zero price / zero quantity errors
```

### **check_memory_overflow**

```asm
; R0 = patient pointer
; R1 = patient_index
; Returns 1 if overflow detected
; Checks both address + billing overflow
```

### **log_error_to_flash**

```asm
; R0 = error_type
; R1 = patient_index
; R2 = error_code
; R3 = error_value
; Writes 16-byte record into error_log_buffer
; Adds timestamp, increments error_count
```

## 🧩 **Module 11 Memory Layout**

```
┌─────────────────────────────────────────────────────────┐
│ Global Error Tracking (RAM)                             │
├─────────────────────────────────────────────────────────┤
│ error_flag              (4 bytes)                       │
│ error_count             (4 bytes)                       │
│ error_log_buffer        (800 bytes)                     │
│   ├─ ErrorRecord[0]                                     │
│   ├─ ...                                                │
│   └─ ErrorRecord[49]                                    │
├─────────────────────────────────────────────────────────┤
│ Sensor History Buffers                                  │
│   hr_history (10 bytes)                                 │
│   o2_history (10 bytes)                                 │
│   sbp_history (10 bytes)                                │
│   dbp_history (10 bytes)                                │
│   sensor_history_index (1 byte)                         │
└─────────────────────────────────────────────────────────┘
```

## 🧪 **Testing Module 11**

---

### **Test 1 — Force Sensor Malfunction**

```asm
vitals_loop_p1
    LDR R0, =SENSOR_HR
    MOV R1, #125   ; repeated value
    STRB R1, [R0]
```

**Expected:** Error logged (type 0x01, value=125)

### **Test 2 — Force Invalid Dosage**

```asm
medicine_list_p1
    DCB 1
    DCB 6
    DCB 0,0
    DCD 0
    DCD 0      ; unit_price = 0
    DCW 10
```

**Expected:** error type 0x02, code 0x01

### **Test 3 — Force Memory Overflow**

```asm
PATIENT_ARRAY_MAX EQU 0x20000100
```

**Expected:** error type 0x03, code 0x01

## ✅ **Module 11 Verification Checklist**

| Test Case              | Status | Description                |
| ---------------------- | ------ | -------------------------- |
| HR sensor malfunction  | ✅ PASS | Detects repeated HR values |
| O₂ sensor malfunction  | ✅ PASS | Detects O₂ stuck values    |
| Zero price medicine    | ✅ PASS | Detected                   |
| Zero quantity medicine | ✅ PASS | Detected                   |
| Pointer overflow       | ✅ PASS | Detected                   |
| Billing overflow       | ✅ PASS | Detected                   |
| Error flag update      | ✅ PASS | Works                      |
| Error count update     | ✅ PASS | Increments                 |
| Timestamp record       | ✅ PASS | Included                   |
| Flash logging          | ✅ PASS | 16-byte record             |
| UART output            | ✅ PASS | Printed in report          |
| Multiple errors        | ✅ PASS | All logged independently   |


# 💾 **Complete Memory Verification**

## **Final Sorted Order (After Module 9)**

| Position | Patient ID | Name       | alert_count | Total Bill |
| -------- | ---------- | ---------- | ----------- | ---------- |
| 0        | 1003       | Bob Wilson | 3           | $50,500    |
| 1        | 1001       | John Doe   | 2           | $53,900    |
| 2        | 1002       | Jane Smith | 0           | $122,200   |

## **Base Addresses (After Sorting)**

| Patient Position | Patient Name | RAM Address |
|------------------| ------------ | ----------- |
| 1                | Bob Wilson   | 0x200000E0  |
| 2                | John Doe     | 0x2000027C  |
| 3                | Jane Smith   | 0x20000418  |

# 🧍‍♂️ **Patient 1 — Bob Wilson (CRITICAL)**

**Base Address: 0x200000E0**

## **Basic Information**

| Offset | Field             | Value (Dec)    | Value (Hex) |
| ------ | ----------------- | -------------- | ----------- |
| +0x00  | patient_id        | 1003           | 0x03EB      |
| +0x04  | name_ptr          | → "Bob Wilson" | 0x20000074  |
| +0x08  | age               | 67             | 0x43        |
| +0x09  | treatment_code    | 6              | 0x06        |
| +0x0A  | ward_number       | 201            | 0x00C9      |
| +0x0C  | room_daily_rate   | 3000           | 0x00000BB8  |
| +0x10  | medicine_list_ptr | → medicine_p3  | 0x20000080  |
| +0x14  | medicine_count    | 1              | 0x01        |
| +0x15  | alert_count       | 3              | 0x03        |
| +0x16  | stay_days         | 5              | 0x0005      |

## **Vital Signs**

| Offset | Field        | Value   | Hex  |
| ------ | ------------ | ------- | ---- |
| +0x18  | heart_rate   | 165 bpm | 0xA5 |
| +0x19  | oxygen_level | 85%     | 0x55 |
| +0x1A  | systolic_bp  | 170     | 0xAA |
| +0x1B  | diastolic_bp | 95      | 0x5F |

## **Billing**

| Offset | Field          | Value (Dec) | Hex        |
| ------ | -------------- | ----------- | ---------- |
| +0x184 | treatment_cost | 30,000      | 0x00007530 |
| +0x188 | room_cost      | 15,000      | 0x00003A98 |
| +0x18C | medicine_cost  | 3,000       | 0x00000BB8 |
| +0x190 | lab_test_cost  | 2,500       | 0x000009C4 |
| +0x194 | total_bill     | 50,500      | 0x0000C544 |
| +0x198 | overflow_flag  | 0           | 0x00       |

## **Associated Errors**

```
Error #1: SENSOR MALFUNCTION
  - Sensor: Heart Rate
  - Stuck Value: 125 bpm
  - Timestamp: 2700 sec
```

# 🧍‍♂️ **Patient 2 — John Doe (MODERATE)**

**Base Address: 0x2000027C**

## **Basic Information**

| Offset | Field             | Value (Dec)   | Value (Hex) |
| ------ | ----------------- | ------------- | ----------- |
| +0x00  | patient_id        | 1001          | 0x03E9      |
| +0x04  | name_ptr          | → "John Doe"  | 0x2000005C  |
| +0x08  | age               | 45            | 0x2D        |
| +0x09  | treatment_code    | 5             | 0x05        |
| +0x0A  | ward_number       | 101           | 0x0065      |
| +0x0C  | room_daily_rate   | 2000          | 0x000007D0  |
| +0x10  | medicine_list_ptr | → medicine_p1 | 0x200000B0  |
| +0x14  | medicine_count    | 3             | 0x03        |
| +0x15  | alert_count       | 2             | 0x02        |
| +0x16  | stay_days         | 7             | 0x0007      |

## **Vital Signs**

| Offset | Field        | Value   | Hex  |
| ------ | ------------ | ------- | ---- |
| +0x18  | heart_rate   | 125 bpm | 0x7D |
| +0x19  | oxygen_level | 88%     | 0x58 |
| +0x1A  | systolic_bp  | 135     | 0x87 |
| +0x1B  | diastolic_bp | 85      | 0x55 |

## **Billing**

| Offset | Field          | Value (Dec) | Hex        |
| ------ | -------------- | ----------- | ---------- |
| +0x184 | treatment_cost | 25,000      | 0x000061A8 |
| +0x188 | room_cost      | 14,000      | 0x000036B0 |
| +0x18C | medicine_cost  | 11,900      | 0x00002E7C |
| +0x190 | lab_test_cost  | 3,000       | 0x00000BB8 |
| +0x194 | total_bill     | 53,900      | 0x0000D28C |
| +0x198 | overflow_flag  | 0           | 0x00       |

## **Associated Errors**

```
Error #2: INVALID DOSAGE
  - Issue: Zero Unit Price
  - Medicine Index: 0
  - Timestamp: 3000 sec

Error #3: MEMORY OVERFLOW
  - Code: Address Boundary
  - Value: 0x536871548
  - Timestamp: 3000 sec
```

# 🧍‍♀️ **Patient 3 — Jane Smith (STABLE)**

**Base Address: 0x20000418**

## **Basic Information**

| Offset | Field             | Value (Dec)    | Value (Hex) |
| ------ | ----------------- | -------------- | ----------- |
| +0x00  | patient_id        | 1002           | 0x03EA      |
| +0x04  | name_ptr          | → "Jane Smith" | 0x20000068  |
| +0x08  | age               | 32             | 0x20        |
| +0x09  | treatment_code    | 2              | 0x02        |
| +0x0A  | ward_number       | 102            | 0x0066      |
| +0x0C  | room_daily_rate   | 5000           | 0x00001388  |
| +0x10  | medicine_list_ptr | → medicine_p2  | 0x200000D0  |
| +0x14  | medicine_count    | 2              | 0x02        |
| +0x15  | alert_count       | 0              | 0x00        |
| +0x16  | stay_days         | 12             | 0x000C      |

## **Vital Signs**

| Offset | Field        | Value  | Hex  |
| ------ | ------------ | ------ | ---- |
| +0x18  | heart_rate   | 78 bpm | 0x4E |
| +0x19  | oxygen_level | 98%    | 0x62 |
| +0x1A  | systolic_bp  | 120    | 0x78 |
| +0x1B  | diastolic_bp | 80     | 0x50 |

## **Billing**

| Offset | Field          | Value (Dec) | Hex        |
| ------ | -------------- | ----------- | ---------- |
| +0x184 | treatment_cost | 50,000      | 0x0000C350 |
| +0x188 | room_cost      | 57,000      | 0x0000DEA8 |
| +0x18C | medicine_cost  | 14,880      | 0x00003A20 |
| +0x190 | lab_test_cost  | 8,000       | 0x00001F40 |
| +0x194 | total_bill     | 129,880     | 0x0001FB58 |
| +0x198 | overflow_flag  | 0           | 0x00       |

## **Associated Errors**

```
Error #4: MEMORY OVERFLOW
  - Code: Address Boundary
  - Value: 0x536871960
  - Timestamp: 3000 sec
```

## 🔍 **Quick Memory Verification Commands**

#### **In Keil Memory Window**

#### **📌 Sorted Patient IDs**

```
// Sorted Patient IDs
0x200000E0         → EB 03 00 00   (1003 - Bob Wilson)
0x2000027C         → E9 03 00 00   (1001 - John Doe)
0x20000418         → EA 03 00 00   (1002 - Jane Smith)
```

#### **📌 Alert Counts (Descending)**

```
// Alert Counts
0x200000E0 + 0x15  → 03   (Bob: 3 alerts - CRITICAL)
0x2000027C + 0x15  → 02   (John: 2 alerts - MODERATE)
0x20000418 + 0x15  → 00   (Jane: 0 alerts - STABLE)
```

### **📌 Total Bills**

```
// Total Bills
0x200000E0 + 0x194 → 44 C5 00 00   ($50,500)
0x2000027C + 0x194 → 8C D2 00 00   ($53,900)
0x20000418 + 0x194 → 58 FB 01 00   ($129,880)
```

### **📌 Error Flag**

```
// Error Flag
&error_flag        → 01 00 00 00   (ERRORS DETECTED)
```

### **📌 Error Count**

```
// Error Count
&error_count       → 04 00 00 00   (4 errors logged)
```

# 🏗️ **Build & Deployment**

## **Project Structure**

```
SmartCare-32/
├── Source/
│   ├── main.s               # Main integration (all modules)
│   ├── data.s               # Data structures & constants
│   ├── module1.s            # Patient initialization
│   ├── module2.s            # Vital sign acquisition
│   ├── module3.s            # Threshold checking
│   ├── module4.s            # Medicine scheduler
│   ├── module5.s            # Treatment cost
│   ├── module6.s            # Room cost
│   ├── module7.s            # Medicine cost
│   ├── module8.s            # Bill aggregation
│   ├── module9.s            # Sorting by criticality
│   ├── module10.s           # UART bridge (Assembly)
│   ├── module11.s           # Error detection & logging
│   ├── main.c               # UART output (C)
│   ├── startup_ARMCM4.c     # System startup
│   └── system_ARMCM4.c      # System initialization
├── Objects/                 # Build output
└── README.md                # Documentation
```

## **Build Instructions**

### **1. Open project**

* Open **Keil µVision 5**
* `Project → Open Project`
* Select **SmartCare-32.uvprojx**

### **2. Build**

* `Project → Rebuild all target files (F7)`
* Expected:
  **0 Errors**, **0–1 Warnings**

## **Debug Configuration**

### **Target Options (Alt+F7)**

* **Target →** ARM Cortex-M4
* **Use Simulator:** ✔ Enabled
* **Use MicroLIB:** ✔ Enabled

### **Debug Settings**

* **Trace → Core Clock:** 25 MHz
* **Trace → ITM Port 0:** ✔
* **Trace Enable:** ✔

## **Running the System**

1. `Debug → Start/Stop Debug Session (Ctrl+F5)`
2. `View → Serial Windows → Debug (printf) Viewer`
3. `Run (F5)`
4. Observe UART output (Module 10 → main.c)

## 🧪 **Testing & Verification**

## **Functional Testing Table**

| Test ID | Description                  | Expected Result         | Status |
|---------|------------------------------|-------------------------|--------|
| T01     | Patient initialization       | All fields populated    | ✅ PASS |
| T02     | Vital sign acquisition       | 10 readings stored      | ✅ PASS |
| T03     | Alert (HR > 120)             | alert_count incremented | ✅ PASS |
| T04     | Alert (O2 < 92)              | alert_flag set          | ✅ PASS |
| T05     | Medicine scheduling          | dosage_due_flag set     | ✅ PASS |
| T06     | Treatment cost lookup        | Correct table value     | ✅ PASS |
| T07     | Room cost (discount)         | 5% discount > 10 days   | ✅ PASS |
| T08     | Medicine cost calculation    | Sum of medicines        | ✅ PASS |
| T09     | Billing overflow detection   | overflow_flag set       | ✅ PASS |
| T10     | Patient sorting              | Descending alert_count  | ✅ PASS |
| T11     | UART report generation       | Formatted output        | ✅ PASS |
| T12     | Sensor malfunction detection | Error logged            | ✅ PASS |
| T13     | Invalid dosage detection     | Error logged            | ✅ PASS |
| T14     | Memory overflow detection    | Error logged            | ✅ PASS |
| T15     | Error log output             | All errors displayed    | ✅ PASS |

## **Performance Metrics**

| Metric                      | Value        |
| --------------------------- | ------------ |
| Code Size                   | 12,744 bytes |
| Read-Only Data              | 2,284 bytes  |
| Read-Write Data             | 1,376 bytes  |
| Zero-Init Data              | 3,932 bytes  |
| Execution Time (3 patients) | ~0.001 sec   |
| Error Detection Overhead    | < 5%         |

## 📊 **System Health Dashboard**

```
╔═══════════════════════════════════════════════════════════╗
║                 SMARTCARE-32 SYSTEM STATUS                ║
╠═══════════════════════════════════════════════════════════╣
║  Modules Operational:       11/11                         ║
║  Patients Monitored:        3                             ║
║  Total Alerts Generated:    5                             ║
║  Error Flag:                ⚠ ACTIVE (4 errors detected)  ║
╠═══════════════════════════════════════════════════════════╣
║  CRITICAL ISSUES:                                         ║
║    • Sensor Malfunction:     1 (HR sensor)                ║
║    • Invalid Dosage:         1 (Patient 1)                ║
║    • Memory Corruption:      2 (Patients 1, 2)            ║
╠═══════════════════════════════════════════════════════════╣
║  PATIENT PRIORITY:                                        ║
║    1. Bob Wilson   (ID: 1003)  [3 alerts]                 ║
║    2. John Doe     (ID: 1001)  [2 alerts]                 ║
║    3. Jane Smith   (ID: 1002)  [0 alerts]                 ║
╠═══════════════════════════════════════════════════════════╣
║  RECOMMENDED ACTIONS:                                     ║
║    ✓ Replace/calibrate HR sensor                          ║
║    ✓ Verify medicine database                             ║
║    ✓ Investigate memory corruption                        ║
║    ✓ Run full system diagnostics                          ║
╚═══════════════════════════════════════════════════════════╝
```

## 📚 **Appendix**

## **A. Register Usage Convention**

| Register | Purpose              | Preserved? |
| -------- | -------------------- | ---------- |
| R0–R3    | Args & return values | No         |
| R4–R11   | Local variables      | Yes        |
| R12      | Scratch (IP)         | No         |
| R13      | Stack pointer (SP)   | Yes        |
| R14      | Link register (LR)   | —          |
| R15      | Program counter (PC) | —          |

## **B. Error Codes Reference**

### **Module 11 Error Types**

| Error Type         | Code | Name                     |
| ------------------ | ---- | ------------------------ |
| Sensor Malfunction | 0x01 | ERROR_SENSOR_MALFUNCTION |
| Invalid Dosage     | 0x02 | ERROR_INVALID_DOSAGE     |
| Memory Overflow    | 0x03 | ERROR_MEMORY_OVERFLOW    |

### **Sensor Malfunction Subcodes**

| Subcode | Sensor               |
| ------- | -------------------- |
| 0x01    | Heart Rate (HR)      |
| 0x02    | Oxygen Level (O2)    |
| 0x03    | Blood Pressure (SBP) |

### **Invalid Dosage Subcodes**

| Subcode | Issue           |
| ------- | --------------- |
| 0x01    | Zero unit_price |
| 0x02    | Zero quantity   |

### **Memory Overflow Subcodes**

| Subcode | Issue                      |
| ------- | -------------------------- |
| 0x01    | Address boundary violation |
| 0x02    | Billing overflow           |

## **C. Checkpoint Markers (R11 values)**

| R11 Value           | Checkpoint            | Module |
| ------------------- | --------------------- | ------ |
| 0x0001              | System start          | Main   |
| 0x0002–0x0006       | Patient 1 billing     | 1, 5–8 |
| 0x0007–0x000B       | Patient 2 billing     | 1, 5–8 |
| 0x000C–0x0010       | Patient 3 billing     | 1, 5–8 |
| 0x0011–0x0013       | Patient 1 vitals      | 2–4    |
| 0x0014–0x0016       | Patient 2 vitals      | 2–4    |
| 0x0017–0x0019       | Patient 3 vitals      | 2–4    |
| 0x001A              | Sorting complete      | 9      |
| 0x001B              | UART start            | 10     |
| 0x001C              | UART complete         | 10     |
| 0x0020              | Error check P1        | 11     |
| 0x0021              | Error check P2        | 11     |
| 0x0022              | Error check P3        | 11     |
| 0x0023              | All error checks done | 11     |
| **0xBEEFDEAD (R0)** | Success indicator     | Main   |

## **D. Memory Map**

```
┌───────────────────────────────────────────┐
│ 0x00000000 - 0x000FFFFF : Flash (1 MB)    │
│   ├─ 0x00000000 : Vector Table            │
│   ├─ 0x00000100 : Code (Modules 1–11)     │
│   └─ 0x00003000 : Read-only data          │
├───────────────────────────────────────────┤
│ 0x20000000 - 0x2001FFFF : SRAM (128 KB)   │
│   ├─ 0x20000000 : Data Section            │
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
│   └─ 0x20001000 : Stack                   │
├───────────────────────────────────────────┤
│ 0xE0000000 - 0xE00FFFFF : ITM/Debug       │
│   └─ 0xE0000000 : ITM Stimulus Port 0     │
└───────────────────────────────────────────┘
```

## **E. Known Limitations**

### **Simulation Only**

* UART via ITM (not real UART)
* Flash writes simulated in RAM

### **Fixed Patient Count**

* Maximum 3 patients
* Fixed medicine list size

### **Error Log Capacity**

* 50 records
* Circular overwrite

### **Sensor History**

* Shared history buffers → may mix readings

## **F. Future Enhancements**

* Real USART1 UART hardware
* True Flash writing
* More error types
* Error severity levels
* Wireless remote alerts
* Trend analysis
* Predictive analytics
* RTOS multithreading

# 📄 **License & Credits**

**Project:** SmartCare-32 Healthcare Monitoring System <br>
**Platform:** ARM Cortex-M4 (Keil µVision 5) <br>
**Version:** 2.0 (with Module 11) <br>
**Author:** SmartCare Development Team <br>
**Updated:** 2025-12-04 <br>

Educational use only.