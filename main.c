#include <stdint.h>

// ITM register addresses for UART output simulation
#define ITM_PORT0   (*((volatile uint32_t *)0xE0000000))
#define ITM_TER     (*((volatile uint32_t *)0xE0000E00))
#define ITM_TCR     (*((volatile uint32_t *)0xE0000E80))

// UART registers (for actual hardware UART)
#define UART0_BASE  0x4000C000
#define UART_DR     (*((volatile uint32_t *)(UART0_BASE + 0x000)))
#define UART_FR     (*((volatile uint32_t *)(UART0_BASE + 0x018)))
#define UART_IBRD   (*((volatile uint32_t *)(UART0_BASE + 0x024)))
#define UART_FBRD   (*((volatile uint32_t *)(UART0_BASE + 0x028)))
#define UART_LCRH   (*((volatile uint32_t *)(UART0_BASE + 0x02C)))
#define UART_CR     (*((volatile uint32_t *)(UART0_BASE + 0x030)))

// Patient structure offsets (must match your assembly data structure)
#define PATIENT_SIZE        412
#define PATIENT_ID_OFF      0x00
#define PATIENT_AGE_OFF     0x08
#define WARD_OFF            0x0A
#define ALERT_COUNT_OFF     0x15
#define VITAL_BUFFER_OFF    0x18
#define TOTAL_BILL_OFF      0x194    // Adjust based on your actual structure

// Import patient array and sensors from assembly modules
extern uint8_t patient_array[];

// ============================================================================
// UART / ITM helpers
// ============================================================================
void UART_Init_C(void) {
    UART_CR = 0;
    UART_IBRD = 104;
    UART_FBRD = 11;
    UART_LCRH = 0x70;
    UART_CR = 0x301;
}

void ITM_SendChar(char ch) {
    while ((ITM_PORT0 & 1) == 0);
    ITM_PORT0 = ch;
}

void ITM_SendString(const char *str) {
    while (*str) {
        ITM_SendChar(*str);
        str++;
    }
}

void ITM_SendInt(uint32_t num) {
    char buffer[12];
    int i = 0;
    if (num == 0) {
        ITM_SendChar('0');
        return;
    }
    while (num > 0 && i < (int)sizeof(buffer)) {
        buffer[i++] = '0' + (num % 10);
        num /= 10;
    }
    while (i > 0) {
        i--;
        ITM_SendChar(buffer[i]);
    }
}

void PrintSeparator(void) {
    ITM_SendString("\r\n\r\n");
		ITM_SendString("\r\n\r\n");
}

// ============================================================================
// Patient Data Structure (matching data.s layout)
// ============================================================================
typedef struct {
    uint32_t id;
    uint8_t  age;
    uint16_t ward;
    uint8_t  hr;
    uint8_t  sbp;
    uint8_t  dbp;
    uint8_t  o2;
    uint8_t  alert_count;
    uint32_t total_bill;
} PatientData;

// ============================================================================
// Extract Patient Data from Assembly Structure
// ============================================================================
void ExtractPatientData(uint8_t *patient_ptr, PatientData *data) {
    data->id = *((uint32_t *)(patient_ptr + PATIENT_ID_OFF));
    data->age = *(uint8_t *)(patient_ptr + PATIENT_AGE_OFF);
    data->ward = (uint16_t)(patient_ptr[WARD_OFF]) | ((uint16_t)patient_ptr[WARD_OFF + 1] << 8);
    data->hr  = *(uint8_t *)(patient_ptr + VITAL_BUFFER_OFF + 0);
    data->sbp = *(uint8_t *)(patient_ptr + VITAL_BUFFER_OFF + 1);
    data->dbp = *(uint8_t *)(patient_ptr + VITAL_BUFFER_OFF + 2);
    data->o2  = *(uint8_t *)(patient_ptr + VITAL_BUFFER_OFF + 3);
    data->alert_count = *(uint8_t *)(patient_ptr + ALERT_COUNT_OFF);
    data->total_bill = *((uint32_t *)(patient_ptr + TOTAL_BILL_OFF));
}

// ============================================================================
// Generate Formatted Summary (All Required Fields)
// ============================================================================
void PrintPatientReport_C(PatientData *data) {
		// Header
    ITM_SendString("==================================================\r\n");
    ITM_SendString("    PATIENT SUMMARY REPORT\r\n");
    ITM_SendString("    SmartCare-32: Healthcare Monitoring System\r\n");
    ITM_SendString("==================================================\r\n");
    
    // Patient Information (Required Field: Patient ID, Age, Ward)
    ITM_SendString("PATIENT INFORMATION:\r\n");
    ITM_SendString("--------------------------------------------------\r\n");
    ITM_SendString("  Patient ID       : ");
    ITM_SendInt(data->id);
    ITM_SendString("\r\n");
    
    ITM_SendString("  Age              : ");
    ITM_SendInt(data->age);
    ITM_SendString(" years\r\n");
    
    ITM_SendString("  Ward Number      : ");
    ITM_SendInt(data->ward);
    ITM_SendString("\r\n");
    
    // Latest Vitals (Required Field: Latest vitals)
		ITM_SendString("--------------------------------------------------\r\n");
    ITM_SendString("LATEST VITAL SIGNS:\r\n");
    ITM_SendString("--------------------------------------------------\r\n");
    
    ITM_SendString("  Heart Rate       : ");
    ITM_SendInt(data->hr);
    ITM_SendString(" bpm\r\n");
    
    ITM_SendString("  Blood Pressure   : ");
    ITM_SendInt(data->sbp);
    ITM_SendString("/");
    ITM_SendInt(data->dbp);
    ITM_SendString(" mmHg\r\n");
    
    ITM_SendString("  SpO2 (Oxygen)    : ");
    ITM_SendInt(data->o2);
    ITM_SendString(" %\r\n");
    
    // Total Alerts (Required Field: Total alerts)
		ITM_SendString("--------------------------------------------------\r\n");
    ITM_SendString("ALERT SUMMARY:\r\n");
    ITM_SendString("--------------------------------------------------\r\n");
    ITM_SendString("  Total Alerts     : ");
    ITM_SendInt(data->alert_count);
    
    // Alert status based on count
    if (data->alert_count == 0) {
        ITM_SendString(" (Patient Stable)");
    } else if (data->alert_count < 3) {
        ITM_SendString(" (Attention Required)");
    } else {
        ITM_SendString(" (Critical condition)");
    }
    ITM_SendString("\r\n");
    
    // Billing Summary (Required Field: Billing summary)
    ITM_SendString("--------------------------------------------------\r\n");
    ITM_SendString("BILLING SUMMARY:\r\n");
    ITM_SendString("--------------------------------------------------\r\n");
    ITM_SendString("  Total Bill       : $");
    ITM_SendInt(data->total_bill);
    ITM_SendString(" USD\r\n");
    
    // Footer
    ITM_SendString("==================================================\r\n");
    ITM_SendString("    End of Report\r\n");
    ITM_SendString("==================================================\r\n");

}
// Import error tracking from assembly
extern uint32_t error_flag;
extern uint8_t error_log_buffer[];
extern uint32_t error_count;

// Error type constants
#define ERROR_SENSOR_MALFUNCTION    0x01
#define ERROR_INVALID_DOSAGE        0x02
#define ERROR_MEMORY_OVERFLOW       0x03

void Print_Error_Log(void) {
    uint32_t count = error_count;
    
    if (count == 0) {
        ITM_SendString("\n[NO ERRORS DETECTED]\n");
        return;
    }
    
    ITM_SendString("\n\n");
    ITM_SendString("========================================\n");
    ITM_SendString("     SYSTEM ERROR LOG (Module 11)      \n");
    ITM_SendString("========================================\n");
    ITM_SendString("Total Errors: ");
    ITM_SendInt(count);
    ITM_SendString("\n\n");
    
    for (uint32_t i = 0; i < count && i < 50; i++) {
        uint8_t *record = error_log_buffer + (i * 16);
        
        uint8_t error_type = record[0];
        uint8_t patient_idx = record[1];
        uint8_t error_code = record[2];
        uint32_t timestamp = *((uint32_t*)(record + 4));
        uint32_t error_value = *((uint32_t*)(record + 8));
        
        ITM_SendString("Error #");
        ITM_SendInt(i + 1);
        ITM_SendString("\n");
        
        ITM_SendString("  Type: ");
        if (error_type == ERROR_SENSOR_MALFUNCTION) {
            ITM_SendString("SENSOR MALFUNCTION\n");
            ITM_SendString("  Sensor: ");
            if (error_code == 1) ITM_SendString("Heart Rate");
            else if (error_code == 2) ITM_SendString("Oxygen");
            else if (error_code == 3) ITM_SendString("Blood Pressure");
            ITM_SendString("\n");
            ITM_SendString("  Stuck Value: ");
            ITM_SendInt(error_value);
        } else if (error_type == ERROR_INVALID_DOSAGE) {
            ITM_SendString("INVALID DOSAGE\n");
            ITM_SendString("  Issue: ");
            if (error_code == 1) ITM_SendString("Zero Unit Price");
            else if (error_code == 2) ITM_SendString("Zero Quantity");
            ITM_SendString("\n");
            ITM_SendString("  Medicine Index: ");
            ITM_SendInt(error_value);
        } else if (error_type == ERROR_MEMORY_OVERFLOW) {
            ITM_SendString("MEMORY OVERFLOW\n");
            ITM_SendString("  Code: ");
            if (error_code == 1) ITM_SendString("Address Boundary");
            else if (error_code == 2) ITM_SendString("Billing Overflow");
            ITM_SendString("\n");
            ITM_SendString("  Value: 0x");
            ITM_SendInt(error_value);
        }
        ITM_SendString("\n");
        
        ITM_SendString("  Patient: ");
        ITM_SendInt(patient_idx);
        ITM_SendString("\n");
        
        ITM_SendString("  Timestamp: ");
        ITM_SendInt(timestamp);
        ITM_SendString(" sec\n");
        ITM_SendString("----------------------------------------\n");
    }
    
    ITM_SendString("========================================\n\n");
}
// ============================================================================
// Public report generator function to be called from assembly/startup
// Exported symbol: Generate_UART_Reports
// ============================================================================
void Generate_UART_Reports(void) {
    PatientData patient;

    UART_Init_C();

    ITM_TCR = 0x0001000D;  // Enable ITM
    ITM_TER = 0x00000001;  // Enable stimulus port 0
	
		// Print error log FIRST
    Print_Error_Log();

    for (int i = 0; i < 3; i++) {
        uint8_t *patient_ptr = patient_array + (i * PATIENT_SIZE);
        ExtractPatientData(patient_ptr, &patient);
        PrintPatientReport_C(&patient);
        if (i < 2) {
            PrintSeparator();
        }
    }
}
