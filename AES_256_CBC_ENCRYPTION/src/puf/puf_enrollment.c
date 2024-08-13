/******************************************************************************/
/*
 *  IMSE.CNM_SPIRS-HwSec_puf4r3_2.0: puf_enrollment.c for PUF4R3  32/64-bits
 *
 *  Created on: 10/02/2023
 *      Author: santiago@imse-cnm.csic.es
 *
 *  Function:
 *   - Executes enrollment processes of the PUFs instantiated in a Test System 
 *     to obtain their Reference Outputs. Optionally, during each enrollment 
 *     stage, can also be generated a Selection Mask indicating the challenges 
 *     (pairs of ROs) with the worst responses from the stability point of view, 
 *     so that they can be eliminated from the PUF output in order to improve 
 *     its reliability. 
 *
 *  Outputs:
 *   - DBG = 0 --> No. differences in the Selection Mask from the previous run
 *                 + Processing times 
 *   - DBG = 1 --> + Bitstream file of the Test System 
 *                 + Time for bitstream loading (for PYNQ-Boards)
 *                 + HDintra versus Reference Output at the enrollment stage
 *                 + Average HDintra values for each PUF (if N_runs > 1)
 *   - DBG = 2 --> Reference Output after the enrollment stage
 *   - DBG = 3 --> Selection Mask indicating the discarted challenges
 *
 *  Control:
 *     -i      --> Wait for a key to be pressed between PUF and PUF (Interactive mode)
 *
 *  Output Files: 
 *     - o     --> Generates two files in the OUTDIR directory for each PUF in 
 *                 the Test System: "_ref.txt" files include the reference outputs, 
 *                 while "_mask.txt" files store the selection masks for each
 *                 enrollment stage 
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
int N_tests    = 100;      // -t Number of test for enrollment
int N_runs     = 3;        // -r Number of runs
int DBG        = 1;        // -d Debug level
int INTER      = 0;        // -i Interactive mode (PUF to PUF)
int OUT_FILE   = 0;        // -o Generate output files
char * BOARD   = "01";     // -b Board ID

int CHD        = 1;        // Compute Hamming Distance
int PE         = 1;        // PUF/Entropy Source (in IP Operation mode)

char * T_code   = "---";   // Test code
char * T_board;            // Board ID

/******************************************************************************/
/******************************************************************************/


int main(int argc, char** argv) {

   MMIO_WINDOW puf;
  
   int op;
   int board;
   int diff;
   int puf_ref[MN_CMPS];
   int puf_selm[MN_CMPS];
   int puf_selm_o[MN_CMPS];
  
   HammDist HDintra;
   
   double HDimean;
   double HDimax;
   double HDimin;
   
   unsigned int CONFIG;
   unsigned long long toc, tr, ts;
   
   char * bitstream_file;
   char input_file[100];
   char output_file1[100];
   char output_file2[100];
   //char idtrail[20];
   char odtrail[20];
   char cboard[3];
   char ctcode[4];
   
   FILE *fptr1;
   FILE *fptr2;

 #if !defined(STANDALONE)

   int arg;
   for(arg=1; arg < argc; arg++) {
      if(argv[arg][0] == '-') {
         if(argv[arg][1] == 'h') {
            printf("\nUsage: ./puf_enrollment [ -h | [-i] [-g] [-n] [-l] [-b <board_id>] [-d <dbg_level>]");
            printf("\n                        [-c <n_cmpc>] [-e <n_cmps>] [-t <n_tests>] [-r <n_runs>] ]\n\n");
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
            if(N_tests>MN_TESTS) N_tests=MN_TESTS;
         } else if(argv[arg][1] == 'r') {
            if(arg<argc-1) N_runs = atoi(argv[arg+1]);
            if(N_runs<1) N_runs=1;
         } else if(argv[arg][1] == 'o') {
            OUT_FILE=1;
         } else if(argv[arg][1] == 'e') {
            if(arg<argc-1) E_CMPS = atoi(argv[arg+1]);
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
   //sprintf(odtrail, "_%d_%d_%d", Nx*Ny, Ns, Nbc);
   strcpy(input_file, InF);
   //strcat(input_file, idtrail);
   bitstream_file = strcat(input_file, ".bit");
       
   printf("\n  --- Start Test ---> T_board %s, T_code %s, N_runs %d, N_tests %d, N_cmps %d, E_cmps %d\n",
          T_board, T_code, N_runs , N_tests, N_CMPS, E_CMPS);
   
   if (DBG > 0) {
      printf("\n   --- Bitstream_file: %s\n", bitstream_file);
   }
   if (DBG < 1) {
      printf("\n");
   }

 #if defined(PYNQ)
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

 #if defined(STANDALONE)
      puf = PUF_BASEADDR[s];
 #endif
      // Create PUF interface
      PUF_createMMIOWindow(&puf, PUF_BASEADDR[s], PUF_LENGTH, 0); 	   
	   
      // Reset Challenges Mask
	  op = 0;
      writeMMIO(&puf, &op, CHLADDC, sizeof(op));	 

 	  ts = Wtime();
      for (int c=0; c<N_CMPS; c++) {
     	  puf_selm[c] = 0;
     	  puf_selm_o[c] = 0;
      }
	  
      if (OUT_FILE == 1) {      
         strcpy(output_file1, OutF);  
         strcat(output_file1, opt[s]);
         strcat(output_file1, odtrail);
         strcat(output_file1, "_");     
         strcat(output_file1, T_board);
         strcat(output_file1, "_");     
         strcat(output_file1, T_code);
         strcpy(output_file2, output_file1);  	
         strcat(output_file1, "_ref.txt");      
         strcat(output_file2, "_mask.txt");      
         fptr1 = fopen(output_file1,"w");  
         fptr2 = fopen(output_file2,"w");  
      }		  
  
	  HDimean = 0;    
	  HDimax  = 0;  
	  HDimin  = 100;
	  
      for (int r=1; r<=N_runs; r++) {
		  
         printf("\n    --  Run %3d", r);
    
         tr = Wtime();
   
         HDintra = PUF_enrollment(&puf, 0, CHD, CONFIG, N_tests, N_CMPS, E_CMPS, 
   	                              puf_ref, puf_selm);
      	                     
 		 HDimean = HDimean + HDintra.mean;
		 if (HDintra.max > HDimax) HDimax = HDintra.max;
		 if (HDintra.min < HDimin) HDimin = HDintra.min;
		 
         if (DBG == 2) {
	        printf("  - puf_ref:  ");    
            for (int c=0; c<N_CMPS; c++) {
     	        printf("%1X", puf_ref[c]);
            }
		 }	
         if (DBG == 3) {	   
   	        printf("  - puf_selm: ");    
            for (int c=0; c<N_CMPS; c++) {
     	        printf("%1X", puf_selm[c]);
			}
   	     }
		 
         if (OUT_FILE == 1) {

 #if defined(STANDALONE)
             printf("\n");
             for (int c=0; c<ceil(N_CMPS/8.)*8; c++) {
      	        printf("%1X", puf_ref[c]);
             }
             printf("\n");
             for (int c=0; c<ceil(N_CMPS/8.)*8; c++) {
       	        printf("%1X", puf_selm[c]);
             }
             printf("\n      ");
 #else
            for (int c=0; c<N_CMPS; c++) {
     	        fprintf(fptr1, "%1X", puf_ref[c]);
      	        fprintf(fptr2, "%1X", puf_selm[c]);
            }
            fprintf(fptr1, "\n");		   
            fprintf(fptr2, "\n");		   
#endif
		 }	
		   	  
   	     diff = 0;
            for (int c=0; c<N_CMPS; c++) {
   		    if (puf_selm[c] != puf_selm_o[c]) diff++;
   		    puf_selm_o[c] = puf_selm[c];
   	     }
   	  
         toc = Wtime() - tr;
         if (r == 1) {
            printf("  Diff: %4d  ", 0);
	  } else {
            printf("  Diff: %4d  ", diff);
         }
		 if ((CHD == 1) & (DBG == 1)) {
            printf("---  HDintra: %6.3f [%5.3f - %5.3f]", HDintra.mean, HDintra.min, HDintra.max);
		 }
		  printf("  (%.3f s)", toc/1000000.);
		  
      }  // end runs
	  
      if (OUT_FILE == 1) {      
         fclose(fptr1);
         fclose(fptr2);
      }
 	  
 #if !defined(STANDALONE)
      // Close PUF interface
      int Status;
      Status = closeMMIOWindow(&puf);
      if (Status != SUCCESS) {
         printf(" closeMMIOWindow failed !!!\n\n");
         return ERROR;
      } 
 #endif

	  if ((N_runs > 1) & (DBG == 1)) {
		 printf("\n    --  Average              ---  HDintra:  %5.3f [%5.3f - %5.3f]", HDimean/N_runs, HDimin, HDimax);
         toc = Wtime() - ts;
         printf("  (%.3f s)", toc/1000000.);
	  }
	  
      if ((INTER == 1) & (s < ns-1)) {
         printf("\n\n   Press any key to continue");
         getchar();
      }

      printf("\n\n");	
	  
   }  // end pufs
   
   printf("  --- End Test\n\n");
   
}
  


