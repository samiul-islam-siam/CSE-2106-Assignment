# SmartCare-32: Healthcare Monitoring & Billing System

## ARM Cortex-M4 Assembly Implementation

This project implements the SmartCare-32 Healthcare Monitoring & Billing System in ARM Cortex-M4 Assembly language for Keil uVision. It focuses on three core modules:

- **Module 2**: Vital Sign Data Acquisition
- **Module 5**: Treatment Cost Computation  
- **Module 9**: Sorting Patients by Criticality

---

## Table of Contents

1. [File Structure](#file-structure)
2. [Conversion Strategy](#conversion-strategy)
3. [Memory Layout Diagrams](#memory-layout-diagrams)
4. [Register Allocation Tables](#register-allocation-tables)
5. [Algorithm Explanations](#algorithm-explanations)
6. [Testing Approach](#testing-approach)
7. [Keil uVision Setup](#keil-uvision-setup)

---

## File Structure

| File | Description |
|------|-------------|
| `data.s` | Data sections, structures, constants, and test patient data |
| `module2.s` | Vital Sign Data Acquisition module |
| `module5.s` | Treatment Cost Computation module |
| `module9.s` | Patient Sorting by Criticality module |
| `main.s` | Main integration program |
| `microlab.c` | Original C reference implementation |
| `README.md` | This documentation file |

---

## Conversion Strategy

### C to ARM Assembly Mapping

| C Construct | ARM Assembly Equivalent |
|-------------|------------------------|
| `uint8_t` variable | `LDRB`/`STRB` instructions |
| `uint16_t` variable | `LDRH`/`STRH` instructions |
| `uint32_t` variable | `LDR`/`STR` instructions |
| Array indexing `arr[i]` | Base address + (index × element_size) |
| Pointer dereference `*ptr` | `LDR Rd, [Rn]` |
| Structure member access | Base address + offset |
| `if-else` statements | `CMP` + conditional branch (`BEQ`, `BNE`, `BLT`, `BGE`) |
| `for` loops | Counter register + `CMP` + `B` loop |
| Function calls | `BL` (Branch with Link) |
| Function return | `BX LR` or `POP {PC}` |
| Modulo arithmetic `% 10` | Comparison and reset (no hardware divide) |

### Memory Access Patterns

```assembly
; Byte access (uint8_t)
LDRB    R0, [R1]            ; Load byte from address in R1
STRB    R0, [R1]            ; Store byte to address in R1

; Halfword access (uint16_t)
LDRH    R0, [R1]            ; Load halfword
STRH    R0, [R1]            ; Store halfword

; Word access (uint32_t)
LDR     R0, [R1]            ; Load word
STR     R0, [R1]            ; Store word

; Offset access (structure member)
LDR     R0, [R1, #offset]   ; Load from R1 + offset
```

### Function Calling Convention (AAPCS)

```assembly
; Parameters: R0-R3
; Return value: R0
; Callee-saved: R4-R11
; Caller-saved: R0-R3, R12

function_name PROC
    PUSH    {R4-R7, LR}     ; Save callee-saved registers
    ; ... function body ...
    POP     {R4-R7, PC}     ; Restore and return
    ENDP
```

---

## Memory Layout Diagrams

### Patient Structure (412 bytes)

```
┌─────────────────────────────────────────────────────────────┐
│ Offset │ Field                │ Size    │ Type              │
├────────┼──────────────────────┼─────────┼───────────────────┤
│ 0x00   │ patient_id           │ 4 bytes │ uint32_t          │
│ 0x04   │ name_ptr             │ 4 bytes │ char*             │
│ 0x08   │ age                  │ 1 byte  │ uint8_t           │
│ 0x09   │ treatment_code       │ 1 byte  │ uint8_t           │
│ 0x0A   │ ward_number          │ 2 bytes │ uint16_t          │
│ 0x0C   │ room_daily_rate      │ 4 bytes │ uint32_t          │
│ 0x10   │ medicine_list_ptr    │ 4 bytes │ Medicine*         │
│ 0x14   │ medicine_count       │ 1 byte  │ uint8_t           │
│ 0x15   │ alert_count          │ 1 byte  │ uint8_t           │
│ 0x16   │ stay_days            │ 2 bytes │ uint16_t          │
│ 0x18   │ vital_buffer[10]     │ 40 bytes│ VitalSign[10]     │
│ 0x40   │ vital_buffer_index   │ 1 byte  │ uint8_t           │
│ 0x41   │ alert_flag           │ 1 byte  │ uint8_t           │
│ 0x42   │ dosage_due_flag      │ 1 byte  │ uint8_t           │
│ 0x43   │ padding              │ 1 byte  │ -                 │
│ 0x44   │ alert_buffer[20]     │ 320 bytes│ AlertRecord[20]  │
│ 0x184  │ billing              │ 24 bytes│ Billing           │
└────────┴──────────────────────┴─────────┴───────────────────┘
Total: 412 bytes (0x19C)
```

### VitalSign Structure (4 bytes)

```
┌─────────────────────────────────────────┐
│ Offset │ Field        │ Size   │ Type   │
├────────┼──────────────┼────────┼────────┤
│ +0     │ heart_rate   │ 1 byte │ uint8_t│
│ +1     │ oxygen_level │ 1 byte │ uint8_t│
│ +2     │ systolic_bp  │ 1 byte │ uint8_t│
│ +3     │ diastolic_bp │ 1 byte │ uint8_t│
└────────┴──────────────┴────────┴────────┘
```

### Billing Structure (24 bytes)

```
┌─────────────────────────────────────────────┐
│ Offset │ Field          │ Size    │ Type    │
├────────┼────────────────┼─────────┼─────────┤
│ 0x00   │ treatment_cost │ 4 bytes │ uint32_t│
│ 0x04   │ room_cost      │ 4 bytes │ uint32_t│
│ 0x08   │ medicine_cost  │ 4 bytes │ uint32_t│
│ 0x0C   │ lab_test_cost  │ 4 bytes │ uint32_t│
│ 0x10   │ total_bill     │ 4 bytes │ uint32_t│
│ 0x14   │ overflow_flag  │ 1 byte  │ uint8_t │
│ 0x15   │ padding        │ 3 bytes │ -       │
└────────┴────────────────┴─────────┴─────────┘
```

### Treatment Cost Table

```
┌───────┬──────────────────┬─────────┐
│ Code  │ Treatment        │ Cost    │
├───────┼──────────────────┼─────────┤
│ 0     │ Basic checkup    │ 5000    │
│ 1     │ Minor surgery    │ 15000   │
│ 2     │ Major surgery    │ 50000   │
│ 3     │ Diagnostic tests │ 8000    │
│ 4     │ Physical therapy │ 12000   │
│ 5     │ ICU admission    │ 25000   │
│ 6     │ Emergency care   │ 30000   │
│ 7     │ Consultation     │ 10000   │
│ 8     │ Imaging          │ 20000   │
│ 9     │ Laboratory       │ 18000   │
│ 10    │ Cardiology       │ 22000   │
│ 11    │ Neurology        │ 27000   │
│ 12    │ Orthopedics      │ 16000   │
│ 13    │ Pediatrics       │ 14000   │
│ 14    │ Oncology         │ 19000   │
│ 15    │ Radiology        │ 21000   │
└───────┴──────────────────┴─────────┘
```

---

## Register Allocation Tables

### Module 2: acquire_vital_signs

| Register | Usage |
|----------|-------|
| R0 | Input: Patient pointer / Temp for sensor reads |
| R1 | Address calculations |
| R2 | Buffer index |
| R3 | Buffer entry address |
| R4 | Patient pointer (preserved) |
| R5 | Heart rate value |
| R6 | Oxygen level value |
| R7 | Systolic BP value |
| LR | Return address |

### Module 5: compute_treatment_cost

| Register | Usage |
|----------|-------|
| R0 | Input: Patient pointer / Cost lookup result |
| R1 | Treatment code |
| R2 | Table base address / Billing address |
| R3 | Index offset (code × 4) |
| R4 | Patient pointer (preserved) |
| LR | Return address |

### Module 9: sort_patients_by_criticality

| Register | Usage |
|----------|-------|
| R0 | Input: Patients array / Swap pointer 1 |
| R1 | Input: Count / Swap pointer 2 |
| R2 | Swap byte counter |
| R3-R4 | Swap temp values |
| R5 | Patient count |
| R6 | Outer loop counter (i) |
| R7 | Loop limit calculations |
| R8 | Inner loop counter (j) |
| R9 | PATIENT_SIZE constant |
| R10 | Address of patients[j] |
| R11 | Address of patients[j+1] |
| LR | Return address |

---

## Algorithm Explanations

### Module 2: Vital Sign Data Acquisition

**Purpose**: Read simulated vital values from memory and store them in a circular buffer.

**Algorithm Steps**:
1. Read sensor values (HR, O2, SBP, DBP) from fixed memory addresses using `LDRB`
2. Get current buffer index from patient structure
3. Calculate buffer entry address: `base + offset + (index × 4)`
4. Store all four vital signs in the buffer entry
5. Increment index with wrap-around: `(index + 1) % 10`
6. Store updated index back to patient structure

```
┌──────────────────┐
│  Read Sensors    │
│  HR, O2, SBP,DBP │
└────────┬─────────┘
         ▼
┌──────────────────┐
│  Get Buffer      │
│  Index (0-9)     │
└────────┬─────────┘
         ▼
┌──────────────────┐
│  Store in        │
│  vital_buffer[i] │
└────────┬─────────┘
         ▼
┌──────────────────┐
│  index = (i+1)%10│
└──────────────────┘
```

### Module 5: Treatment Cost Computation

**Purpose**: Look up treatment cost from a table based on treatment code.

**Algorithm Steps**:
1. Load treatment code from patient structure (byte at offset 0x09)
2. Validate code is within range (0-15)
3. Calculate table address: `table_base + (code × 4)` using `LSL #2`
4. Load cost value from table
5. Store cost in billing structure (offset 0x184)

```
┌──────────────────┐
│  Load treatment  │
│  code (0-15)     │
└────────┬─────────┘
         ▼
┌──────────────────┐
│  code < 16?      │──No──► cost = 0
└────────┬─────────┘
         │Yes
         ▼
┌──────────────────┐
│  cost = table    │
│  [code]          │
└────────┬─────────┘
         ▼
┌──────────────────┐
│  Store in        │
│  billing struct  │
└──────────────────┘
```

### Module 9: Patient Sorting by Criticality

**Purpose**: Sort patients in descending order by alert_count using bubble sort.

**Algorithm Steps**:
1. Outer loop: iterate `count - 1` times
2. Inner loop: compare adjacent patients
3. If `patients[j].alert_count < patients[j+1].alert_count`, swap
4. Swap entire 412-byte structures word-by-word
5. Continue until array is sorted

```
┌─────────────────────────────────────────────────┐
│  for i = 0 to count-2:                          │
│    for j = 0 to count-i-2:                      │
│      if patients[j].alert_count <               │
│         patients[j+1].alert_count:              │
│        swap(patients[j], patients[j+1])         │
└─────────────────────────────────────────────────┘

Before sorting:
┌─────────┬─────────┬─────────┐
│ John(2) │ Jane(0) │ Bob(5)  │
└─────────┴─────────┴─────────┘

After sorting (descending by alerts):
┌─────────┬─────────┬─────────┐
│ Bob(5)  │ John(2) │ Jane(0) │
└─────────┴─────────┴─────────┘
```

---

## Testing Approach

### Test Data Configuration

Three patients are pre-configured in `data.s`:

| Patient | Name | Treatment Code | Alert Count | Expected Cost |
|---------|------|---------------|-------------|---------------|
| 1 | John Doe | 5 (ICU) | 2 | 25,000 |
| 2 | Jane Smith | 2 (Major Surgery) | 0 | 50,000 |
| 3 | Bob Wilson | 6 (Emergency) | 5 | 30,000 |

### Simulated Sensor Values

| Patient | HR | O2 | SBP | DBP | Status |
|---------|----|----|-----|-----|--------|
| John | 125 | 88 | 135 | 85 | High HR, Low O2 |
| Jane | 78 | 98 | 120 | 80 | Normal |
| Bob | 165 | 85 | 170 | 95 | Critical |

### Verification Steps

1. **Module 2 Testing**:
   - Set breakpoint after `acquire_vital_signs`
   - Verify `vital_buffer[index]` contains correct sensor values
   - Verify `vital_buffer_index` increments and wraps at 10

2. **Module 5 Testing**:
   - Set breakpoint after `compute_treatment_cost`
   - Verify `billing.treatment_cost` matches expected values
   - Test invalid code (>15) returns 0

3. **Module 9 Testing**:
   - Set breakpoint after `sort_patients_by_criticality`
   - Verify patient order: Bob (5), John (2), Jane (0)
   - Verify all patient data intact after swap

### Memory Inspection Points

| Address | Expected Value | Description |
|---------|---------------|-------------|
| `patient_array + 0x184` | 25000 | Patient 1 treatment cost |
| `patient_array + PATIENT_SIZE + 0x184` | 50000 | Patient 2 treatment cost |
| `patient_array + 2*PATIENT_SIZE + 0x184` | 30000 | Patient 3 treatment cost |

---

## Keil uVision Setup

### Project Configuration

1. **Create New Project**:
   - File → New → μVision Project
   - Select device: ARM Cortex-M4 (e.g., STM32F407)

2. **Add Source Files**:
   - Right-click Source Group → Add Existing Files
   - Add: `main.s`, `data.s`, `module2.s`, `module5.s`, `module9.s`

3. **Configure Target**:
   - Project → Options for Target
   - Device tab: Select Cortex-M4 processor
   - Target tab: Set IROM1 and IRAM1 addresses

4. **Assembler Settings**:
   - Asm tab: Enable "Thumb Mode"
   - Misc Controls: `--cpu Cortex-M4`

### Build and Debug

1. **Build Project**: Project → Build Target (F7)
2. **Start Debug Session**: Debug → Start/Stop Debug Session (Ctrl+F5)
3. **Set Breakpoints**: Click in left margin of source file
4. **Run**: Debug → Run (F5)
5. **Step Through**: Debug → Step (F11)

### Memory View Configuration

- View → Memory Windows → Memory 1
- Enter address: `0x20000000` (RAM start)
- View patient structures and verify values

### Watch Window

Add these symbols to watch:
- `patient_array`
- `system_clock`
- `treatment_cost_table`

---

## Success Criteria Checklist

- ✅ All files compile without errors in Keil uVision
- ✅ Proper structure alignment and memory management
- ✅ Modular design with EXPORT/IMPORT directives
- ✅ Comments explaining every major operation
- ✅ Test data produces expected results
- ✅ Code follows ARM Cortex-M4 conventions
- ✅ Comprehensive documentation included

---

## Author

CSE 2106: Microprocessor and Assembly Language Lab Assignment
