/******************************************************************************/
/*
 *  IMSE.CNM_SPIRS-HwSec_puf4r3_2.0: puf_getdata.c for PUF4R3  32/64-bits
 *
 *  Created on: 10/02/2023
 *      Author: santiago@imse-cnm.csic.es
 *
 *  Function:
 *   - Runs successive series of tests for each of the PUFs instantiated in 
 *     a Test System in order to verify their correct operation and capture 
 *     data for off-line evaluation of their characteristics.
 *      
 *  Outputs:
 *   - DBG = 0 --> Identifier and processing time for each run and each PUF
 *   - DBG = 1 --> + Number of registers with PUF output for each test
 *   - DBG = 2 --> + Content of the PUF output registers for each test
 *   - DBG = 3 --> + Bitstream file of the Test System
 *                 + Time for bitstream loading (for PYNQ-Boards)
 *                 + Time invested in each stage of operation of the PUF
 *   - DBG = 4 --> + Wait cycles until getting the response from the PUF
 *
 *  Output Files:
 *   - o       --> Generates a file in the OUTDIR directory with the outputs  
 *                 of the PUF for each PUF and each run
*/
/******************************************************************************/

/******************************** Include Files *******************************/

#include "puf4r3.h"
#include "testsystem.h"

/******************************** Test parameters *****************************/

int N_CMPS     = 640;      // -c Number of comparisons
int PE         = 1;        // -e PUF/Entropy Source (in Operation mode)
int BG         = 1;        // -g Binary/Gray counters
int NR         = 0;        // -n Nearby/Remote RO pairs
int LH         = 0;        // -l Lower/Higher Bits
int N_tests    = 10;       // -t Number of test
int N_runs     = 1;        // -r Number of runs
int DBG        = 0;        // -d Debug level
int AM         = 0;        // -a Applay Challenges Mask)
int INTER      = 0;        // -i Interactive mode (PUF to PUF)
int OUT_FILE   = 0;        // -o Generate output files
char * BOARD   = "01";     // -b Board ID

char * T_code   = "---";   // Test code
char * T_board;            // Board ID
 
/******************************************************************************/
/******************************************************************************/


int main(int argc, char** argv) {

   int Status;
   int board;
   int triesr;
   int last_reg;
   
#if defined(AXI64)
   unsigned long long puf_output[MN_REGS/2];
#else
   unsigned int puf_output[MN_REGS];
#endif	

   unsigned int CONFIG;
   unsigned long long toc, ts, tr, tt;
   
   char * bitstream_file;
   char input_file[100];
   char output_file[100];
   char crun[3];
   //char idtrail[20];
   char odtrail[20];
   char cboard[3];
   char ctcode[4];
   
   FILE *fptr;
   MMIO_WINDOW puf;
  
 #if !defined(STANDALONE)

   int arg;
   for(arg=1; arg < argc; arg++) {
      if(argv[arg][0] == '-') {
         if(argv[arg][1] == 'h') {
            printf("\nUsage: ./puf_getdata [ -h | [-i] [-o] [-e] [-g] [-n] [-l] [-b <board_id>] [-c <n_cmpc>]");
			printf("\n                     [-d <dbg_level>] [-r <n_runs>] [-t <n_tests>] ]\n\n");
            return SUCCESS;  
         } else if(argv[arg][1] == 'b') { 
            if(arg<argc-1) {
               board = atoi(argv[arg+1]);
               sprintf(cboard, "%02d", board);
               BOARD = cboard;          
            }
         } else if(argv[arg][1] == 'd') { 
            if(arg<argc-1) DBG = atoi(argv[arg+1]);
         } else if(argv[arg][1] == 'c') {
            if(arg<argc-1) N_CMPS = atoi(argv[arg+1]);
            if(N_CMPS>4*Nx*Ny) N_CMPS=4*Nx*Ny;
            if(N_CMPS<8) N_CMPS=8;
         } else if(argv[arg][1] == 't') {
            if(arg<argc-1) N_tests = atoi(argv[arg+1]);
            if(N_tests<1) N_tests=1;
         } else if(argv[arg][1] == 'r') {
            if(arg<argc-1) N_runs = atoi(argv[arg+1]);
            if(N_runs<1) N_runs=1;
         } else if(argv[arg][1] == 'o') {
            OUT_FILE=1;
         } else if(argv[arg][1] == 'e') {
            PE=0;
         } else if(argv[arg][1] == 'i') {
            INTER=1;
         } else if(argv[arg][1] == 'g') {
            BG=0;
         } else if(argv[arg][1] == 'n') {
            NR=1;
         } else if(argv[arg][1] == 'l') {
            LH=1;
         } else {
            printf("\nunknow option: %s\n", argv[arg]);
         }
      }
   }
   
 #endif

   if (PE == 0) {
      T_code = "ES";
   } else {
      sprintf(ctcode, "%01d%01d%01d", BG, NR, LH);
      T_code = ctcode;
   }
   
   T_board = BOARD;
   if (strcmp(T_board, "00") == 0) {
      printf("\nBoard ID: ");
      scanf("%d", &board);
      sprintf(cboard, "%02d", board);
      T_board = cboard;
   }
       
   //sprintf(idtrail, "_%d_%d_%d", Nx*Ny, Ns, Nbc);
   sprintf(odtrail, "_%d_%d_%d", Nx*Ny, Ns, Nbc);
   strcpy(input_file, InF);
   //strcat(input_file, idtrail);
   bitstream_file = strcat(input_file, ".bit");
       
   printf("\n  --- Start Test ---> T_board %s, T_code %s, N_runs %d, N_tests %d, N_cmps %d\n",
          T_board, T_code, N_runs, N_tests, N_CMPS);
   
   if (DBG > 2) {
      printf("\n   --- Bitstream_file: %s\n", bitstream_file);
   }

   ts = Wtime();
   
 #if defined(PYNQ)
   // Load Bitstream
   PUF_loadBitstream(bitstream_file, DBG);
 #endif

   CONFIG =  (PE<<5) + (BG<<4) + (NR<<3) + (LH<<2);
   
   // For each PUF instance (s)
   int ns = sizeof(opt)/sizeof(opt[0]);
   for (int s=0; s<ns; s++) {
     
      // For each Test Run (run)  ---  (uncomment the selected option)
      
      for (int run=1; run<=N_runs; run++) {    // Generate r runs
      //for (int run=N_runs; run<=N_runs; run++) {  // Generate only run r
    
         if (OUT_FILE == 1) {      
            sprintf(crun, "%02d", run);
            strcpy(output_file, OutF);  
            strcat(output_file, opt[s]);
            strcat(output_file, odtrail);
            strcat(output_file, "_");     
            strcat(output_file, T_board);
            strcat(output_file, "_");     
            strcat(output_file, T_code);
            strcat(output_file, "_");     
            strcat(output_file, crun);     
            strcat(output_file, ".txt");      
            fptr = fopen(output_file,"w");  
         }
	  
         printf("\n   -- Run %3d --- %s ", run, opt[s]);

 #if defined(STANDALONE)
         puf = PUF_BASEADDR[s];
 #endif
         // Create PUF interface
         PUF_createMMIOWindow(&puf, PUF_BASEADDR[s], PUF_LENGTH, DBG);  

          // Reset Challenges Mask
		 unsigned int op;
		 op = 0;
         writeMMIO(&puf, &op, CHLADDC, sizeof(op));	 

         triesr = 0;
         tr = Wtime();  
	  
         // For each Test (t)
         for (int t=1; t<=N_tests; t++) {
           
            tt = Wtime();;
                        
            if ((DBG > 0) & (DBG < 4)) {
               printf( "\n      -- Test: %3d  ", t);
            }
            
            // Reset, configure and generate PUF responses
            last_reg = PUF_applyChallenges(&puf, CONFIG, N_CMPS, DBG);
            
            if (last_reg < ceil(N_CMPS/(Dbw/4.))) {
               triesr++;
               t = t-1;
            }
            
            //Read PUF results
            Status = PUF_readOutput(&puf, N_CMPS, puf_output, DBG);
            if (Status == ERROR) {
               printf("failed!\n");
            }
            
            if ((OUT_FILE == 1) | (DBG == 2)) {
               for (int r=0; r<ceil(N_CMPS/(Dbw/4.)); r++) {
                  if (OUT_FILE == 1) {

 #if defined(STANDALONE)
                  printf(" %8.8x", puf_output[r]);    // Hex output
 #else
	    #if defined(AXI64)
                  fprintf(fptr, " %16.16llX", puf_output[r]);    // Hex output
        #else
                  fprintf(fptr, " %8.8X", puf_output[r]);    // Hex output
        #endif
                  //fprintf(fptr, " %u", puf_output[r]);       // Dec output  
 #endif
                  }
               }
            }
            if (OUT_FILE == 1) {
 #if defined(STANDALONE)
                printf("\n");
 #else
                fprintf(fptr, "\n");
 #endif
            }
            
            if (DBG == 2) {
               printf("\n");
            }
            
            if (DBG == 1) {
               toc = Wtime() - tt;
               printf("  -- (%.2f ms)", toc/1000.);    // Test time
            }        
            
         }  //  end tests
          
         if (DBG > 0) {
            printf("\n");
            printf("\n   -- Registers: %3d,  Tries failed: %3d,  ", last_reg, triesr);                                      
         }
         
         toc = Wtime() - tr;              // Run time
         printf("  (%.3f s)", toc/1000000.);
         if (DBG > 0) {
            printf("\n");
         }
         if (OUT_FILE == 1) {      
            fclose(fptr);
         }

 #if !defined(STANDALONE)
         // Close PUF interface
         Status = closeMMIOWindow(&puf);
         if (Status != SUCCESS) {
            printf(" closeMMIOWindow failed !!!\n\n");
            return ERROR;
        }
 
#endif

      }  //  end runs
	  
      if (DBG > 0) {
         toc = Wtime() - ts;
         printf("\n  --- End Test ---   (%.3f s)\n", toc/1000000.);
      }
	  
      if ((INTER == 1) & (s < ns-1)) {
         printf("\n\n   Press any key to continue");
         getchar();
      }
	  
   }  // end pufs
   
   printf("\n\n  --- End Test\n\n");

}

