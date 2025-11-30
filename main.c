#include <stdint.h>

// ITM register addresses
#define ITM_PORT0   (*((volatile uint32_t *)0xE0000000))
#define ITM_TER     (*((volatile uint32_t *)0xE0000E00))
#define ITM_TCR     (*((volatile uint32_t *)0xE0000E80))

// Function to send a single character via ITM
void ITM_SendChar(char ch) {
    while ((ITM_PORT0 & 1) == 0);
    ITM_PORT0 = ch;
}

// Function to send a string via ITM
void ITM_SendString(const char *str) {
    while (*str) {
        ITM_SendChar(*str++);
    }
}

// Function to print the patient report
void PrintPatientReport(void) {
    ITM_SendString("============================================\r\n");
    ITM_SendString("    PATIENT SUMMARY REPORT\r\n");
    ITM_SendString("    Healthcare Monitoring System\r\n");
    ITM_SendString("============================================\r\n");
    ITM_SendString("\r\n");
    
    ITM_SendString("PATIENT INFORMATION:\r\n");
    ITM_SendString("--------------------------------------------\r\n");
    ITM_SendString("  Patient ID       : 10245\r\n");
    ITM_SendString("  Age              : 68 years\r\n");
    ITM_SendString("  Ward Number      : 7\r\n");
    ITM_SendString("\r\n");
    
    ITM_SendString("LATEST VITAL SIGNS:\r\n");
    ITM_SendString("--------------------------------------------\r\n");
    ITM_SendString("  Heart Rate       : 78 bpm\r\n");
    ITM_SendString("  Blood Pressure   : 130/85 mmHg\r\n");
    ITM_SendString("  Temperature      : 38 C\r\n");
    ITM_SendString("  SpO2 (Oxygen)    : 95 %\r\n");
    ITM_SendString("\r\n");
    
    ITM_SendString("ALERT SUMMARY:\r\n");
    ITM_SendString("--------------------------------------------\r\n");
    ITM_SendString("  Total Alerts     : 2 (Attention Required)\r\n");
    ITM_SendString("\r\n");
    
    ITM_SendString("BILLING SUMMARY:\r\n");
    ITM_SendString("--------------------------------------------\r\n");
    ITM_SendString("  Total Bill       : $2450 USD\r\n");
    ITM_SendString("\r\n");
    
    ITM_SendString("============================================\r\n");
    ITM_SendString("    End of Report\r\n");
    ITM_SendString("    Report Generated Successfully\r\n");
    ITM_SendString("============================================\r\n");
}

int main(void) {
    // Enable ITM trace
    ITM_TCR = 0x0001000D;  // Enable ITM
    ITM_TER = 0x00000001;  // Enable stimulus port 0
    
    // Print the patient report
    PrintPatientReport();
    
    // Infinite loop
    while(1) {
        // Application continues running
    }
    
    return 0;
}