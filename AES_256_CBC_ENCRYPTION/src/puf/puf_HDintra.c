/******************************************************************************/
/*
 *  IMSE.CNM_SPIRS-HwSec_puf4r3_2.0: puf_HDintra.c for PUF4R3  32/64-bits
 *
 *  Created on: 10/02/2023
 *      Author: santiago@imse-cnm.csic.es
 *
 *  Function:
 *   - Evaluates, for each of the PUFs instantiated in a Test System, the  
 *     Hamming Distance with respect to its Reference Output (HDintra) for 
 *     successive runs. To do this, first an enrollment process is performed 
 *     for each PUF to obtain the reference output and the RO Selection Mask   
 *     that indicates the discarded comparisons.
 *      
 *  Outputs:
 *   - DBG = 0 --> HDintra for each PUF after applying the selection mask
 *                 + HDintra without eliminating worst comparisons & Reduction 
 *					 percentage (-a option)
 *                 + Average values for each PUF (if N_runs > 1)
 *   - DBG = 1 --> + HDintra for enrollment stage 
 *                 + Processing times
 *   - DBG = 2 --> + Bitstream file of the Test System
 *                 + Time for bitstream loading (for PYNQ-Boards)
 *   Control:
 *     -i --> Wait for a key to be pressed between PUF and PUF (Interactive mode)
 *     -w --> Wait the specified time between successive runs
 *     -k --> Wait for a key to be pressed between successive runs
*/
/******************************************************************************/

/******************************** Include Files *******************************/

#include "puf4r3.h"
#include "testsystem.h"

/******************************** Test parameters *****************************/

int N_CMPS     = 640;      // -c Number of comparisons
int E_CMPS     = 64;       // -e Number of comparisons eliminated at enrollment
int BG         = 1;        // -g Binary/Gray counters
int NR         = 0;        // -n Nearby/Remote RO pairs
int LH         = 0;        // -l Lower/Higher Bits
int N_tests    = 100;      // -t Number of test
int E_tests    = 100;      // -m Number of test for enrollment
int N_runs     = 3;        // -r Number of runs
int DBG        = 0;        // -d Debug level
int ARWCM      = 0;        // -a Add results without Challenges Mask
int INTER      = 0;        // -i Interactive mode (PUF to PUF)
int W_TIME     = 0;        // -w Wait Time between runs
int W_CHAR     = 0;		   // -k Wait Key between runs
char * BOARD   = "01";     // -b Board ID

int PE         = 1;        // PUF/Entropy Source
int CHD        = 1;        // Compute Hamming Distance

char * T_code   = "---";   // Test code
char * T_board;            // Board ID

/******************************************************************************/
/******************************************************************************/


int main(int argc, char** argv) {

   MMIO_WINDOW puf;
   
#if defined(AXI64)  
   long long puf_selr[(int)ceil((MN_CMPS/64.))];
#else   
   int puf_selr[(int)ceil((MN_CMPS/32.))];
#endif

   int board;
   int puf_ref[MN_CMPS];
   int puf_eref[MN_CMPS];
   int puf_selm[MN_CMPS];
   int cr;
   
   unsigned int op;
   unsigned int CONFIG;
   unsigned long long toc, tr, ts;
   
   HammDist HDintra1;
   HammDist HDintra2;
   HammDist HDref;
   
   double HDimean1, HDimean2;
   double HDimax1,  HDimax2;
   double HDimin1,  HDimin2;
      
   char * bitstream_file;
   char input_file[100];
   //char idtrail[20];
   char cboard[3];
   char ctcode[4];
      
 #if !defined(STANDALONE)

   int arg;
   for(arg=1; arg < argc; arg++) {
      if(argv[arg][0] == '-') {
         if(argv[arg][1] == 'h') {
            printf("\nUsage: ./puf_HDintra [ -h | [-g] [-n] [-l] [-a] [-i] [-k] [-b <board_id>] [-d <dbg_level>] [-c <n_cmpc>] ");
            printf("\n                     [-e <n_cmps>] [-m <n_tests>] [-t <n_tests>] [-r <n_runs>] [-w <w_time>] ]\n\n");
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
         } else if(argv[arg][1] == 'w') {
            if(arg<argc-1) W_TIME = atoi(argv[arg+1]);
         } else if(argv[arg][1] == 'a') {
            ARWCM=1;
         } else if(argv[arg][1] == 'k') {
            W_CHAR=1;
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
   strcpy(input_file, InF);
   //strcat(input_file, idtrail);
   bitstream_file = strcat(input_file, ".bit");
       
   printf("\n  --- Start Test ---> T_board %s, T_code %s, N_runs %d, E_tests %d, N_tests %d, N_cmps %d, E_cmps %d \n",
          T_board, T_code, N_runs, E_tests, N_tests, N_CMPS, E_CMPS);
   
   if (DBG > 1) {
      printf("\n   --- Bitstream_file: %s\n", bitstream_file);
   }
   if (DBG < 2) {
      printf("\n");
   }
   
 #if defined(PYNQ)
   // Load Bitstream
   PUF_loadBitstream(bitstream_file, DBG+1);
   if (DBG > 1) {
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
	  HDref = PUF_enrollment(&puf, 1, CHD, CONFIG, E_tests, N_CMPS, E_CMPS,
	                         puf_ref, puf_selm);
							 
	  if (DBG > 0)  { 
  	     printf("\n      -- Enrollment: ");    
	     printf("-- HD_enrl = %5.3f [%5.3f - %5.3f]", HDref.mean, HDref.min, HDref.max);
		 toc = Wtime() - ts;
 	     if (ARWCM == 1) {       
            printf("                                     --       ");
         }			
         printf(" (%.3f s)", toc/1000000.);
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
 	     printf("\n       ---  puf_ref:  ");
         for (int c=0; c<N_CMPS; c++) {
		     printf("%1.1X", puf_ref[c]);
	     }	  
 	     printf("\n       ---  puf_selm: ");
         for (int b=0; b<N_CMPS; b++) {
		     printf("%1.1X", puf_selm[b]);
	     }	  
 	     printf("\n       ---  puf_eref: ");
         for (int c=0; c<cr; c++) {
		    printf("%1.1X", puf_eref[c]);
	     }	  
 	     printf("\n       ---  puf_selr: ");
	     for (int r=0; r<(float)N_CMPS/Dbw; r++) {
      #if defined(AXI64)
		    printf("%16.16llX ", puf_selr[r]);
      #else
		    printf("%8.8X ", puf_selr[r]);
      #endif
         }	
      }	  
      //////////////////////////////////////////////////////
  
	  HDimean1 = 0;   HDimean2 = 0;
	  HDimax1  = 0;   HDimax2  = 0;
	  HDimin1  = 100; HDimin2  = 100;
	  
	  // For each run
      for (int r=1; r<=N_runs; r++) {
	 
  	     printf("\n       ---  Run %3d ---", r);
 		 tr = Wtime();

         // Enable/Disable Challenges Mask
         if (E_CMPS == 0) {
	        op = 0;
	     } else {
      #if defined(AXI64)
            PUF_writeChallegesMask(&puf, puf_selr, ceil(N_CMPS/64.), DBG); 
      #else
            PUF_writeChallegesMask(&puf, puf_selr, ceil(N_CMPS/32.), DBG); 
      #endif
            op = RCHL;
	     }
         writeMMIO(&puf, &op, CHLADDC, sizeof(op));	 
	 		 
	     HDintra1 = PUF_HD(&puf, 1, CONFIG, puf_eref, puf_selm, N_tests, N_CMPS, E_CMPS);

	     printf(" HDintra = %5.3f [%5.3f - %5.3f]", HDintra1.mean, HDintra1.min, HDintra1.max);
		
		 HDimean1 = HDimean1 + HDintra1.mean;
	     if (HDintra1.max > HDimax1) HDimax1 = HDintra1.max;
	     if (HDintra1.min < HDimin1) HDimin1 = HDintra1.min;
	  
	     if (ARWCM == 1) {
            printf(" -->");
		    op = 0;
            writeMMIO(&puf, &op, CHLADDC, sizeof(op));
		 
	        HDintra2 = PUF_HD(&puf, 0, CONFIG, puf_ref, puf_selm, N_tests, N_CMPS, 0);
			
	        printf(" HDintra = %5.3f [%5.3f - %5.3f]", HDintra2.mean, HDintra2.min, HDintra2.max);
			
		    HDimean2 = HDimean2 + HDintra2.mean;
		    if (HDintra2.max > HDimax2) HDimax2 = HDintra2.max;
		    if (HDintra2.min < HDimin2) HDimin2 = HDintra2.min;
		 
		    printf(" --  %5.2f", 100-100*HDintra1.mean/HDintra2.mean);

   	     }  // end If ARWCM	
 	 		 
        if (DBG > 0) { 
            toc = Wtime() - tr;
            printf(" (%.3f s)", toc/1000000.);
         }

 		 if (W_TIME != 0) sleep(W_TIME);
		 if (W_CHAR == 1) getchar();
		 
      }	 // end runs

 #if !defined(STANDALONE)
      // Close PUF interface
      int Status;
      Status = closeMMIOWindow(&puf);
      if (Status != SUCCESS) {
         printf("\n closeMMIOWindow failed !!!\n\n");
         return ERROR;
      } 
#endif

	  if (N_runs > 1) {
		 printf("\n       ---  Average --- HDintra = %5.3f [%5.3f - %5.3f]", HDimean1/N_runs, HDimin1, HDimax1);
		 if (ARWCM == 1) {
		    printf(" --> HDintra = %5.3f [%5.3f - %5.3f] --  %5.2f", HDimean2/N_runs, HDimin2, HDimax2, 
		                 100-100*HDimean1/HDimean2);
		 }
         if (DBG > 0) {
            toc = Wtime() - ts;
            printf(" (%.3f s)", toc/1000000.);
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

 
