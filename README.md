# SmartCare-32: ARM-Based Healthcare Monitoring & Billing System

## System Overview (How everything fits together)

### Goal
SmartCare‑32 modernizes DU Medical Center’s embedded monitoring & billing by:
- acquiring vitals continuously (simulated sensors),
- generating alerts from out‑of‑range vitals,
- scheduling medicine administration,
- computing billing (treatment + room + medicine + lab tests),
- performing error detection and logging,
- printing a complete summary via serial/ITM output.

### Execution flow (from `main.s`)
1. Reset `system_clock = 0`
2. Initialize Patient 1 → compute bills (treatment/room/medicine/total)
3. Initialize Patient 2 → compute bills
4. Initialize Patient 3 → compute bills
5. Acquire vitals:
   - Patient 1: loop **10 readings** (also fills sensor_history for malfunction checking)
   - Patient 2: 1 reading
   - Patient 3: 1 reading
6. After each acquisition:
   - Module 11a (sensor malfunction check) runs.
7. For each patient:
   - Module 3 checks thresholds and inserts alert records if violated.
   - Module 4 checks dosage schedule.
   - Module 11b checks invalid dosage.
8. Module 11c checks memory overflow for each patient.
9. Module 9 sorts patients by criticality (alert_count descending).
10. Module 10 prints:
   - Error log first (Module 11 print routine)
   - Then patient summary reports over ITM/UART
