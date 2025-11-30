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
#define PATIENT_AGE_OFF     0x04
#define WARD_OFF            0x08
#define HR_OFF              0x0C
#define SBP_OFF             0x10
#define DBP_OFF             0x14
#define O2_OFF              0x18
#define TEMP_OFF            0x1C
#define ALERT_COUNT_OFF     0x15
#define TOTAL_BILL_OFF      0x190    // Adjust based on your actual structure

// Import patient array from assembly modules
extern uint8_t patient_array[];

// ============================================================================
// MODULE 10 - Step 1: Initialize UART
// ============================================================================
void UART_Init_C(void) {
    // Disable UART during configuration
    UART_CR = 0;
    
    // Set baud rate to 9600 (assuming 16 MHz clock)
    // Baud Rate Divisor = Clock / (16 * Baud Rate)
    // BRD = 16000000 / (16 * 9600) = 104.166
    UART_IBRD = 104;    // Integer part
    UART_FBRD = 11;     // Fractional part (0.166 * 64 ˜ 11)
    
    // Configure Line Control: 8 data bits, no parity, 1 stop bit, FIFO enabled
    UART_LCRH = 0x70;   // WLEN=11 (8 bits), FEN=1
    
    // Enable UART, transmit, and receive
    UART_CR = 0x301;    // UARTEN=1, TXE=1, RXE=1
}

// ============================================================================
// MODULE 10 - Step 3: Transmit Byte-by-Byte Using UART DR Register
// ============================================================================
void UART_SendChar(char ch) {
    // Wait until TX FIFO is not full
    while (UART_FR & 0x20);  // Check TXFF bit (bit 5)
    
    // Write byte to UART Data Register (byte-by-byte transmission)
    UART_DR = (uint8_t)ch;
}

// ============================================================================
// MODULE 10: Send Character via ITM (for Keil simulator)
// ============================================================================
void ITM_SendChar(char ch) {
    while ((ITM_PORT0 & 1) == 0);
    ITM_PORT0 = ch;
}

// ============================================================================
// MODULE 10: Send String (transmits byte-by-byte)
// ============================================================================
void ITM_SendString(const char *str) {
    while (*str) {
        ITM_SendChar(*str);       // For ITM/simulator
        UART_SendChar(*str);      // For actual UART hardware
        str++;
    }
}

// ============================================================================
// MODULE 10 - Step 2: Convert Integers to ASCII
// ============================================================================
void ITM_SendInt(uint32_t num) {
    char buffer[12];
    int i = 0;
    
    // Handle zero case
    if (num == 0) {
        ITM_SendChar('0');
        UART_SendChar('0');
        return;
    }
    
    // Convert integer to ASCII (digits extracted in reverse)
    while (num > 0) {
        buffer[i++] = '0' + (num % 10);  // Convert digit to ASCII
        num /= 10;
    }
    
    // Send in correct order (reverse the buffer)
    while (i > 0) {
        i--;
        ITM_SendChar(buffer[i]);
        UART_SendChar(buffer[i]);
    }
}

// ============================================================================
// MODULE 10: Print Separator Between Reports
// ============================================================================
void PrintSeparator(void) {
    ITM_SendString("\r\n\r\n");
    ITM_SendString("################################################\r\n");
    ITM_SendString("################################################\r\n");
    ITM_SendString("\r\n\r\n");
}

// ============================================================================
// MODULE 10: Patient Data Structure
// ============================================================================
typedef struct {
    uint32_t id;
    uint32_t age;
    uint32_t ward;
    uint32_t hr;
    uint32_t sbp;
    uint32_t dbp;
    uint32_t o2;
    uint32_t temp;
    uint32_t alert_count;
    uint32_t total_bill;
} PatientData;

// ============================================================================
// MODULE 10: Extract Patient Data from Assembly Structure
// ============================================================================
void ExtractPatientData(uint8_t *patient_ptr, PatientData *data) {
    data->id = *((uint32_t *)(patient_ptr + PATIENT_ID_OFF));
    data->age = *((uint32_t *)(patient_ptr + PATIENT_AGE_OFF));
    data->ward = *((uint32_t *)(patient_ptr + WARD_OFF));
    data->hr = *((uint32_t *)(patient_ptr + HR_OFF));
    data->sbp = *((uint32_t *)(patient_ptr + SBP_OFF));
    data->dbp = *((uint32_t *)(patient_ptr + DBP_OFF));
    data->o2 = *((uint32_t *)(patient_ptr + O2_OFF));
    data->temp = *((uint32_t *)(patient_ptr + TEMP_OFF));
    data->alert_count = *((uint8_t *)(patient_ptr + ALERT_COUNT_OFF));
    data->total_bill = *((uint32_t *)(patient_ptr + TOTAL_BILL_OFF));
}

// ============================================================================
// MODULE 10: Generate Formatted Summary (All Required Fields)
// ============================================================================
void PrintPatientReport_C(PatientData *data) {
    // Header
    ITM_SendString("============================================\r\n");
    ITM_SendString("    PATIENT SUMMARY REPORT\r\n");
    ITM_SendString("    Healthcare Monitoring System\r\n");
    ITM_SendString("============================================\r\n");
    ITM_SendString("\r\n");
    
    // Patient Information (Required Field: Patient ID, Age, Ward)
    ITM_SendString("PATIENT INFORMATION:\r\n");
    ITM_SendString("--------------------------------------------\r\n");
    
    ITM_SendString("  Patient ID       : ");
    ITM_SendInt(data->id);
    ITM_SendString("\r\n");
    
    ITM_SendString("  Age              : ");
    ITM_SendInt(data->age);
    ITM_SendString(" years\r\n");
    
    ITM_SendString("  Ward Number      : ");
    ITM_SendInt(data->ward);
    ITM_SendString("\r\n\r\n");
    
    // Latest Vitals (Required Field: Latest vitals)
    ITM_SendString("LATEST VITAL SIGNS:\r\n");
    ITM_SendString("--------------------------------------------\r\n");
    
    ITM_SendString("  Heart Rate       : ");
    ITM_SendInt(data->hr);
    ITM_SendString(" bpm\r\n");
    
    ITM_SendString("  Blood Pressure   : ");
    ITM_SendInt(data->sbp);
    ITM_SendString("/");
    ITM_SendInt(data->dbp);
    ITM_SendString(" mmHg\r\n");
    
    ITM_SendString("  Temperature      : ");
    ITM_SendInt(data->temp);
    ITM_SendString(" C\r\n");
    
    ITM_SendString("  SpO2 (Oxygen)    : ");
    ITM_SendInt(data->o2);
    ITM_SendString(" %\r\n\r\n");
    
    // Total Alerts (Required Field: Total alerts)
    ITM_SendString("ALERT SUMMARY:\r\n");
    ITM_SendString("--------------------------------------------\r\n");
    ITM_SendString("  Total Alerts     : ");
    ITM_SendInt(data->alert_count);
    
    // Alert status based on count
    if (data->alert_count == 0) {
        ITM_SendString(" (Patient Stable)");
    } else if (data->alert_count < 3) {
        ITM_SendString(" (Attention Required)");
    } else {
        ITM_SendString(" (CRITICAL - Immediate Action)");
    }
    ITM_SendString("\r\n\r\n");
    
    // Billing Summary (Required Field: Billing summary)
    ITM_SendString("BILLING SUMMARY:\r\n");
    ITM_SendString("--------------------------------------------\r\n");
    ITM_SendString("  Total Bill       : $");
    ITM_SendInt(data->total_bill);
    ITM_SendString(" USD\r\n\r\n");
    
    // Footer
    ITM_SendString("============================================\r\n");
    ITM_SendString("    End of Report\r\n");
    ITM_SendString("============================================\r\n");
}

// ============================================================================
// MODULE 10: Main Report Generation Function
// Called from module10.s assembly bridge
// ============================================================================
void Generate_UART_Reports(void) {
    PatientData patient;
    
    // Step 1: Initialize UART
    UART_Init_C();
    
    // Enable ITM trace for simulator
    ITM_TCR = 0x0001000D;  // Enable ITM
    ITM_TER = 0x00000001;  // Enable stimulus port 0
    
    // Generate formatted summary for all 3 patients
    for (int i = 0; i < 3; i++) {
        // Get pointer to patient data in assembly array
        uint8_t *patient_ptr = patient_array + (i * PATIENT_SIZE);
        
        // Extract patient data from assembly structure
        ExtractPatientData(patient_ptr, &patient);
        
        // Generate and transmit formatted report (Step 3: byte-by-byte)
        PrintPatientReport_C(&patient);
        
        // Add separator between reports (except after last patient)
        if (i < 2) {
            PrintSeparator();
        }
    }
}
