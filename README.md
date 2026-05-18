# SmartCare-32  
## ARM-Based Healthcare Monitoring & Billing System

## Introduction
**SmartCare-32** is an ARM Cortex‑M based embedded firmware prototype for **DU Medical Center (2025)**. The system stores patient records in RAM, continuously reads simulated vital sensors (HR, SpO₂, blood pressure) into rolling buffers, detects dangerous threshold conditions and logs **16‑byte alert records** with timestamps, and manages medication schedules using an internal clock.

It also computes treatment, room, medicine, and lab costs, aggregates the final bill with **overflow checking**, sorts patients by **criticality (alert count)** for triage, securely logs anomalies (sensor malfunction, invalid dosage, memory boundary issues), and outputs a formatted patient summary report through serial/UART-style output (ITM simulation).

## System Overview

SmartCare‑32 modernizes DU Medical Center’s embedded monitoring & billing by:
- Acquiring vitals continuously (simulated sensors)
- Generating alerts from out‑of‑range vitals
- Scheduling medicine administration
- Computing billing (treatment + room + medicine + lab tests)
- Performing error detection and logging
- Printing a complete summary via serial/ITM output

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

## Known Implementation Observations
- **Module 10 vital field mapping:** prints BP and O2 using swapped offsets relative to how Module 2 stores them.
- **Alert_count initialization strategy:** `data.s` sets initial `alert_count`; Module 1 intentionally avoids overwriting it.
- **Lab test persistence:** Module 1 does not clear `lab_test_cost`; values from data drive totals.
- **Sensor malfunction early return:** logs first stuck sensor found (HR first), may not log others even if stuck.

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
