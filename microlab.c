
#include <stdint.h>
#include <stdio.h>
#include <string.h>

// ============================================================================
// STRUCTURE DEFINITIONS
// ============================================================================

// Medicine structure
typedef struct
{
    uint8_t medicine_id;
    uint8_t dosage_interval_hours;
    uint32_t last_administered_time;
    uint32_t unit_price;
    uint16_t quantity;
    uint8_t padding[3]; // Alignment padding
} Medicine;

// Vital signs structure
typedef struct
{
    uint8_t heart_rate;
    uint8_t oxygen_level;
    uint8_t systolic_bp;
    uint8_t diastolic_bp;
} VitalSign;

// Alert record structure
typedef struct
{
    uint8_t vital_type; // 0=HR, 1=O2, 2=BP
    uint8_t actual_reading;
    uint16_t padding;
    uint32_t timestamp;
    uint8_t reserved[8]; // Total 16 bytes
} AlertRecord;

// Billing structure
typedef struct
{
    uint32_t treatment_cost;
    uint32_t room_cost;
    uint32_t medicine_cost;
    uint32_t lab_test_cost;
    uint32_t total_bill;
    uint8_t overflow_flag;
    uint8_t padding[3];
} Billing;

// Patient structure
typedef struct
{
    uint32_t patient_id;
    char *name_ptr;
    uint8_t age;
    uint8_t treatment_code;
    uint16_t ward_number;
    uint32_t room_daily_rate;
    Medicine *medicine_list_ptr;
    uint8_t medicine_count;
    uint8_t alert_count;
    uint16_t stay_days;
    VitalSign vital_buffer[10];
    uint8_t vital_buffer_index;
    uint8_t alert_flag;
    uint8_t dosage_due_flag;
    uint8_t padding;
    AlertRecord alert_buffer[20];
    Billing billing;
} Patient;

// ============================================================================
// GLOBAL DATA
// ============================================================================

// Treatment cost lookup table
uint32_t treatment_cost_table[16] = {
    5000,  // Code 0: Basic checkup
    15000, // Code 1: Minor surgery
    50000, // Code 2: Major surgery
    8000,  // Code 3: Diagnostic tests
    12000, // Code 4: Physical therapy
    25000, // Code 5: ICU admission
    30000, // Code 6: Emergency care
    10000, // Code 7: Consultation
    20000, // Code 8: Imaging
    18000, // Code 9: Laboratory
    22000, // Code 10: Cardiology
    27000, // Code 11: Neurology
    16000, // Code 12: Orthopedics
    14000, // Code 13: Pediatrics
    19000, // Code 14: Oncology
    21000  // Code 15: Radiology
};

// Simulated vital sensor memory addresses
volatile uint8_t *SENSOR_HR = (uint8_t *)0x40000000;
volatile uint8_t *SENSOR_O2 = (uint8_t *)0x40000001;
volatile uint8_t *SENSOR_SBP = (uint8_t *)0x40000002;
volatile uint8_t *SENSOR_DBP = (uint8_t *)0x40000003;

// System clock counter
volatile uint32_t system_clock = 0;

// ============================================================================
// MODULE 1: PATIENT RECORD INITIALIZATION
// ============================================================================

void initialize_patient(Patient *patient, uint32_t id, char *name, uint8_t age,
                        uint16_t ward, uint8_t treatment_code,
                        uint32_t room_rate, Medicine *med_list, uint8_t med_count,
                        uint16_t stay_days)
{
    patient->patient_id = id;
    patient->name_ptr = name;
    patient->age = age;
    patient->ward_number = ward;
    patient->treatment_code = treatment_code;
    patient->room_daily_rate = room_rate;
    patient->medicine_list_ptr = med_list;
    patient->medicine_count = med_count;
    patient->stay_days = stay_days;
    patient->vital_buffer_index = 0;
    patient->alert_count = 0;
    patient->alert_flag = 0;
    patient->dosage_due_flag = 0;

    // Initialize billing to zero
    memset(&patient->billing, 0, sizeof(Billing));

    // Initialize vital buffer
    memset(patient->vital_buffer, 0, sizeof(patient->vital_buffer));

    // Initialize alert buffer
    memset(patient->alert_buffer, 0, sizeof(patient->alert_buffer));
}

// ============================================================================
// MODULE 2: VITAL SIGN DATA ACQUISITION
// ============================================================================

void acquire_vital_signs(Patient *patient)
{
    // Read from simulated sensors
    uint8_t hr = *SENSOR_HR;
    uint8_t o2 = *SENSOR_O2;
    uint8_t sbp = *SENSOR_SBP;
    uint8_t dbp = *SENSOR_DBP;

    // Store in rolling buffer
    uint8_t index = patient->vital_buffer_index;
    patient->vital_buffer[index].heart_rate = hr;
    patient->vital_buffer[index].oxygen_level = o2;
    patient->vital_buffer[index].systolic_bp = sbp;
    patient->vital_buffer[index].diastolic_bp = dbp;

    // Update index with modulo arithmetic (rolling buffer)
    patient->vital_buffer_index = (index + 1) % 10;
}

// ============================================================================
// MODULE 3: VITAL THRESHOLD ALERT MODULE
// ============================================================================

void check_vital_thresholds(Patient *patient)
{
    uint8_t current_index = (patient->vital_buffer_index == 0) ? 9 : patient->vital_buffer_index - 1;
    VitalSign *current_vital = &patient->vital_buffer[current_index];

    // Check Heart Rate > 120
    if (current_vital->heart_rate > 120)
    {
        patient->alert_flag = 1;
        if (patient->alert_count < 20)
        {
            AlertRecord *alert = &patient->alert_buffer[patient->alert_count];
            alert->vital_type = 0; // HR
            alert->actual_reading = current_vital->heart_rate;
            alert->timestamp = system_clock;
            patient->alert_count++;
        }
    }

    // Check O2 < 92
    if (current_vital->oxygen_level < 92)
    {
        patient->alert_flag = 1;
        if (patient->alert_count < 20)
        {
            AlertRecord *alert = &patient->alert_buffer[patient->alert_count];
            alert->vital_type = 1; // O2
            alert->actual_reading = current_vital->oxygen_level;
            alert->timestamp = system_clock;
            patient->alert_count++;
        }
    }

    // Check SBP > 160 or < 90
    if (current_vital->systolic_bp > 160 || current_vital->systolic_bp < 90)
    {
        patient->alert_flag = 1;
        if (patient->alert_count < 20)
        {
            AlertRecord *alert = &patient->alert_buffer[patient->alert_count];
            alert->vital_type = 2; // BP
            alert->actual_reading = current_vital->systolic_bp;
            alert->timestamp = system_clock;
            patient->alert_count++;
        }
    }
}

// ============================================================================
// MODULE 4: MEDICINE ADMINISTRATION SCHEDULER
// ============================================================================

void check_medicine_schedule(Patient *patient)
{
    patient->dosage_due_flag = 0;

    for (uint8_t i = 0; i < patient->medicine_count; i++)
    {
        Medicine *med = &patient->medicine_list_ptr[i];
        uint32_t next_due_time = med->last_administered_time + (med->dosage_interval_hours * 3600);

        if (system_clock >= next_due_time)
        {
            patient->dosage_due_flag = 1;
            // Update last administered time
            med->last_administered_time = system_clock;
        }
    }
}

// ============================================================================
// MODULE 5: TREATMENT COST COMPUTATION
// ============================================================================

void compute_treatment_cost(Patient *patient)
{
    uint8_t code = patient->treatment_code;
    if (code < 16)
    {
        patient->billing.treatment_cost = treatment_cost_table[code];
    }
    else
    {
        patient->billing.treatment_cost = 0; // Invalid code
    }
}

// ============================================================================
// MODULE 6: DAILY ROOM RENT CALCULATION
// ============================================================================

void compute_room_cost(Patient *patient)
{
    uint32_t rate = patient->room_daily_rate;
    uint16_t days = patient->stay_days;
    uint32_t room_cost = rate * days;

    // Apply 5% discount if days > 10
    if (days > 10)
    {
        // 5% discount = multiply by 0.95 = multiply by 19/20
        room_cost = (room_cost * 19) / 20;
    }

    patient->billing.room_cost = room_cost;
}

// ============================================================================
// MODULE 7: MEDICINE BILLING MODULE
// ============================================================================

void compute_medicine_cost(Patient *patient)
{
    uint32_t total_medicine_cost = 0;

    for (uint8_t i = 0; i < patient->medicine_count; i++)
    {
        Medicine *med = &patient->medicine_list_ptr[i];
        uint32_t med_cost = med->unit_price * med->quantity * patient->stay_days;
        total_medicine_cost += med_cost;
    }

    patient->billing.medicine_cost = total_medicine_cost;
}

// ============================================================================
// MODULE 8: PATIENT BILL AGGREGATOR
// ============================================================================

void aggregate_total_bill(Patient *patient)
{
    uint32_t treatment = patient->billing.treatment_cost;
    uint32_t room = patient->billing.room_cost;
    uint32_t medicine = patient->billing.medicine_cost;
    uint32_t lab = patient->billing.lab_test_cost;

    // Check for overflow
    uint32_t temp = treatment + room;
    if (temp < treatment)
    { // Overflow detected
        patient->billing.overflow_flag = 1;
        patient->billing.total_bill = 0xFFFFFFFF;
        return;
    }

    temp += medicine;
    if (temp < medicine)
    { // Overflow detected
        patient->billing.overflow_flag = 1;
        patient->billing.total_bill = 0xFFFFFFFF;
        return;
    }

    temp += lab;
    if (temp < lab)
    { // Overflow detected
        patient->billing.overflow_flag = 1;
        patient->billing.total_bill = 0xFFFFFFFF;
        return;
    }

    patient->billing.total_bill = temp;
    patient->billing.overflow_flag = 0;
}

// ============================================================================
// MODULE 9: SORTING PATIENTS BY CRITICALITY
// ============================================================================

void sort_patients_by_criticality(Patient *patients, uint8_t count)
{
    // Bubble sort based on alert_count (descending order)
    for (uint8_t i = 0; i < count - 1; i++)
    {
        for (uint8_t j = 0; j < count - i - 1; j++)
        {
            if (patients[j].alert_count < patients[j + 1].alert_count)
            {
                // Swap entire patient structures
                Patient temp = patients[j];
                patients[j] = patients[j + 1];
                patients[j + 1] = temp;
            }
        }
    }
}

// ============================================================================
// UART OUTPUT FUNCTIONS
// ============================================================================

void print_patient_summary(Patient *patient)
{
    printf("\n========================================\n");
    printf("PATIENT SUMMARY - SmartCare-32\n");
    printf("========================================\n");
    printf("Patient ID: %lu\n", patient->patient_id);
    printf("Name: %s\n", patient->name_ptr);
    printf("Age: %u years\n", patient->age);
    printf("Ward Number: %u\n", patient->ward_number);
    printf("Stay Days: %u\n", patient->stay_days);
    printf("\n--- VITAL SIGNS (Latest) ---\n");
    uint8_t idx = (patient->vital_buffer_index == 0) ? 9 : patient->vital_buffer_index - 1;
    printf("Heart Rate: %u bpm\n", patient->vital_buffer[idx].heart_rate);
    printf("Oxygen Level: %u%%\n", patient->vital_buffer[idx].oxygen_level);
    printf("Blood Pressure: %u/%u mmHg\n",
           patient->vital_buffer[idx].systolic_bp,
           patient->vital_buffer[idx].diastolic_bp);

    printf("\n--- ALERTS ---\n");
    printf("Total Alerts: %u\n", patient->alert_count);
    printf("Alert Flag: %s\n", patient->alert_flag ? "ACTIVE" : "CLEAR");

    printf("\n--- MEDICATION ---\n");
    printf("Dosage Due Flag: %s\n", patient->dosage_due_flag ? "YES" : "NO");
    printf("Medicine Count: %u\n", patient->medicine_count);

    printf("\n--- BILLING DETAILS ---\n");
    printf("Treatment Cost: Rs. %lu\n", patient->billing.treatment_cost);
    printf("Room Cost: Rs. %lu\n", patient->billing.room_cost);
    printf("Medicine Cost: Rs. %lu\n", patient->billing.medicine_cost);
    printf("Lab Test Cost: Rs. %lu\n", patient->billing.lab_test_cost);
    printf("----------------------------------------\n");
    if (patient->billing.overflow_flag)
    {
        printf("TOTAL BILL: OVERFLOW ERROR!\n");
    }
    else
    {
        printf("TOTAL BILL: Rs. %lu\n", patient->billing.total_bill);
    }
    printf("========================================\n\n");
}

// ============================================================================
// MAIN FUNCTION - SYSTEM INTEGRATION
// ============================================================================

int main(void)
{
    // Test data initialization
    char patient1_name[] = "John Doe";
    char patient2_name[] = "Jane Smith";
    char patient3_name[] = "Bob Wilson";

    // Medicine lists
    Medicine patient1_medicines[3] = {
        {1, 6, 0, 50, 10, {0}}, // Med 1: 6hr interval, Rs.50/unit, qty 10
        {2, 8, 0, 120, 5, {0}}, // Med 2: 8hr interval, Rs.120/unit, qty 5
        {3, 12, 0, 200, 3, {0}} // Med 3: 12hr interval, Rs.200/unit, qty 3
    };

    Medicine patient2_medicines[2] = {
        {4, 4, 0, 80, 8, {0}}, // Med 4: 4hr interval, Rs.80/unit, qty 8
        {5, 6, 0, 150, 4, {0}} // Med 5: 6hr interval, Rs.150/unit, qty 4
    };

    Medicine patient3_medicines[1] = {
        {6, 24, 0, 300, 2, {0}} // Med 6: 24hr interval, Rs.300/unit, qty 2
    };

    // Patient array
    Patient patients[3];

    // Initialize patients
    initialize_patient(&patients[0], 1001, patient1_name, 45, 101, 5, 2000,
                       patient1_medicines, 3, 7);
    initialize_patient(&patients[1], 1002, patient2_name, 32, 102, 2, 5000,
                       patient2_medicines, 2, 12);
    initialize_patient(&patients[2], 1003, patient3_name, 67, 201, 6, 3000,
                       patient3_medicines, 1, 5);

    // Set lab test costs
    patients[0].billing.lab_test_cost = 3000;
    patients[1].billing.lab_test_cost = 8000;
    patients[2].billing.lab_test_cost = 2500;

    // Simulate sensor data (normally would read from hardware)
    uint8_t simulated_hr[3] = {125, 78, 165};   // P1: High, P2: Normal, P3: Critical
    uint8_t simulated_o2[3] = {88, 98, 85};     // P1: Low, P2: Normal, P3: Critical
    uint8_t simulated_sbp[3] = {135, 120, 170}; // P1: Normal, P2: Normal, P3: High
    uint8_t simulated_dbp[3] = {85, 80, 95};

    printf("\n");
    printf("*************************************************\n");
    printf("* SmartCare-32: Healthcare Monitoring System *\n");
    printf("* ARM Cortex-M Embedded Firmware *\n");
    printf("* DU Medical Center - 2025 *\n");
    printf("*************************************************\n");

    // Process each patient
    for (uint8_t i = 0; i < 3; i++)
    {
        printf("\n[Processing Patient %u...]\n", i + 1);

        // Simulate sensor readings
        *SENSOR_HR = simulated_hr[i];
        *SENSOR_O2 = simulated_o2[i];
        *SENSOR_SBP = simulated_sbp[i];
        *SENSOR_DBP = simulated_dbp[i];

        // Acquire vital signs (Module 2)
        for (uint8_t j = 0; j < 10; j++)
        {
            acquire_vital_signs(&patients[i]);
            system_clock += 300; // Simulate 5 minutes
        }

        // Check vital thresholds (Module 3)
        check_vital_thresholds(&patients[i]);

        // Check medicine schedule (Module 4)
        system_clock += 21600; // Simulate 6 hours
        check_medicine_schedule(&patients[i]);

        // Compute treatment cost (Module 5)
        compute_treatment_cost(&patients[i]);

        // Compute room cost (Module 6)
        compute_room_cost(&patients[i]);

        // Compute medicine cost (Module 7)
        compute_medicine_cost(&patients[i]);

        // Aggregate total bill (Module 8)
        aggregate_total_bill(&patients[i]);
    }

    // Sort patients by criticality (Module 9)
    printf("\n[Sorting patients by criticality...]\n");
    sort_patients_by_criticality(patients, 3);

    // Print summaries in priority order
    printf("\n*************************************************\n");
    printf("* PATIENT SUMMARIES (Sorted by Criticality) *\n");
    printf("*************************************************\n");

    for (uint8_t i = 0; i < 3; i++)
    {
        printf("\nPRIORITY RANK: %u\n", i + 1);
        print_patient_summary(&patients[i]);
    }

    printf("\n[SmartCare-32 System Processing Complete]\n\n");

    return 0;
}