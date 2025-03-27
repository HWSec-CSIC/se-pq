/****************************************************************************************/
/*
 *  IMSE.CNM_HwSec_puf4r5_2.1: puf4.c    32/64-bits
 *
 *  Created on: 18/03/2024
 *      Author: santiago@imse-cnm.csic.es
 *
 */

/******************************** Include Files *******************************/

#include "puf4.h"

////////////////////////////////////////////////////////////////////////////////
///////////                                                          ///////////
///////////                    PUF FUNCTIONS                         ///////////
///////////                                                          ///////////
////////////////////////////////////////////////////////////////////////////////


/******************************************************************************/
/*
 * PUF_writeChallegesMask(&puf, puf_selr[], regs, DBG)
 *
 * Write challenge selection mask
 *
 * Params: puf      --  data structure to access PUF registers
 *         puf_selr --  challenge selection mask register
 *         reg      --  number of registers
 *         DBG      --  debug level
 *
 * Return:          --  PUF identifier
 *
 ******************************************************************************/

 int PUF_writeChallegesMask(INTF* puf, int puf_selr[], int regs, int DBG) {
   unsigned int dat;

   unsigned int op;
   unsigned long long tic, toc;
   unsigned int dataout;
   unsigned int id;
  
  // send reset & configuration
 
   for (int chl_r=0; chl_r<regs; chl_r++) {
      op = chl_r; 
      write_INTF(puf, &op, CHLADDC, sizeof(op));
      dat = puf_selr[chl_r];
      write_INTF(puf, &dat, CHLDATA, sizeof(dat));
      op = op + WCHL;
      write_INTF(puf, &op, CHLADDC, sizeof(op));	 
   }
   op = 0;
   write_INTF(puf, &op, CHLADDC, sizeof(op));
   read_INTF(puf, &dataout, DATAOUT, sizeof(dataout));

   id = (dataout >> 16);

   if ((DBG > 2) & (DBG < 5)) {
      toc = Wtime() - tic;
      printf("(%.3f ms)", toc/1000.);
   }

   return id;   
}

/******************************************************************************/
/*
 * PUF_applyChallenges(&puf, config, cmps, DBG)
 *
 * Reset, configure and start PUF operation
 *
 * Params: puf     --  data structure to access PUF registers
 *         config  --  PUF configuration parameters
 *         cmps    --  number of comparison cycles (number of challenges)
 *         DBG     --  debug level
 *
 * Return:         --  address of the last register of the PUF output
 *
 ******************************************************************************/

 int PUF_applyChallenges(INTF* puf, unsigned int config, int cmps, int DBG) {

   unsigned int dataout;
   unsigned int op;
   int last_reg;
   int tries;
   int Delay; 

   cmps = ceil(cmps/8.)*8;						//  Convert to multiple of 8  
 

   op = RESET; 
   write_INTF(puf, &op, CONTROL, sizeof(op));
   op = OPER;
   write_INTF(puf, &op, CONTROL, sizeof(op));
   op = (cmps<<6) + config;
   write_INTF(puf, &op, CONTROL, sizeof(op));
   read_INTF(puf, &dataout, DATAOUT, sizeof(dataout));
   
   if (dataout&0x01) {
      printf("\n\n------ System is busy --> Exit \n\n");
      return ERROR;
   }
   
   // Start puf operation
   op = op + START;
   write_INTF(puf, &op, CONTROL, sizeof(op));
   read_INTF(puf, &dataout, DATAOUT, sizeof(dataout));               

   tries = 0;
   Delay = inc_delay * cmps;

   // wait NOT BUSY   
   while (!(dataout&0x01)) {
      for (int d=0; d<Delay; d++) {
         // Delay for read operations
      }
      read_INTF(puf, &dataout, DATAOUT, sizeof(dataout));               

      tries++;
      if (tries > MaxTries) {
         break;
      }
   }
      
   last_reg = (dataout & 0x000000000000FFFF)>>1;     
   
   if (tries > MaxTries) printf("\n ERROR: MaxTries reached");
   
   return last_reg;
}

/******************************************************************************/
/*
 * PUF_readOutput(&puf, cmps, puf_out[], DBG)
 *
 * Read PUF results in the array passed as parameter
 *
 * Params: puf        --  data structure to access PUF registers
 *         cmps       --  number of comparison cycles (number of challenges)
 *         puf_out[]  --  PUF output grouped into 32/64-bit registers 
 *         DBG        --  debug level
 *
 * Return:            --  status
 *
 ******************************************************************************/

int PUF_readOutput(INTF* puf, int cmps, unsigned int puf_out[], int DBG) {
   unsigned int pufout;


   unsigned long long tic, toc;
   unsigned int pufaddr;
   
   if ((DBG > 1) & (DBG < 3)) {
      printf("\n");
   }
   
   if ((DBG > 2) & (DBG < 5)) {
      printf("\n         - Reading results ........... ");
      tic = Wtime();   
   }
   
   if ((DBG > 1) & (DBG < 3)) {
      printf("\n");
   }
   
   for (int a=0; a<ceil((float)cmps*BPC/Dbw); a++) {
      pufaddr = a;

      write_INTF(puf, &pufaddr, PUFADDR, sizeof(pufaddr));                     
      read_INTF(puf, &pufout, PUFOUT, sizeof(pufout));
 
        if (DBG == 2) {
			printf("         - Register: %3d    -->    pufout: %8.8X \n", pufaddr, pufout);
		}

      puf_out[a]=pufout;
   }
                  
   if ((DBG > 2) & (DBG < 5)) {
      toc = Wtime() - tic;
      printf("(%.3f ms)\n", toc/1000.);         // Reading results
   }      
   return SUCCESS;
}

/******************************************************************************/
/*
 * PUF_enrollment(&puf, DBG, CHD, config, E_Tests, N_cmps, E_cmps,
 *                puf_ref[], puf_selm[])
 *
 * Generate PUF Output Reference and RO Selection Mask, 
 * [calculate Hamming Distance for enrollment data]
 *
 * Params: puf         --  data structure to access PUF registers
 *         DBG         --  debug level
 *         CHD         --  calculate Hamming distance
 *         config      --  PUF configuration parameters
 *         E_tests     --  number of test for enrollment
 *         N_cmps      --  number of comparison cycles (number of challenges)
 *         E_cmps      --  number of challenges eliminated in enrollment 
 *         puf_ref[]   --  PUF output reference vector 
 *         puf_selm[]  --  PUF RO Selection Mask vector
 *
 * Return:             --  Hamming Distance for enrollment data

 ******************************************************************************/
           
 HammDist PUF_enrollment(INTF* puf, int DBG, int CHD, unsigned int config,
	                     int E_tests, int N_cmps, int E_cmps, int puf_ref[],
						 int puf_selm[]) {

   int Status;
   int triesr;
   int last_reg;
   int cmp_result;
   int cmp;
   int maxv, maxd;
   int val, pos;
   int cases[16];
   int HD, HDmn, HDmx, HDt;
   HammDist HDintra;

   unsigned int puf_output[MN_REGS];

   unsigned int puf_results[MN_TESTS][MN_CMPS];
   int puf_diff[MN_CMPS];
   int puf_outc[MN_CMPS];
   char puf_outb[MN_BITS];
   char puf_refb[MN_BITS];
   
   int N_bits;
   int N_regs;
   
   N_regs  = ceil(N_cmps/(Dbw/4.));      // Number of registers 
   N_bits  = N_cmps*4;                   // Number of bits
 
   triesr = 0;

   // For each Test (t)
   for (int t=1; t<=min(E_tests,MN_TESTS); t++) {
                 
      // Reset, configure and generate PUF responses
      last_reg = PUF_applyChallenges(puf, config, N_cmps, 0);
      
      if (last_reg < N_regs) {
         triesr++;
         t = t-1;
      }
      
      //Read PUF results
      Status = PUF_readOutput(puf, N_cmps, puf_output, 0);
      if (Status != SUCCESS) {
         printf("PUF_readOutput failed!\n\n");
		 exit(ERROR);
      }
	  
      // printf("\n");	  
	  // for (int r=0; r<N_regs; r++) {
         // printf(" %16.16llX", puf_output[r]);    // Hex output          ----- DEL -----
      // }

      //Store comparisons results
      for (int r=0; r<N_regs; r++) {
        for (int c=7; c>-1; c--) {
            cmp_result = ((puf_output[r]>>c*4)&0xF);
            puf_results[t-1][r*8+7-c] = cmp_result;
         }
      }
   }  // end tests
 
   // Get reference PUF values (mode) 	      
   for (int c=0; c<N_cmps; c++) {
  	  for (int d=0; d<16; d++) {
  	     cases[d]= 0;
      }
      for (int t=0; t<min(E_tests,MN_TESTS); t++) {
  	     cmp = puf_results[t][c];
  	     cases[cmp]++;
      }  

      maxv = 0;
      maxd = 0;
      for (int d=0; d<16; d++) {
  	     if (cases[d] > maxv) {
  		    maxv = cases[d];
  		    maxd = d;
  	    }
      }
      puf_ref[c] = maxd;
   }

   // Get differences againsts the reference PUF      
   for (int c=0; c<N_cmps; c++) {
      puf_diff[c] = 0;
      puf_selm[c] = 0;
      for (int t=0; t<min(E_tests,MN_TESTS); t++) {
  	     if (puf_results[t][c] !=  puf_ref[c]) {
            puf_diff[c]++;
         }		  
  	  }
   }
   
   // Identify the worst n comparisons      
   for(int k=0; k<E_cmps; k++) {
      val = -1;
      for (int c=0; c<N_cmps; c++) {
     	 if (puf_diff[c] >= val){
  	        val = puf_diff[c];
  	        pos = c;
  	     }
      }
      puf_diff[pos] = -1;
      puf_selm[pos] = 1;
   }
 
   if (CHD == 1) { 
      // Calculate PUF HDintra 
      HD = 0;  HDmx = 0; HDmn = 100;
      puf_ctob(puf_ref, N_cmps, puf_refb);
      for (int t=0; t<min(E_tests,MN_TESTS); t++) {  
   	     for (int c=0; c< N_cmps; c++) {
            puf_outc[c] = puf_results[t][c];
   	     }
   	     puf_ctob(puf_outc, N_cmps, puf_outb);  
   
         HDt = 0;
         for (int b=0; b<N_bits; b++) {
            if (puf_outb[b] != puf_refb[b]) {
               HDt++;
   	        }
         }
         HD = HD+HDt;
         if (HDt > HDmx) HDmx = HDt;		 
         if (HDt < HDmn) HDmn = HDt;		 
      }
      HDintra.mean = 100*HD/(double)(N_bits*E_tests);	  
      HDintra.max = 100*HDmx/(double)N_bits;	  
      HDintra.min = 100*HDmn/(double)N_bits;	  
   }
   
   return HDintra;	 
}

/******************************************************************************/
/*
 * PUF_HD(&puf, DBG, config, puf_ref, puf_selm, N_tests, N_cmps, E_cmps)
 *			   
 * Calculate mean, min and maximum Hamming distance
 *
 * Params: puf         --  data structure to access PUF registers
 *         DBG         --  debug level
 *         config      --  PUF configuration parameters
 *         puf_ref[]   --  PUF output reference vector 
 *         puf_selm[]  --  PUF RO Selection Mask vector 
 *         N_tests     --  number of test for calculus of Hamming distance
 *         N_cmps      --  number of comparison cycles (number of challenges)
 *         E_cmps      --  number of challenges eliminated during enrollment 
 *
 * Return:             --  Hamming distance for test data
 *
 ******************************************************************************/

 HammDist PUF_HD(INTF* puf, int DBG, unsigned int config, int puf_ref[],
	            int puf_selm[], int N_tests, int N_cmps, int E_cmps) {

   int Status;
   int triesr;
   int last_reg;
   int HD, HDmn, HDmx, HDt;
   HammDist HDintxx;  
	
   unsigned int puf_output[MN_REGS];

   int  puf_outc[MN_CMPS];
   char puf_outb[MN_BITS];
   char puf_refb[MN_BITS];

   int N_bits;
   int N_regs;

   N_regs = ceil((N_cmps-E_cmps)/(Dbw/4.));    // Number of registers 
   N_bits = (N_cmps-E_cmps)*4;           		// Number of bits  	  

   HD = 0; HDmx = 0; HDmn = 1000000;
   triesr = 0;
      
   puf_ctob(puf_ref, N_cmps-E_cmps, puf_refb);

   for (int t=1; t<=N_tests; t++) {
	    
      // Reset, configure and generate PUF responses
      last_reg = PUF_applyChallenges(puf, config, N_cmps-E_cmps, 0);
     
      if (last_reg < N_regs) {
         triesr++;
         t = t-1;
		 if (triesr > 100) {
		   printf("\n\n Max tryes reached. Bye ...\n\n");
		   exit(ERROR);
 		}
     }	   
    
      //Read PUF results
      Status = PUF_readOutput(puf, N_cmps-E_cmps, puf_output, 0);
      if (Status != SUCCESS) {
         printf("PUF_readOutput failed!\n\n");
		 exit(ERROR);		 
      } 
  
      // Get PUF bits      
  	  puf_rtoc(puf_output, N_regs, puf_outc);

      puf_ctob(puf_outc, N_cmps-E_cmps, puf_outb);

      HDt = 0;
      for (int b=0; b<N_bits; b++) {
         if (puf_outb[b] != puf_refb[b]) {
            HDt++;
	     }
      }
	  
      HD = HD+HDt;
	  if (HDt > HDmx) HDmx = HDt;
	  if (HDt < HDmn) HDmn = HDt;

   }  // end tests
   
   HDintxx.mean = 100*HD/(double)(N_bits*N_tests);
   HDintxx.max = 100*HDmx/(double)N_bits;
   HDintxx.min = 100*HDmn/(double)N_bits;
      
   return HDintxx;

}

	  
////////////////////////////////////////////////////////////////////////////////
///////////                                                          ///////////
///////////                UTILITY FUNCTIONS                         ///////////
///////////                                                          ///////////
////////////////////////////////////////////////////////////////////////////////

/******************************************************************************/
/*                                                                            */
/* Convert PUF output registers into bits stored in a character vector        */
/*                                                                            */
/******************************************************************************/
      
void puf_rtob(int puf_reg[], int n_regs, char* puf_bin) { 

   unsigned int reg;
   
   for (int addr=0; addr<n_regs; addr++) {
      reg = puf_reg[addr];
      for (int bit=0; bit<32; bit++) {
         if (reg & 1)
            puf_bin[(31-bit)+addr*32] = 1;
         else
            puf_bin[(31-bit)+addr*32] = 0;

         reg >>= 1;
      }
   }
   return;
}

/******************************************************************************/
/*                                                                            */
/* Convert PUF output registers into comparisons stored in an int vector      */
/*                                                                            */
/******************************************************************************/

void puf_rtoc(unsigned int puf_reg[], int n_regs, int puf_cmp[]) { 

   unsigned int reg;
   
   for (int addr=0; addr<n_regs; addr++) {
      reg = puf_reg[addr];
      for (int c=0; c<8; c++) {    
            puf_cmp[(7-c)+addr*8] = reg & 0xF;
			reg >>= 4;
	  }
   }
   return;   
}

/******************************************************************************/
/*                                                                            */
/* Convert PUF output comparisons into bits stored in a character vector      */
/*                                                                            */
/******************************************************************************/
      
void puf_ctob(int puf_cmp[], int n_cmps, char* puf_bin) { 

   int val;
   
   for (int cmp=0; cmp<n_cmps; cmp++) {
      val = puf_cmp[cmp];
      for (int bit=0; bit<4; bit++) {
         if (val&1) 
			puf_bin[(3-bit)+cmp*4] = 1;
		 else 
            puf_bin[(3-bit)+cmp*4] = 0;
         val >>= 1;
      }
   }
   return;
   
}

/******************************************************************************/
/*                                                                            */
/* Convert Challenges Selection Mask from bits to registers                   */
/*                                                                            */
/******************************************************************************/
	
void chl_btor(int puf_selm[], int n_cmps, int puf_selr[]) { 
   int b = 0;
   int r = 0;
   for (int cmp=0; cmp<n_cmps; cmp++) {  
      puf_selr[r] = puf_selr[r] + (puf_selm[cmp]<<(31-b));
	  b++;
	  if (b == 32) {
		 b = 0;
         r++;
      }
  } 
   return;   
}

/******************************************************************************/
/*                                                                            */
/* Convert Binary to hexadecimal                                              */
/*                                                                            */
/******************************************************************************/
      
void puf_btoh(char* puf_bin, int n_bits, int puf_hex[]) { 
   int b = 0;
   int h = 0;
   for (int n=0; n<n_bits; n++) {  
      puf_hex[h] = puf_hex[h] + (puf_bin[n]<<(3-b));
	  b++;
	  if (b == 4) {
		 b = 0;
         h++;
      }
  } 
   return;   
}


/******************************************************************************/
/*                                                                            */
/*            Apply an R-Repetitions Error Correction Code                    */
/*                                                                            */
/******************************************************************************/
      
void puf_ecc(char* bin_n, int n_bits, int R, char* bin_k) { 

   int sum;
   
   // printf("\n\n");
   for (int bit=0; bit<n_bits/R; bit++) {
      sum = 0;
      for (int i=bit*R; i<(bit+1)*R; i++) {
         sum = sum + bin_n[i];
         //printf(" %2d ", i);
      }
      if (sum > R/2) {
         bin_k[bit] = 1;
      } else {
         bin_k[bit] = 0;
      }
      //printf(" bit %3d,  sum %4d,  bin_k %4d\n", bit, sum, bin_k[bit]);

   }
   return;
   
}