/******************************************************************************/
/*
 *  IMSE.CNM_SPIRS-HwSec_puf4r3_2.0: puf_test.c for PUF4R3  32/64-bits
 *
 *  Created on: 10/02/2023
 *      Author: santiago@imse-cnm.csic.es
 *
 *  Function:
 *   - Processes input parameters to calculate the number of challenges that can
 *     be discarded.
 *   - Executes an enrollment processes to obtain the PUF Reference Output and the
 *     Challenges Selection Mask.
 *   - Evaluates HDintra metric after applyng the challenges selection estrategy.
 *   - Invokes the PUF repeatedly to verify its reliability as an ID generator using 
 *     the chosen configuration.
 *
 *
 *  Outputs:
 *   - DBG = 0 --> No. of times the reliability test passes or fails in each run 
 *   - DBG = 1 --> + HDintra values in the enrollment process and after applying  
 *                   the challenge selection mechanism for each run
 *   - DBG = 2 --> + Challenges Selection Mask and PUF Reference Outputs before  
 *                   and after applying the challenge selection mechanism
 *   - DBG = 3 --> + Last PUF output for each run
 *
*/
/******************************************************************************/

/******************************** Include Files *******************************/

#include "puf4r3.h"
#include "testsystem.h"

/******************************** Test parameters *****************************/

int N_CMPS     = 640;      //    Number of comparisons
int E_CMPS     = 64;       //    Number of discarded comparisons
int PE         = 1;        //    PUF/Entropy Source (in IP Operation mode)

int BG         = 1;        // -g Binary/Gray counters
int NR         = 0;        // -n Nearby/Remote RO pairs
int LH         = 0;        // -l Lower/Higher Bits
int K_bits     = 128;      // -k Number of bits of KEY
int RC         = 7;        // -p ECC Repetition code
int E_tests    = 100;      // -m Number of test for enrollment
int N_tests    = 100;      // -t Number of test for each run
int N_runs     = 3;        // -r Number of runs
int DBG        = 1;        // -d Debug level

char * T_code  = "---";    // Test code

/******************************************************************************/
/******************************************************************************/


int main(int argc, char** argv) {

   MMIO_WINDOW puf;
  
   int puf_ref[MN_CMPS];
   int puf_selm[MN_CMPS];
   int puf_eref[MN_CMPS];					 
   int cr; 

   int triesr;
   int last_reg;
   
   int N_regs;
   int N_bits;
   int diffs;
   int sum_diffs;
   int failed_t;
   int passed_t;
   int t_passed;
   unsigned long long toc, tr, ts;
 
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
   
   HammDist HDintra;
     
 #if defined(PYNQ)
   char * bitstream_file;
   char input_file[100];
 #endif   
 
   char ctcode[4];   
   char puf_refb[MN_BITS];
   char puf_outb[MN_BITS];
   char puf_compare[MN_BITS];
   char puf_diffs[MN_BITS/5];

 #if !defined(STANDALONE)

   int arg;
   for(arg=1; arg < argc; arg++) {
      if(argv[arg][0] == '-') {
         if(argv[arg][1] == 'h') {
            printf("\nUsage: ./puf_test [ -h | [-g] [-n] [-l] [-d <dbg_level>]");
            printf("\n                  [-c <n_cmpc>] [-k <n_bits>] [-p <ecc_repcode>]");
 			printf("\n                  [-m <n_tests>] [-t <n_tests>] [-r <n_runs>] ]\n\n");
           return 0;   
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
         } else if(argv[arg][1] == 'k') {
            if(arg<argc-1)K_bits = atoi(argv[arg+1]);
         } else if(argv[arg][1] == 'p') {
            if(arg<argc-1) RC = atoi(argv[arg+1]);
            if(RC==(RC/2)*2) { RC = 5;
               printf("\n\n --> RC must be odd. Set to %2d.\n\n", RC);}
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

   if (PE == 0) {
      T_code = "ES";
   } else {
      sprintf(ctcode, "%01d%01d%01d", BG, NR, LH);
      T_code = ctcode;
   }
        
 #if defined(PYNQ)
   strcpy(input_file, InF);
   bitstream_file = strcat(input_file, ".bit");
 #endif
  
   // Calculate No. of challenges that can be discarded (E_CMPS)
   
   N_bits = ceil(RC * K_bits/4.)*4;         // Number of bits 
   if (N_bits/4 > N_CMPS) {
	  printf("\n  %d comparisons are not enough to obfuscate a %d-bit key with a repetition code of length %d.  Bye ...\n\n", N_CMPS, K_bits, RC);
	  return ERROR;
   } else {
      E_CMPS = N_CMPS - N_bits/4;           // Number of discarded comparisons
   }
   
 #if defined(AXI64)
   N_regs = ceil((N_CMPS-E_CMPS)/16.);     	// Number of registers 
 #else
   N_regs = ceil((N_CMPS-E_CMPS)/8.);     	// Number of registers 
 #endif

   // Start Test

   printf("\n  --- Start Test ---> T_code %s, K_bits %d, RC %d, N_cmps %d, E_cmps %d\n",
                                   T_code, K_bits, RC, N_CMPS, E_CMPS);							   
   printf(" 		      E_tests %d, N_tests %d, N_runs %d\n",
                          E_tests, N_tests,  N_runs);
 
 #if defined(PYNQ)
   if (DBG > 0) {
      printf("\n   ---  Load Bitstream file: %s\n", bitstream_file);
   }
   if (DBG < 1) {
      printf("\n");
   }
   // Load Bitstream
   PUF_loadBitstream(bitstream_file, DBG+2);
 #endif
 
   if (DBG > 0) {
      printf("\n");
   }
 
   CONFIG =  (PE<<5) + (BG<<4) + (NR<<3) + (LH<<2);
  
   // For each PUF instance (s)
   int ns = sizeof(opt)/sizeof(opt[0]);
   for (int s=0; s<ns; s++) {

      // Create PUF interface
      PUF_createMMIOWindow(&puf, PUF_BASEADDR[s], PUF_LENGTH, 0); 	   
	   
      // Reset Challenges Mask
	  op = 0;
      writeMMIO(&puf, &op, CHLADDC, sizeof(op));	 

	  ts = Wtime();
      for (int c=0; c<ceil(N_CMPS/(Dbw/4.))*16; c++) {
     	  puf_selm[c] = 0;
      }
	  
      // Perform the enrollment process 	    
      tr = Wtime(); 
      HDintra = PUF_enrollment(&puf, 0, 1, CONFIG, N_tests, N_CMPS, E_CMPS, 
   	                            puf_ref, puf_selm);                        	
      toc = Wtime() - tr;
	  	  
	  if (DBG > 0) {
         printf("\n\n      - PUF Enrollment  ---  HDintra: %6.3f [%5.3f - %5.3f]", HDintra.mean, HDintra.min, HDintra.max);
	     printf("  (%.3f s)\n", toc/1000000.);
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

      if (DBG > 1) {
	      printf("\n        ---  puf_ref:  ");    
          for (int c=0; c<N_CMPS; c++) {
          //for (int c=0; c<ceil(N_CMPS/(Dbw/4.))*16; c++) {
              printf("%1X", puf_ref[c]);
          }
	      printf("\n");    
	  }	
      if (DBG > 1) {	   
   	      printf("\n        ---  puf_selm: ");    
          for (int c=0; c<N_CMPS; c++) {
          //for (int c=0; c<ceil(N_CMPS/(Dbw/4.))*16; c++) {
              printf("%1X", puf_selm[c]);
	      }
	      printf("\n");    
   	  }
      if (DBG > 1) {
	      printf("\n        ---  puf_eref: ");    
          for (int c=0; c<(N_CMPS-E_CMPS); c++) {
              printf("%1X", puf_eref[c]);
          }
	      printf("\n");    
	  }	
		  
     // Write Challenges Selection Mask
	  if (DBG >0) {
           printf("\n      - Writing Challenges Selection Mask");
      }
  #if defined(AXI64)
      PUF_writeChallegesMask(&puf, puf_selr, ceil(MN_CMPS/64.), 0); 
  #else
      PUF_writeChallegesMask(&puf, puf_selr, ceil(MN_CMPS/32.), 0); 
  #endif
      op = RCHL;										  
      writeMMIO(&puf, &op, CHLADDC, sizeof(op));	 

      //chl_btor( puf_selm, N_CMPS, puf_selr);
	  
      puf_ctob(puf_eref, N_CMPS-E_CMPS, puf_refb);
	  
	  t_passed = 0;	  
		  

      // Calculate HDintra
	  if (DBG > 0) {
           printf("\n\n      - HDintra evaluation \n");
      }

      for (int run=1; run<=N_runs; run++) {

         if (DBG > 0) {
		  
            printf("\n        ---  Run %4d   --- ", run);
	        HDintra = PUF_HD(&puf, 1, CONFIG, puf_eref, puf_selm, N_tests, N_CMPS, E_CMPS);

	        printf(" HDintra = %5.3f [%5.3f - %5.3f]", HDintra.mean, HDintra.min, HDintra.max);
  
            toc = Wtime() - tr;
            printf(" (%.3f s)", toc/1000000.);
         }
	  
      }  //end runs
 
      // Evaluate Key recoverability
	  if (DBG > 0) {
           printf("\n\n      - Key recovery\n");
      }
     // For each run
      for (int run=1; run<=N_runs; run++) {
  	  
         printf("\n        ---  Run %4d   --- ", run);

         triesr = 0;
         sum_diffs = 0;
		 failed_t = 0;
		 passed_t = 0;
		 
         tr = Wtime();
         
         // For each Test (t)
		 int t = 0;
         for (t=1; t<=N_tests; t++) {
            
            // Generate PUF response
            last_reg = PUF_applyChallenges(&puf, CONFIG, N_CMPS-E_CMPS, 0);
            
            if (last_reg < ceil((float)(N_CMPS-E_CMPS)/Dbw)) {
               triesr++;
               t = t-1;
            } else {
            
               //Read PUF results
               PUF_readOutput(&puf, N_CMPS-E_CMPS, puf_output, 0);
                               
               // Get PUF comparisons      
	           puf_rtoc(puf_output, N_regs, puf_outc);
	         	         
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
               			
               for (int b=0; b<K_bits; b++) {
                  diffs = diffs + puf_diffs[b];
               }
               sum_diffs = sum_diffs + diffs;
			   
			   if (diffs == 0) {
			      passed_t++;
               } else {
                  failed_t++;
			   }
			   			   
            }
			
         }  // end tests
		 
         if(sum_diffs == 0) {
            printf(" #tests %6d  -->  Passed", passed_t);
         } else {
            printf(" #tests %6d  -->  Failed", failed_t);
         }      
         if (DBG > 0) {         
		    toc = Wtime() - tr;                     // Run time
            printf("\t(%.3f s)", toc/1000000.);
         }
		 
         //if ((DBG > 2) & (failed_t == 0) ) {
         if ((DBG > 2)) {
	        printf("\n\n        ---  puf_outc: ");    
            for (int c=0; c<(N_CMPS-E_CMPS); c++) {
                printf("%1X", puf_outc[c]);
            }
	        printf("\n");    
	     }	
	 
         t_passed = t_passed + passed_t;		 
         
      }  //end runs

	  if (N_runs > 1) {
		 printf("\n        ---  Total      ---  #tests  %5d  --> ", t_passed);
		 if(t_passed == N_tests*N_runs) {
            printf(" PASSED  ");
		 } else {
            printf(" FAILED  ");
		 }			 
	  }		 

      printf("\n\n");	
	  
  #if !defined(STANDALONE)
         //Close PUF interface
         int Status;
         Status = closeMMIOWindow(&puf);
         if (Status != SUCCESS) {
            printf(" Failed !!!\n");
            return 1;
         }
  #endif
	  
   }  // end pufs
     
   printf("  --- End Test");
   toc = Wtime() - ts;
   printf("  (%.3f s)\n\n", toc/1000000.);
   
}
  


