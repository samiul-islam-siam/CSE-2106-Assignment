# SmartCare-32 — Complete Memory Verification

This document provides **full memory verification** for all three patients in the **SmartCare-32 Patient Monitoring System**, after applying **Module 9: Sorting by `alert_count` (Descending)**.

All data reflects the **final sorted order** in RAM.

# Final Sorted Order (By Criticality)

| Position | Patient ID | Name       | alert_count | Status   | Total Bill |
| -------- | ---------- | ---------- | ----------- | -------- | ---------- |
| **0**    | **1003**   | Bob Wilson | **4 🔴**    | CRITICAL | 47,500     |
| **1**    | **1001**   | John Doe   | **2 🟡**    | MODERATE | 42,000     |
| **2**    | **1002**   | Jane Smith | **0 🟢**    | STABLE   | 115,000    |

# Base Addresses (After Sorting)

| Patient                     | RAM Address  |
| --------------------------- | ------------ |
| **Position 0 — Bob Wilson** | `0x20000080` |
| **Position 1 — John Doe**   | `0x2000021C` |
| **Position 2 — Jane Smith** | `0x200003B8` |

# Patient 1 — Bob Wilson (Most Critical)

### **Base Address:** `0x20000080`

### **Basic Information**

| Offset  | Field             | Value            |
| ------- | ----------------- | ---------------- |
| `+0x00` | patient_id        | **1003**         |
| `+0x04` | name_ptr          | → `"Bob Wilson"` |
| `+0x08` | age               | **67**           |
| `+0x09` | treatment_code    | 6 (Emergency)    |
| `+0x0A` | ward_number       | **201**          |
| `+0x0C` | room_daily_rate   | **3000**         |
| `+0x10` | medicine_list_ptr | NULL             |
| `+0x14` | medicine_count    | 1                |
| `+0x15` | alert_count       | **4**            |
| `+0x16` | stay_days         | 5                |

### **Vital Signs**

| Offset  | Field        | Value          |
| ------- | ------------ | -------------- |
| `+0x18` | heart_rate   | **165 (HIGH)** |
| `+0x19` | oxygen_level | 85 (LOW)       |
| `+0x1A` | systolic_bp  | 170 (HIGH)     |
| `+0x1B` | diastolic_bp | 95             |

### **System Flags**

| Offset  | Field              | Value          |
| ------- | ------------------ | -------------- |
| `+0x40` | vital_buffer_index | 1              |
| `+0x41` | alert_flag         | **1 (ALERT!)** |
| `+0x42` | dosage_due_flag    | 0/1            |

### **Billing**

| Offset   | Field          | Amount     |
| -------- | -------------- | ---------- |
| `+0x184` | treatment_cost | 30,000     |
| `+0x188` | room_cost      | 15,000     |
| `+0x18C` | medicine_cost  | 0          |
| `+0x190` | lab_test_cost  | 2,500      |
| `+0x194` | **total_bill** | **47,500** |
| `+0x198` | overflow_flag  | 0          |

# Patient 2 — John Doe (Moderate Critical)

### **Base Address:** `0x2000021C`

### **Basic Information**

| Offset  | Field             | Value          |
| ------- | ----------------- | -------------- |
| `+0x00` | patient_id        | **1001**       |
| `+0x04` | name_ptr          | → `"John Doe"` |
| `+0x08` | age               | 45             |
| `+0x09` | treatment_code    | 5 (ICU)        |
| `+0x0A` | ward_number       | 101            |
| `+0x0C` | room_daily_rate   | **2000**       |
| `+0x10` | medicine_list_ptr | NULL           |
| `+0x14` | medicine_count    | 3              |
| `+0x15` | alert_count       | **2**          |
| `+0x16` | stay_days         | 7              |

### **Vital Signs**

| Offset  | Field        | Value          |
| ------- | ------------ | -------------- |
| `+0x18` | heart_rate   | **125 (HIGH)** |
| `+0x19` | oxygen_level | 88 (LOW)       |
| `+0x1A` | systolic_bp  | 135            |
| `+0x1B` | diastolic_bp | 85             |

### **System Flags**

| Offset  | Field              | Value          |
| ------- | ------------------ | -------------- |
| `+0x40` | vital_buffer_index | 1              |
| `+0x41` | alert_flag         | **1 (ALERT!)** |
| `+0x42` | dosage_due_flag    | 0/1            |

### **Billing**

| Offset   | Field          | Amount     |
| -------- | -------------- | ---------- |
| `+0x184` | treatment_cost | 25,000     |
| `+0x188` | room_cost      | 14,000     |
| `+0x18C` | medicine_cost  | 0          |
| `+0x190` | lab_test_cost  | 3,000      |
| `+0x194` | **total_bill** | **42,000** |
| `+0x198` | overflow_flag  | 0          |

# Patient 3 — Jane Smith (Least Critical)

### **Base Address:** `0x200003B8`

### **Basic Information**

| Offset  | Field             | Value             |
| ------- | ----------------- | ----------------- |
| `+0x00` | patient_id        | **1002**          |
| `+0x04` | name_ptr          | → `"Jane Smith"`  |
| `+0x08` | age               | 32                |
| `+0x09` | treatment_code    | 2 (Major Surgery) |
| `+0x0A` | ward_number       | 102               |
| `+0x0C` | room_daily_rate   | **5000**          |
| `+0x10` | medicine_list_ptr | NULL              |
| `+0x14` | medicine_count    | 2                 |
| `+0x15` | alert_count       | **0**             |
| `+0x16` | stay_days         | 12                |

### **Vital Signs**

| Offset  | Field        | Value |
| ------- | ------------ | ----- |
| `+0x18` | heart_rate   | 78    |
| `+0x19` | oxygen_level | 98    |
| `+0x1A` | systolic_bp  | 120   |
| `+0x1B` | diastolic_bp | 80    |

### **System Flags**

| Offset  | Field              | Value |
| ------- | ------------------ | ----- |
| `+0x40` | vital_buffer_index | 1     |
| `+0x41` | alert_flag         | 0     |
| `+0x42` | dosage_due_flag    | 0/1   |

### **Billing**

| Offset   | Field          | Value       |
| -------- | -------------- | ----------- |
| `+0x184` | treatment_cost | 50,000      |
| `+0x188` | room_cost      | 57,000      |
| `+0x18C` | medicine_cost  | 0           |
| `+0x190` | lab_test_cost  | 8,000       |
| `+0x194` | **total_bill** | **115,000** |
| `+0x198` | overflow_flag  | 0           |

# Quick Memory Verification Commands

### **Sorted Patient IDs**

```
0x20000080 → EB 03 00 00 (1003)
0x2000021C → E9 03 00 00 (1001)
0x200003B8 → EA 03 00 00 (1002)
```

### **Alert Counts**

```
0x20000080 + 0x15 → 04
0x2000021C + 0x15 → 02
0x200003B8 + 0x15 → 00
```

### **Total Bills**

```
0x20000080 + 0x194 → 8C B9 00 00 (47,500)
0x2000021C + 0x194 → 50 A4 00 00 (42,000)
0x200003B8 + 0x194 → 98 C1 01 00 (115,000)
```
