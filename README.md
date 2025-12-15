# SmartCare-32  
## ARM-Based Healthcare Monitoring & Billing System

## Introduction
**SmartCare-32** is an ARM Cortex‑M based embedded firmware prototype for **DU Medical Center (2025)**. The system stores patient records in RAM, continuously reads simulated vital sensors (HR, SpO₂, blood pressure) into rolling buffers, detects dangerous threshold conditions and logs **16‑byte alert records** with timestamps, and manages medication schedules using an internal clock.

It also computes treatment, room, medicine, and lab costs, aggregates the final bill with **overflow checking**, sorts patients by **criticality (alert count)** for triage, securely logs anomalies (sensor malfunction, invalid dosage, memory boundary issues), and outputs a formatted patient summary report through serial/UART-style output (ITM simulation).

---

## System Overview

### Goal
SmartCare‑32 modernizes DU Medical Center’s embedded monitoring & billing by:
- Acquiring vitals continuously (simulated sensors)
- Generating alerts from out‑of‑range vitals
- Scheduling medicine administration
- Computing billing (treatment + room + medicine + lab tests)
- Performing error detection and logging
- Printing a complete summary via serial/ITM output

### Execution flow (from `main.s`)
1. Reset `system_clock = 0`
2. Initialize Patient 1 → compute bills (treatment/room/medicine/total)
3. Initialize Patient 2 → compute bills
4. Initialize Patient 3 → compute bills
5. Acquire vitals:
   - Patient 1: loop 10 readings (also fills `sensor_history` for malfunction checking)
   - Patient 2: 1 reading
   - Patient 3: 1 reading
6. After each acquisition: **Module 11a (sensor malfunction check)** runs.
7. For each patient:
   - **Module 3** checks thresholds and inserts alert records if violated
   - **Module 4** checks dosage schedule
   - **Module 11b** checks invalid dosage
   - **Module 11c** checks memory overflow for each patient
8. **Module 9** sorts patients by criticality (alert_count descending)
9. **Module 10** prints:
   - Error log first (Module 11 print routine)
   - Then patient summary reports over ITM/UART

---

## File Inventory

| File | Role |
|------|------|
| `data.s` | Global data: patient structures, tables, sensor registers, medicine lists, system clock, error log buffers/constants |
| `main.s` | Full integration of Modules 1–11; simulates sensor inputs and runs the workflow |
| `module1.s` | Patient record initialization (writes header fields, clears buffers, resets billing sub-structure) |
| `module2.s` | Vital acquisition: reads sensor registers, pushes into a 10-entry rolling buffer |
| `module3.s` | Vital threshold checks; generates alert records and increments `alert_count` |
| `module4.s` | Medicine administration scheduler based on `system_clock` and dosage intervals |
| `module5.s` | Treatment cost lookup using `treatment_cost_table` |
| `module6.s` | Room cost computation with discount after a threshold stay length |
| `module7.s` | Medicine billing module using `unit_price * quantity * stay_days` |
| `module8.s` | Bill aggregation with unsigned overflow detection and overflow flagging |
| `module9.s` | Sorts patients by “criticality” (descending `alert_count`) via bubble sort (swapping entire patient structs) |
| `module10.s` | Human-readable report generator outputting via ITM UART simulation |
| `module11.s` | Error detection + secure log buffer (“flash simulation”) + printing error log report |
| `uart.s` | ITM/serial helpers: `ITM_Init`, `ITM_SendChar` |

---

## Module Descriptions

## 1) Data & Memory Layout (`data.s`)
### Solution technique
Defines:
- Fixed offsets for `Patient`, `Medicine`, `Billing`, `VitalSign`, `AlertRecord`
- Simulated sensor registers (1 byte each): `SENSOR_HR`, `SENSOR_O2`, `SENSOR_SBP`, `SENSOR_DBP`
- Global `system_clock` (seconds counter)
- `treatment_cost_table[0..15]`
- 3 patient names + 3 medicine lists + `patient_array`
- Module 11 error logging buffers & sensor history ring buffers

### Key structure sizes
- `Medicine` = 16 bytes  
- `VitalSign` = 4 bytes  
- `AlertRecord` = 16 bytes  
- `Billing` = 24 bytes  
- `Patient` = 252 bytes (`PATIENT_SIZE`)

### Initial dataset (important for outputs)
Patients pre-populated in `patient_array` with:
- Patient1: `alert_count = 2`, `lab_test_cost = 3000`
- Patient2: `alert_count = 0`, `lab_test_cost = 8000`
- Patient3: `alert_count = 5`, `lab_test_cost = 2500`

Medicines:
- P1: `(id1 price50 qty10)`, `(id2 price120 qty5)`, `(id3 price200 qty3)`
- P2: `(id4 price0 qty0)` ← intentionally invalid, triggers error; plus `(id5 price150 qty4)`
- P3: `(id6 price300 qty2)`

---

## 2) Module 1 — Patient Record Initialization
### What it does
Creates/updates one Patient record fields and clears runtime buffers.

### Inputs
- `R0` = patient struct pointer  
- `R1` = patient_id  
- `R2` = name_ptr  
- `R3` = age  
- stack params: ward, treatment_code, room_rate, medicine_list_ptr, medicine_count, stay_days

### Solution technique
Uses fixed offsets and store instructions (`STR`, `STRB`, `STRH`) to write each field.

Initializes counters/flags:
- `vital_buffer_index = 0`
- `alert_flag = 0`
- `dosage_due_flag = 0`
- does **not** overwrite `alert_count` (preset in `data.s`)

Clears:
- `vital_buffer[10]` (10 words)
- `alert_buffer[10]` (40 words = 160 bytes)
- billing fields mostly

### Output notes
- Identity fields are correct.
- Buffers cleared.
- Preset `alert_count` preserved.
- **`billing.lab_test_cost` is not cleared**, preserving dataset values (3000/8000/2500), affecting totals (intended).

---

## 3) Module 2 — Vital Sign Data Acquisition
### What it does
Reads 4 simulated sensor bytes and writes a rolling buffer of 10 entries.

### Inputs
- `R0` = Patient pointer
- Sensor memory: `SENSOR_HR`, `SENSOR_O2`, `SENSOR_SBP`, `SENSOR_DBP`

### Solution technique
- Reads each sensor with `LDRB`
- Computes slot = `vital_buffer_index`
- Stores packed 4 bytes: `[0]=HR, [1]=O2, [2]=SBP, [3]=DBP`
- Updates `vital_buffer_index = (index + 1) % 10`

### Output (values written by `main`)
- **Patient 1** (10 times): HR=125, O2=88, SBP=135, DBP=85  
  - After 10: index wraps to 0; buffer contains 10 identical entries
- **Patient 2** (1 time): HR=78, O2=98, SBP=120, DBP=80 → index=1
- **Patient 3** (1 time): HR=165, O2=85, SBP=170, DBP=95 → index=1

---

## 4) Module 3 — Vital Threshold Alert Module
### What it does
Checks latest vital entry and generates AlertRecords if thresholds are violated.

### Threshold rules implemented
- HR > 120 ⇒ alert (type 0)
- O2 < 92 ⇒ alert (type 1)
- SBP > 160 or SBP < 90 ⇒ alert (type 2)
- DBP not used for thresholding

### Solution technique
- Determine latest slot:
  - `latest = (vital_buffer_index == 0) ? 9 : (index - 1)`
- Load bytes from that slot
- For each violated condition:
  - set `patient.alert_flag = 1`
  - append AlertRecord at `alert_buffer[alert_count]` (max 10)
  - increment `alert_count`
  - record timestamp from `system_clock`

AlertRecord layout:
- byte0: vital_type
- byte1: actual_reading
- word at +4: timestamp
- rest zero

### Output (expected from main’s vitals)
- Patient 1: preset 2 → +2 (HR + O2) → **4**
- Patient 2: preset 0 → +0 → **0**
- Patient 3: preset 5 → +3 (HR + O2 + SBP) → **8**

**Timestamp note**
- Patient 1 loop increments clock by +300 seconds * 10 → `system_clock = 3000`
- Threshold checks happen after loop; timestamps around ~3000

---

## 5) Module 4 — Medicine Administration Scheduler
### What it does
For each medicine:
- `next_due_time = last_admin_time + (interval_hours * 3600)`
- if `system_clock >= next_due_time`:
  - set `patient.dosage_due_flag = 1`
  - update `medicine.last_administered_time = system_clock`

### Output in this run
All medicines start with `last_administered_time = 0`; `system_clock ≈ 3000` which is below all due times.
- No medicine due → `dosage_due_flag = 0` for all patients.

---

## 6) Module 5 — Treatment Cost Computation
### What it does
Looks up cost using `treatment_code` in `treatment_cost_table` and stores to billing.

### `treatment_cost_table`
- Code 0: 5000 (Basic checkup)
- Code 1: 15000 (Minor surgery)
- Code 2: 50000 (Major surgery)
- Code 3: 8000 (Diagnostic tests)
- Code 4: 12000 (Physical therapy)
- Code 5: 25000 (ICU admission)
- Code 6: 30000 (Emergency care)
- Code 7: 10000 (Consultation)
- Code 8: 20000 (Imaging)
- Code 9: 18000 (Laboratory)
- Code 10: 22000 (Cardiology)
- Code 11: 27000 (Neurology)
- Code 12: 16000 (Orthopedics)
- Code 13: 14000 (Pediatrics)
- Code 14: 19000 (Oncology)
- Code 15: 21000 (Radiology)

### Output
- P1 code 5 ⇒ 25000
- P2 code 2 ⇒ 50000
- P3 code 6 ⇒ 30000

---

## 7) Module 6 — Daily Room Rent Calculation
### What it does
`room_cost = room_daily_rate * stay_days` with discount:
- if `stay_days > 10`, apply 5% discount: multiply by 95/100

### Output
- P1: 2000 * 7 = 14000
- P2: 5000 * 12 = 60000 → discounted = 57000
- P3: 3000 * 5 = 15000

---

## 8) Module 7 — Medicine Billing Module
### What it does
Sum across medicines: `unit_price * quantity * stay_days`

### Output (dataset)
- **P1** (7 days):
  - 50*10*7=3500
  - 120*5*7=4200
  - 200*3*7=4200  
  Total: **11900**
- **P2** (12 days):
  - 0*0*12=0
  - 150*4*12=7200  
  Total: **7200**
- **P3** (5 days):
  - 300*2*5=3000  
  Total: **3000**

---

## 9) Module 8 — Bill Aggregator
### What it does
`total_bill = treatment_cost + room_cost + medicine_cost + lab_test_cost`
with unsigned overflow detection:
- if overflow: `total_bill = 0xFFFFFFFF`, `overflow_flag = 1`

### Output totals (no overflow expected)
Lab tests preserved from `data.s`:
- P1: 25000 + 14000 + 11900 + 3000 = **53900**
- P2: 50000 + 57000 + 7200 + 8000 = **122200**
- P3: 30000 + 15000 + 3000 + 2500 = **50500**

---

## 10) Module 9 — Sort Patients by Criticality
### What it does
Sorts `patient_array` in-place by `alert_count` descending.

### Output (expected order after Module 3)
Alert counts:
- Patient 3: 8
- Patient 1: 4
- Patient 2: 0

Sorted order printed by Module 10:
1. Bob Wilson (1003)
2. John Doe (1001)
3. Jane Smith (1002)

---

## 11) Module 10 — Patient Report Generator
### What it does
Prints:
1. Error log (calls Module 11 `Print_Error_Log`)
2. Then per patient (in sorted order):
   - header
   - patient ID / age / ward
   - “latest vitals”
   - total alerts + status text
   - total bill

### Output (what will be printed)
A) Error log first (Module 11).  
B) Patient summary reports (sorted order):

**Report 1 — Patient 3 / Bob Wilson**
- Patient ID: 1003
- Age: 67
- Ward: 201
- Vitals (Module 10 reads fixed vitals location; in this run slot0 holds the only entry):
  - HR=165, O2=85, SBP=170, DBP=95
- Total alerts: 8 ⇒ “Critical condition”
- Total bill: 50500

**Report 2 — Patient 1 / John Doe**
- Patient ID: 1001
- Age: 45
- Ward: 101
- HR=125, O2=88, SBP=135, DBP=85
- Total alerts: 4 ⇒ “Critical condition” (>=3)
- Total bill: 53900

**Report 3 — Patient 2 / Jane Smith**
- Patient ID: 1002
- Age: 32
- Ward: 102
- HR=78, O2=98, SBP=120, DBP=80
- Total alerts: 0 ⇒ “Patient Stable”
- Total bill: 122200

---

## 12) Module 11 — System Error Detection & Logging
Module 11 includes 3 detection routines + logger + error-log printing.

### 11a) Sensor malfunction detection (`check_sensor_malfunction`)
Maintains last 10 readings for each sensor. If all 10 identical → sensor “stuck”.

**Expected in this run**
Patient 1 writes the same vitals 10 times → stuck sensor detected.
Implementation checks HR first and may return early, so likely only HR is logged.

Expected error:
- Type: SENSOR MALFUNCTION
- Sensor: Heart Rate
- Stuck value: 125
- Patient index: 0
- Patient ID: derived from `patient_array[0]` at log time

### 11b) Invalid dosage (`check_invalid_dosage`)
For each medicine:
- if `unit_price == 0` ⇒ code 1
- else if `quantity == 0` ⇒ code 2

**Expected in this run**
Patient 2 medicine 1 has `unit_price=0` and `quantity=0`.
Checks unit_price first → logs “Zero Unit Price”.

Expected error:
- Type: INVALID DOSAGE
- Issue: Zero Unit Price
- Medicine index: 0
- Patient index: 1
- Patient ID: 1002

### 11c) Memory overflow (`check_memory_overflow`)
- patient pointer >= `PATIENT_ARRAY_MAX (0x20000100)` → boundary error
- `total_bill >= 0xF0000000` → billing overflow pattern

Expected: none in this run.

### Error logging format (`log_error_to_flash`)
- Sets `error_flag = 1`
- Writes 16-byte record into `error_log_buffer` (max 20, circular overwrite):
  - type, patient_index, code, padding
  - timestamp (`system_clock`)
  - value (stuck value / med index / overflow value)
  - patient_id (looked up from `patient_array + index*252`)

### Printed output (high level)
- “SYSTEM ERROR LOG”
- Total errors: likely **2**
  - SENSOR MALFUNCTION (HR stuck at 125, patient ID 1001, timestamp ~ end of loop)
  - INVALID DOSAGE (zero unit price, med index 0, patient ID 1002, timestamp ~3000)

---

## UART/ITM Output Layer (`uart.s`)
Simulated serial printing using ARM ITM registers:
- `ITM_Init`: enables ITM trace control and stimulus port 0
- `ITM_SendChar`: waits until port ready then writes the character

All reports (Module 10 + Module 11 print routines) go through `ITM_SendChar`.

---

## Quick Reference

### Consolidated outputs per module
- **Module 1:** patient fields populated, buffers cleared; lab test costs preserved
- **Module 2:** vital buffers updated (P1: 10 entries, wraps to 0; P2/P3: 1 entry)
- **Module 3:** alerts after checks → P1: 2→4, P2: 0→0, P3: 5→8
- **Module 4:** no dosage due (clock ~3000 < intervals)
- **Module 5 (treatment_cost):** P1=25000, P2=50000, P3=30000
- **Module 6 (room_cost):** P1=14000, P2=57000, P3=15000
- **Module 7 (medicine_cost):** P1=11900, P2=7200, P3=3000
- **Module 8 (total_bill):** P1=53900, P2=122200, P3=50500
- **Module 9 (sorted):** P3 (8), P1 (4), P2 (0)
- **Module 10 (printed):** error log then 3 patient reports in sorted order
- **Module 11:** logs stuck sensor (P1) + invalid dosage (P2)

---

## Output Analysis

### Initial order (initialized in `data.s`)
| Position | RAM Address | Patient ID | Name | Alert_count |
|---------:|------------:|-----------:|------|------------:|
| 0 | 0x200007E4 | 1001 | John Doe | 2 |
| 1 | 0x200008E0 | 1002 | Jane Smith | 0 |
| 2 | 0x200009DC | 1003 | Bob Wilson | 5 |

### Final sorted order (by criticality)
| Position | Patient ID | Name | Alert_count | Status | Total Bill |
|---------:|-----------:|------|------------:|--------|-----------:|
| 0 | 1003 | Bob Wilson | 8 | CRITICAL | 50,500 |
| 1 | 1001 | John Doe | 4 | MODERATE | 53,900 |
| 2 | 1002 | Jane Smith | 0 | STABLE | 122,200 |

### Base addresses (after sorting)
- Position 0 — Bob Wilson: `0x200007E4`
- Position 1 — John Doe: `0x200008E0`
- Position 2 — Jane Smith: `0x200009DC`

---

## Known Implementation Observations
- **Module 10 vital field mapping:** prints BP and O2 using swapped offsets relative to how Module 2 stores them.
- **Alert_count initialization strategy:** `data.s` sets initial `alert_count`; Module 1 intentionally avoids overwriting it.
- **Lab test persistence:** Module 1 does not clear `lab_test_cost`; values from data drive totals.
- **Sensor malfunction early return:** logs first stuck sensor found (HR first), may not log others even if stuck.

---

## Limitations
- Simulation only:
  - UART via ITM (not real UART)
  - Flash writes simulated in RAM
- Fixed patient count:
  - Maximum 3 patients
  - Fixed medicine list size
- Error log capacity:
  - 20 records
  - Circular overwrite
