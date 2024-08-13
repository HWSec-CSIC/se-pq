/*****************************************************************************/
/*
 *  IMSE.CNM_SPIRS-HwSecpuf4r3_2.0: puf_reliability.c for PUF4R3
 *
 *  Created on: 10/02/2023
 *      Author: santiago@imse-cnm.csic.es
 *
 *  Function:
 *   - Evaluates the reliability of the PUFs instantiated in a Test System. 
 *     To do this, an enrollment process is first performed for each PUF to 
 *     obtain its Reference Output. Subsequently, the Key Masks obtained by 
 *     applying an ECC with a given repetition code to the responses of the 
 *     successive series of invocations to the PUF are analyzed.
 *
 *  Outputs:
 *   - DBG = 0 --> Tests passed or failed test for each PUF and each run
 *                 + Total values for each PUF (if N_runs > 1)
 *   - DBG = 1 --> + Bitstream file of the Test System 
 *                 + Time for bitstream loading (for PYNQ-Boards)
 *                 + HDintra at the enrollment stage
 *                 + Processing times
 *   - DBG = 2 --> + Result and procesing times for each test
 *
 *  Output Files:
 *   - o       --> Generates a file in the OUTDIR directory with the outputs  
 *                 of the PUF for each PUF and each run
*/
 /*****************************************************************************/

/******************************** Include Files *******************************/

#include "puf4r3.h"
#include "testsystem.h"

/******************************* Test parameters ******************************/

int N_CMPS     = 640;      // -c Number of comparisons
int E_CMPS     = 64;       // -e Number of comparisons eliminated at enrollment
int BG         = 1;        // -g Binary/Gray counters
int NR         = 0;        // -n Nearby/Remote RO pairs
int LH         = 0;        // -l Lower/Higher Bits
int N_tests    = 100;      // -t Number of test
int E_tests    = 100;      // -m Number of test for enrollment
int N_runs     = 3;        // -r Number of runs
int DBG        = 0;        // -d Debug level
int RC         = 7;        // -p ECC Repetition code
int OUT_FILE   = 0;        // -o Generate output files
int INTER      = 0;        // -i Interactive mode (PUF to PUF)
char * BOARD   = "01";     // -b Board ID

int PE         = 1;        // PUF/Entropy Source (in IP Operation mode)
int CHD        = 1;        // Compute Hamming Distance

char * T_code   = "---";   // Test code
char * T_board;            // Board ID
                     
/******************************************************************************/
/******************************************************************************/


int main(int argc, char** argv) {

   int board;
   int puf_ref[MN_CMPS];
   int puf_eref[MN_CMPS];					 
   int puf_selm[MN_CMPS];
   int cr;

   int triesr;
   int last_reg;
   
   int N_regs;
   int N_bits;
   int K_bits;
   int diffs;
   int sum_diffs;
   int failed_t;
   int passed_t;
   int t_passed;
   unsigned long long toc, ts, tr, tt;
   
#if defined(AXI64)
   long long op;
   unsigned long long puf_output[MN_REGS/2];
   long long puf_selr[(int)ceil((MN_CMPS/64.))];
#else	
   int op;
   unsigned int puf_output[MN_REGS];
   int puf_selr[(int)ceil((MN_CMPS/32.))];
#endif

   unsigned int CONFIG;
   int  puf_outc[MN_CMPS];
   
   HammDist HDref;
  
   char * bitstream_file;
   char input_file[100];
   char output_file[100];
   char crun[3];
   //char idtrail[20];
   char odtrail[20];
   char cboard[3];
   char ctcode[4];
   
   char puf_refb[MN_BITS];
   char puf_outb[MN_BITS];
   char puf_compare[MN_BITS];
   char puf_diffs[MN_BITS/5];

   FILE *fptr;
   MMIO_WINDOW puf;
    
 #if !defined(STANDALONE)

  int arg;
   for(arg=1; arg < argc; arg++) {
      if(argv[arg][0] == '-') {
         if(argv[arg][1] == 'h') {
            printf("\nUsage: ./puf_reliability [ -h | [-i] [-o] [-g] [-n] [-l] [-b <board_id>] [-d <dbg_level>]");
            printf("\n                         [-c <n_cmpc>] [-e <n_cmpc>] [-m <n_tests>] [-t <n_tests>]");
			printf("\n                         [-p <ecc_repcode>] [-r <n_runs>] ]\n\n");
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
            if(N_tests<2) N_tests=2;
         } else if(argv[arg][1] == 'm') {
            if(arg<argc-1) E_tests = atoi(argv[arg+1]);
            if(E_tests>MN_TESTS) E_tests=MN_TESTS;
            if(E_tests<10) E_tests=10;
         } else if(argv[arg][1] == 'r') {
            if(arg<argc-1) N_runs = atoi(argv[arg+1]);
            if(N_runs<1) N_runs=1;
         } else if(argv[arg][1] == 'e') {
            if(arg<argc-1) E_CMPS = atoi(argv[arg+1]);
         } else if(argv[arg][1] == 'p') {
            if(arg<argc-1) RC = atoi(argv[arg+1]);
            if(RC==(RC/2)*2) { RC = 5;
               printf("\n\n --> RC must be odd. Set to %2d.\n\n", RC);}
         } else if(argv[arg][1] == 'o') {
            OUT_FILE=1;
         } else if(argv[arg][1] == 'i') {
            INTER=1;
         } else if(argv[arg][1] == 'g') {
            BG=0;
         } else if(argv[arg][1] == 'n') {
            NR=1;
         } else if(argv[arg][1] == 'l') {
            LH=1;
         } else {
            printf("\n unknow option: %s\n", argv[arg]);
         }
      }   
   }   

 #endif

 #if defined(AXI64)
   N_regs = ceil((N_CMPS-E_CMPS)/16.);     	// Number of registers 
 #else
   N_regs = ceil((N_CMPS-E_CMPS)/8.);     	// Number of registers 
 #endif
   N_bits = (N_CMPS-E_CMPS)*4;				// Number of bits of PUF
   K_bits = N_bits/RC;           			// Number of bits of KEY

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

         
   printf("\n  --- Start Test ---> T_board %s, T_code %s, N_runs %d, E_tests %d, N_tests %d\n",
                                   T_board, T_code, N_runs , E_tests, N_tests);
   printf("                      N_cmps %d, E_cmps %d, N_bits %d, RC %d, K_bits %d\n",
		                           N_CMPS, E_CMPS, N_bits, RC, K_bits);
      
   if (DBG > 0) {
      printf("\n   --- Bitstream_file: %s\n", bitstream_file);
   }
   if (DBG < 1) {
      printf("\n");
   }
   
 #if defined(PYNQ)
   // Load Bitstream
   PUF_loadBitstream(bitstream_file, DBG+2);
   if (DBG > 0) {
      printf("\n");
   }  
 #endif
 
   CONFIG =  (PE<<5) + (BG<<4) + (NR<<3) + (LH<<2);
   
   // For each PUF instance (s)
   int ns = sizeof(opt)/sizeof(opt[0]);
   for (int s=0; s<ns; s++) {
      
 #if defined(STANDALONE)
      puf = PUF_BASEADDR[s];
 #endif
 
      // Create PUF interface
      PUF_createMMIOWindow(&puf, PUF_BASEADDR[s], PUF_LENGTH, 0);      
 
      // Reset Challenges Mask
	  op = 0;
      writeMMIO(&puf, &op, CHLADDC, sizeof(op));	 

      for (int c=0; c<ceil(MN_CMPS/8.)*8; c++) {
     	  puf_selm[c] = 0;
      }
#if defined(AXI64)  
      for (int r=0; r<ceil(MN_CMPS/64.); r++) {
#else
      for (int r=0; r<ceil(MN_CMPS/32.); r++) {     
#endif
     	  puf_selr[r] = 0;
      }
	  
      ts = Wtime();

      // Get PUF reference output for N_CMPS
	  HDref = PUF_enrollment(&puf, 0, 1, CONFIG, E_tests, N_CMPS, E_CMPS, 
	                         puf_ref, puf_selm);
 
	  if (DBG > 0) { 
	     printf(" HD_enrl = %5.3f [%5.3f - %5.3f]", HDref.mean, HDref.min, HDref.max);
		 toc = Wtime() - ts;
         printf("\t(%.3f s)", toc/1000000.);
	  }
	  	  
	  // Get PUF reference output for N_CMPS-E_CMPS
 	  cr = 0;
      for (int c=0; c<N_CMPS; c++) {
    	 if (puf_selm[c] == 0) {
		    puf_eref[cr] = puf_ref[c];
		    cr++;
		 }
      }

      chl_btor(puf_selm, N_CMPS, puf_selr);

      //////////////////////////////////////////////////////
	  if (DBG == 5) {
         printf("\n\n         puf_ref  --- ");				  
         for (int c=0; c<(N_CMPS); c++) {
            printf("%1.1x", puf_ref[c]);    // Hex output 
         }
         printf("\n         puf_selm --- ");				  
         for (int c=0; c<(N_CMPS); c++) {
            printf("%1.1x", puf_selm[c]);    // Hex output 
         }
         printf("\n         puf_eref --- ");				  
         for (int c=0; c<(N_CMPS-E_CMPS); c++) {
            printf("%1.1x", puf_eref[c]);    // Hex output 
         }
       printf("\n");				  
      }
      //////////////////////////////////////////////////////

      // Enable/Disable Challenges Mask
      if (E_CMPS == 0) {
	     op = 0;
	  } else {
   #if defined(AXI64)
         PUF_writeChallegesMask(&puf, puf_selr, ceil(MN_CMPS/64.), DBG); 
   #else
         PUF_writeChallegesMask(&puf, puf_selr, ceil(MN_CMPS/32.), DBG); 
   #endif
         op = RCHL;										  
	  }
      writeMMIO(&puf, &op, CHLADDC, sizeof(op));	 

      chl_btor( puf_selm, N_CMPS, puf_selr);
	  
      puf_ctob(puf_eref, N_CMPS-E_CMPS, puf_refb);
	  
	  t_passed = 0;
	  
      // For each run
      for (int run=1; run<=N_runs; run++) {
		  
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
   
         printf("\n       ---  Run %4d  ---", run);

         if (DBG > 1) {
            printf( "\n");
         }
 
         K_bits = N_bits/RC;
         triesr = 0;
         sum_diffs = 0;
		 failed_t = 0;
		 passed_t = 0;
		 
         tr = Wtime();
         
         // For each Test (t)
		 int t = 0;
         for (t=1; t<=N_tests; t++) {
            
            tt = Wtime();;
                             
            if (DBG > 1) {
               printf( "            -T- %4d  ", t);
            }
               
            // Generate PUF responses
            last_reg = PUF_applyChallenges(&puf, CONFIG, N_CMPS-E_CMPS, 0);
            
            if (last_reg < ceil((float)(N_CMPS-E_CMPS)/Dbw)) {
               triesr++;
               t = t-1;
            } else {
            
               //Read PUF results
               PUF_readOutput(&puf, N_CMPS-E_CMPS, puf_output, 0);
                  
               if (OUT_FILE == 1) {
                  for (int r=0; r<ceil((float)(N_CMPS-E_CMPS)/Dbw); r++) {
         #if defined(AXI64)
                     fprintf(fptr, " %16.16llX", puf_output[r]);    // Hex output  
         #else
                     fprintf(fptr, " %8.8X", puf_output[r]);    // Hex output 
         #endif			   
                     //fprintf(fptr, " %u", puf_output[r]);        // Dec output  
                  }
                  fprintf(fptr, "\n");
               }
              
               // Get PUF comparisons      
	           puf_rtoc(puf_output, N_regs, puf_outc);
	         	         
               if (DBG >= 5) {
                  for (int c=0; c<(N_CMPS-E_CMPS); c++) {
                     printf("%1.1x", puf_outc[c]);    // Hex output 
                  }
                  printf(" ");				  
               }

               // Get PUF bits      
               puf_ctob(puf_outc, N_CMPS-E_CMPS, puf_outb);

               // Compare with the PUF reference output             
               for (int b=0; b<N_bits; b++) {
                  if (puf_outb[b] == puf_refb[b]) {
                     puf_compare[b] = 0;
                  } else {
                     puf_compare[b] = 1;
                  }
               }
			   
               // Apply Error Correction Code 
               diffs = 0;
               puf_ecc(puf_compare, N_bits, RC, puf_diffs);
               
               if (DBG > 5) {
                  printf(" --- ");
                  for (int b=0; b<K_bits; b++) {
                     printf("%1d", puf_diffs[b]);
                  }
                   printf("  ");
              }
			
               for (int b=0; b<K_bits; b++) {
                  diffs = diffs + puf_diffs[b];
               }
               sum_diffs = sum_diffs + diffs;
			   
			   if (diffs == 0) {
			      passed_t++;
               } else {
                  failed_t++;
			   }
				   		   
               if (DBG > 1) {
                  printf("---  Diff. %5d", diffs); 
                  if (diffs == 0) {
                     printf(" --> passed");
                  } else {
                     printf(" --> failed");
                  }					 
                  toc = Wtime() - tt;
                  printf("  ...  (%.2f ms)\n", toc/1000.);      // Test time
               }
            }
			
         }  // end tests
                  
         if (DBG > 4) printf("\n");
         if (DBG > 1) printf("                      ---");
		  
         if(sum_diffs == 0) {
            printf(" #tests %5d --> Passed", passed_t);
         } else {
            printf(" #tests %5d --> Failed", failed_t);
         }      
         if (DBG > 0) {         
		    toc = Wtime() - tr;                     // Run time
            printf("\t(%.3f s)", toc/1000000.);
         }
	     if ((DBG > 1) & (N_runs > 1)) {
            printf("\n");
         }		 
         if (OUT_FILE == 1) {         
            fclose(fptr);
         }

         t_passed = t_passed + passed_t;		 
         
 #if !defined(STANDALONE)
         // Close PUF interface
         int Status;
         Status = closeMMIOWindow(&puf);
         if (Status != SUCCESS) {
            printf(" closeMMIOWindow failed !!!\n\n");
            return ERROR;
         }
 #endif

      }  //end runs

	  if (N_runs > 1) {
		 printf("\n       ---  Total     --- #tests %5d -->", t_passed);
		 if(t_passed == N_tests*N_runs) {
            printf(" PASSED  ");
		 } else {
            printf(" FAILED  ");
		 }
			 
         if (DBG > 0) {
            toc = Wtime() - ts;
            printf("\t(%.3f s)", toc/1000000.);
         }
	  }		 

      if ((INTER == 1) & (s < ns-1)) {
         printf("\n\n   Press any key to continue");
         getchar();
      }
      
      printf("\n\n");	

   }  // end pufs
   
   printf("  --- End Test\n\n");	  
}
