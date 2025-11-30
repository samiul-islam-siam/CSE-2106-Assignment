# SmartCare-32 — Complete Memory Verification

This document provides **full memory verification** for all three patients in the **SmartCare-32 Patient Monitoring System**, after applying **Module 9: Sorting by `alert_count` (Descending)**.

All data reflects the **final sorted order** in RAM.

# Final Sorted Order (By Criticality)

| Position | Patient ID        | Name       | alert_count  | Status   | Total Bill           |
| -------- | ----------------- | ---------- | ------------ | -------- |----------------------|
| **0**    | **1003 (0x03EB)** | Bob Wilson | **4 (0x04)** | CRITICAL | 50,500 (0x0000C544)  |
| **1**    | **1001 (0x03E9)** | John Doe   | **2 (0x02)** | MODERATE | 42,000 (0x0000A410)  |
| **2**    | **1002 (0x03EA)** | Jane Smith | **0 (0x00)** | STABLE   | 115,000 (0x0001C138) |

# Base Addresses (After Sorting)

| Patient                     | RAM Address  |
| --------------------------- |--------------|
| **Position 0 — Bob Wilson** | `0x200000EO` |
| **Position 1 — John Doe**   | `0x2000027C` |
| **Position 2 — Jane Smith** | `0x20000418` |

# Patient 1 — Bob Wilson (Most Critical)

### **Base Address:** `0x200000E0`

## **Basic Information**

| Offset  | Field             | Decimal              | Hex            |
| ------- | ----------------- |----------------------|----------------|
| `+0x00` | patient_id        | **1003**             | **0x03EB**     |
| `+0x04` | name_ptr          | → `"Bob Wilson"`     | (pointer)      |
| `+0x08` | age               | **67**               | **0x43**       |
| `+0x09` | treatment_code    | **6**                | **0x06**       |
| `+0x0A` | ward_number       | **201**              | **0x00C9**     |
| `+0x0C` | room_daily_rate   | **3000**             | **0x00000BB8** |
| `+0x10` | medicine_list_ptr | → `"medicine_ptr_3"` | **0x20000080** |
| `+0x14` | medicine_count    | **1**                | **0x01**       |
| `+0x15` | alert_count       | **4**                | **0x04**       |
| `+0x16` | stay_days         | **5**                | **0x0005**     |

## **Vital Signs**

| Offset  | Field        | Decimal | Hex      |
| ------- | ------------ | ------- | -------- |
| `+0x18` | heart_rate   | **165** | **0xA5** |
| `+0x19` | oxygen_level | **85**  | **0x55** |
| `+0x1A` | systolic_bp  | **170** | **0xAA** |
| `+0x1B` | diastolic_bp | **95**  | **0x5F** |

## **System Flags**

| Offset  | Field              | Decimal | Hex         |
| ------- | ------------------ | ------- | ----------- |
| `+0x40` | vital_buffer_index | **1**   | **0x01**    |
| `+0x41` | alert_flag         | **1**   | **0x01**    |
| `+0x42` | dosage_due_flag    | **0/1** | 0x00 / 0x01 |

## **Billing**

| Offset   | Field          | Decimal    | Hex            |
| -------- | -------------- |------------|----------------|
| `+0x184` | treatment_cost | **30,000** | **0x00007530** |
| `+0x188` | room_cost      | **15,000** | **0x00003A98** |
| `+0x18C` | medicine_cost  | **3,000**  | **0x00000BB8** |
| `+0x190` | lab_test_cost  | **2,500**  | **0x000009C4** |
| `+0x194` | total_bill     | **50,500** | **0x0000C544** |
| `+0x198` | overflow_flag  | **0**      | **0x00**       |

# Patient 2 — John Doe (Moderate Critical)

### **Base Address:** `0x2000027C`

## **Basic Information**

| Offset  | Field             | Decimal        | Hex            |
| ------- | ----------------- | -------------- | -------------- |
| `+0x00` | patient_id        | **1001**       | **0x03E9**     |
| `+0x04` | name_ptr          | → `"John Doe"` | (pointer)      |
| `+0x08` | age               | **45**         | **0x2D**       |
| `+0x09` | treatment_code    | **5**          | **0x05**       |
| `+0x0A` | ward_number       | **101**        | **0x0065**     |
| `+0x0C` | room_daily_rate   | **2000**       | **0x000007D0** |
| `+0x10` | medicine_list_ptr | NULL           | **0x00000000** |
| `+0x14` | medicine_count    | **3**          | **0x03**       |
| `+0x15` | alert_count       | **2**          | **0x02**       |
| `+0x16` | stay_days         | **7**          | **0x0007**     |

## **Vital Signs**

| Offset  | Field        | Decimal | Hex      |
| ------- | ------------ | ------- | -------- |
| `+0x18` | heart_rate   | **125** | **0x7D** |
| `+0x19` | oxygen_level | **88**  | **0x58** |
| `+0x1A` | systolic_bp  | **135** | **0x87** |
| `+0x1B` | diastolic_bp | **85**  | **0x55** |

## **System Flags**

| Offset  | Field              | Decimal | Hex         |
| ------- | ------------------ | ------- | ----------- |
| `+0x40` | vital_buffer_index | **1**   | **0x01**    |
| `+0x41` | alert_flag         | **1**   | **0x01**    |
| `+0x42` | dosage_due_flag    | **0/1** | 0x00 / 0x01 |

## **Billing**

| Offset   | Field          | Decimal    | Hex            |
| -------- | -------------- | ---------- |----------------|
| `+0x184` | treatment_cost | **25,000** | **0x000061A8** |
| `+0x188` | room_cost      | **14,000** | **0x000036B0** |
| `+0x18C` | medicine_cost  | **0**      | **0x00000000** |
| `+0x190` | lab_test_cost  | **3,000**  | **0x00000BB8** |
| `+0x194` | total_bill     | **42,000** | **0x0000A410** |
| `+0x198` | overflow_flag  | **0**      | **0x00**       |

# Patient 3 — Jane Smith (Least Critical)

### **Base Address:** `0x20000418`

## **Basic Information**

| Offset  | Field             | Decimal          | Hex            |
| ------- | ----------------- | ---------------- | -------------- |
| `+0x00` | patient_id        | **1002**         | **0x03EA**     |
| `+0x04` | name_ptr          | → `"Jane Smith"` | (pointer)      |
| `+0x08` | age               | **32**           | **0x20**       |
| `+0x09` | treatment_code    | **2**            | **0x02**       |
| `+0x0A` | ward_number       | **102**          | **0x0066**     |
| `+0x0C` | room_daily_rate   | **5000**         | **0x00001388** |
| `+0x10` | medicine_list_ptr | NULL             | **0x00000000** |
| `+0x14` | medicine_count    | **2**            | **0x02**       |
| `+0x15` | alert_count       | **0**            | **0x00**       |
| `+0x16` | stay_days         | **12**           | **0x000C**     |

## **Vital Signs**

| Offset  | Field        | Decimal | Hex      |
| ------- | ------------ | ------- | -------- |
| `+0x18` | heart_rate   | **78**  | **0x4E** |
| `+0x19` | oxygen_level | **98**  | **0x62** |
| `+0x1A` | systolic_bp  | **120** | **0x78** |
| `+0x1B` | diastolic_bp | **80**  | **0x50** |

## **System Flags**

| Offset  | Field              | Decimal | Hex         |
| ------- | ------------------ | ------- | ----------- |
| `+0x40` | vital_buffer_index | **1**   | **0x01**    |
| `+0x41` | alert_flag         | **0**   | **0x00**    |
| `+0x42` | dosage_due_flag    | **0/1** | 0x00 / 0x01 |

## **Billing**

| Offset   | Field          | Decimal     | Hex            |
| -------- | -------------- | ----------- |----------------|
| `+0x184` | treatment_cost | **50,000**  | **0x0000C350** |
| `+0x188` | room_cost      | **57,000**  | **0x0000DEA8** |
| `+0x18C` | medicine_cost  | **0**       | **0x00000000** |
| `+0x190` | lab_test_cost  | **8,000**   | **0x00001F40** |
| `+0x194` | total_bill     | **115,000** | **0x0001C138** |
| `+0x198` | overflow_flag  | **0**       | **0x00**       |

# Quick Memory Verification

### **Sorted IDs**

```
0x20000080 → EB 03 00 00 (1003 / 0x03EB)
0x2000021C → E9 03 00 00 (1001 / 0x03E9)
0x200003B8 → EA 03 00 00 (1002 / 0x03EA)
```

### **Alert Counts**

```
0x20000080 + 0x15 → 04 (0x04)
0x2000021C + 0x15 → 02 (0x02)
0x200003B8 + 0x15 → 00 (0x00)
```

### **Total Bills**

```
0x20000080 + 0x194 → 44 C5 00 00 (50,500 / 0x0000C544)
0x2000021C + 0x194 → 50 A4 00 00 (42,000 / 0x0000A450)
0x200003B8 + 0x194 → 98 C1 01 00 (115,000 / 0x0001C198)
```