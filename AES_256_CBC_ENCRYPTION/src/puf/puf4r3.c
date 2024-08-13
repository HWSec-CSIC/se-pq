/******************************************************************************/
/*
 *  IMSE.CNM_SPIRS-HwSec_puf4r3_2.0: puf4r3.c    32/64-bits
 *
 *  Created on: 10/02/2023
 *      Author: santiago@imse-cnm.csic.es
 */
/******************************************************************************/

/******************************** Include Files *******************************/

#include "puf4r3.h"

#if defined(STANDALONE)
 #if defined(PYNQZ2)					
  #include "xtime_l.h"
 #endif
#endif	  

////////////////////////////////////////////////////////////////////////////////
///////////                                                          ///////////
///////////                    PUF FUNCTIONS                         ///////////
///////////                                                          ///////////
////////////////////////////////////////////////////////////////////////////////

#if defined(PYNQZ2)
 #if !defined(STANDALONE)
/******************************************************************************/
/*
 * PUF_loadBitstream(bitstream_file, DBG)
 *
 * Load bitstream to program the device (only for Zynq-7000 and Zynq UltraScale+)
 *
 * Params: bitstream_file  --  device programming file
 *         DBG             --  debug level
 *
 * Return:                 --  status           
 *
 ******************************************************************************/

int PUF_loadBitstream(char* bitstream_file, int DBG) {

	int Status;
	unsigned long long tic, toc;
	FILE *bptr;
	
	if ((DBG > 2) & (DBG < 5)) {
		printf("\n      - Loading Bitstream ............ ");
		tic = PYNQ_Wtime();
	}
	
	if ((bptr = fopen(bitstream_file, "r"))) {
		fclose(bptr);
	} else {
		printf("Bitstream doesn't exist. Bye ...\n\n");
		//return PYNQ_ERROR;
		exit(PYNQ_ERROR);
	}
			
	Status = PYNQ_loadBitstream(bitstream_file);
	if (Status != PYNQ_SUCCESS) {
		printf("LoadBitstream Failure\n\n");
		exit(PYNQ_ERROR);  
	}
	
	if ((DBG > 2) & (DBG < 5)) {
		toc = PYNQ_Wtime() - tic;	
		printf("(%.3f ms)\n", toc/1000.);
	}
	
	return PYNQ_SUCCESS;
}

 #endif
#endif

/******************************************************************************/
/*
 * PUF_createMMIOWindow(&puf, baseaddr, length, DBG)
 *
 * Create Memory-Mapped IO window for PUF registers
 *
 * Params: puf       --  data structure to access PUF registers
 *         baseaddr  --  base address in PS memory map
 *         length    --  size of the data structure
 *         DBG       --  debug level
 *
 * Return:           --  PUF identifier
 *
 ******************************************************************************/

int PUF_createMMIOWindow(MMIO_WINDOW* puf, int baseaddr, int length, int DBG) {

   unsigned long long tic, toc;
   unsigned int id;
   unsigned int dataout;

   if ((DBG > 2) & (DBG < 5)) {
      printf("\n\n      -- Creating MMIOWindow ......... ");
      tic = Wtime();
   }

 #if !defined(STANDALONE)
   int Status;
   Status = createMMIOWindow(puf, baseaddr, length);
   if (Status != SUCCESS) {
      printf("\n createMMIOWindow failed!\n\n");
      exit(ERROR);
   }
 #endif

   if ((DBG > 2) & (DBG < 5)) {
      toc = Wtime() - tic;
      printf("(%.3f ms)", toc/1000.);
   }

 #if defined(STANDALONE)
   dataout = PUF4R3_mReadReg(*puf, DATAOUT);
 #else
   readMMIO(puf, &dataout, DATAOUT, sizeof(dataout));
 #endif
   id = (dataout >> 16);
   printf("   ---  ID: %d ---", id);
   
   if (DBG > 0) {
      printf("\n");
   }  
   return id;   
}

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

#if defined(AXI64)
 int PUF_writeChallegesMask(MMIO_WINDOW* puf, long long puf_selr[], int regs, int DBG) {
   unsigned long long dat;
#else
 int PUF_writeChallegesMask(MMIO_WINDOW* puf, int puf_selr[], int regs, int DBG) {
   unsigned int dat;
#endif

   unsigned int op;
   unsigned long long tic, toc;
   unsigned int dataout;
   unsigned int id;
  
  // send reset & configuration
   if ((DBG > 2) & (DBG < 5)) {
      printf("\n         - Writing Challenges Mask. .. ");
      tic = Wtime();
   }
   
   if (DBG == 6) {
      printf("\n");
      printf("       W -  puf_selr: ");
      for(int chl_r=0; chl_r<regs; chl_r++ ) {
   #if defined(AXI64)
         printf("%16.16llX ", puf_selr[chl_r]);
   #else
         printf("%8.8X ", puf_selr[chl_r]);
   #endif			
         }
      }

 #if !defined(STANDALONE)
 
   for (int chl_r=0; chl_r<regs; chl_r++) {
      op = chl_r; 
      writeMMIO(puf, &op, CHLADDC, sizeof(op));
      dat = puf_selr[chl_r];
      writeMMIO(puf, &dat, CHLDATA, sizeof(dat));
      op = op + WCHL;
      writeMMIO(puf, &op, CHLADDC, sizeof(op));	 
   }
   op = 0;
   writeMMIO(puf, &op, CHLADDC, sizeof(op));
   readMMIO(puf, &dataout, DATAOUT, sizeof(dataout));

 #else
	 
   for (int chl_r=0; chl_r<regs; chl_r++) {
      op = chl_r; 
      PUF4R3_mWriteReg(*puf, CHLADDC, op);
      dat = puf_selr[chl_r];
      PUF4R3_mWriteReg(*puf, CHLDATA, op);
      op = op + WCHL;
      PUF4R3_mWriteReg(*puf, CHLADDC, op);	 
   }
   op = 0;
   PUF4R3_mWriteReg(*puf, CHLADDC, op);	   
   dataout = PUF4R3_mReadReg(*puf, DATAOUT);
   
 #endif
 
   /////////////////////////////////////////
   if (DBG == 6) {
      printf("\n       R -  puf_selr: ");
      for (int chl_r=0; chl_r<regs; chl_r++) {
         op = chl_r; 
         writeMMIO(puf, &op, CHLADDC, sizeof(op));
         readMMIO(puf, &dat, CHLDATA, sizeof(dat));
   #if defined(AXI64)
         printf("%16.16llX ", dat);
   #else
	     printf("%8.8X ", dat);
   #endif
     }
   }
  /////////////////////////////////////////
   
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

 int PUF_applyChallenges(MMIO_WINDOW* puf, int config, int cmps, int DBG) {

 #if defined(AXI64)
   unsigned long long dataout;
 #else
   unsigned int dataout;
 #endif 
   unsigned long long tic, toc;
   unsigned int op;
   int last_reg;
   int tries;
   int Delay; 

 #if defined(AXI64)
   cmps = ceil(cmps/16.)*16;					//  Convert to multiple of 16  
 #else
   cmps = ceil(cmps/8.)*8;						//  Convert to multiple of 8  
 #endif
 
   // send reset & configuration
   if ((DBG > 2) & (DBG < 5)) {
      printf("\n         - Sending reset & conf. ..... ");
      tic = Wtime();
   }

 #if !defined(STANDALONE)
   op = RESET; 
   writeMMIO(puf, &op, CONTROL, sizeof(op));
   op = OPER;
   writeMMIO(puf, &op, CONTROL, sizeof(op));
   op = (cmps<<6) + config;
   writeMMIO(puf, &op, CONTROL, sizeof(op));
   readMMIO(puf, &dataout, DATAOUT, sizeof(dataout));
 #else
   op = RESET;
   PUF4R3_mWriteReg(*puf, CONTROL, op);
   op = OPER;
   PUF4R3_mWriteReg(*puf, CONTROL, op);
   op = (cmps<<6) + config;
   PUF4R3_mWriteReg(*puf, CONTROL, op);
   dataout = PUF4R3_mReadReg(*puf, DATAOUT);
 #endif
   
   if (dataout&0x01) {
      printf("\n\n------ System is busy --> Exit \n\n");
      return ERROR;
   }
   if ((DBG > 2) & (DBG < 5)) {
      toc = Wtime() - tic;
      printf("(%.3f ms)\n", toc/1000.);         // Send reset & conf.      
   }
   
   // Start puf operation
   if ((DBG > 2) & (DBG < 5)) {
      printf("         - Operating ................. ");
      tic = Wtime();      
   }   
   op = op + START;

 #if defined(STANDALONE)
   PUF4R3_mWriteReg(*puf, CONTROL, op);
   dataout = PUF4R3_mReadReg(*puf, DATAOUT);
 #else
   writeMMIO(puf, &op, CONTROL, sizeof(op));
   readMMIO(puf, &dataout, DATAOUT, sizeof(dataout));               
 #endif

   tries = 0;
   Delay = inc_delay * cmps;

   // wait NOT BUSY   
   while (!(dataout&0x01)) {
      for (int d=0; d<Delay; d++) {
         // Delay for read operations
      }

 #if defined(STANDALONE)
      dataout = PUF4R3_mReadReg(*puf, DATAOUT);
 #else
      readMMIO(puf, &dataout, DATAOUT, sizeof(dataout));               
 #endif

      if ((DBG > 3) & (DBG < 5)) {
         printf(".");  
      } 
      tries++;
      if (tries > MaxTries) {
         break;
      }
   }
      
   last_reg = (dataout & 0x000000000000FFFF)>>1;
   if ((DBG > 0) & (DBG < 3) & (last_reg == ceil((float)cmps*BPC/Dbw)) ) {
     printf(" -- Registers: %3d", last_reg);
   }
   if ((DBG > 2) & (DBG < 5)) {
      toc = Wtime() - tic;
      printf("(%.3f ms)", toc/1000.);         // operating
   }      
   
   if (tries > MaxTries) {
      if ((DBG > 1) & (DBG < 5)) {      
         printf("  -- MaxTries reached");
      }
      if ((DBG > 1) & (DBG < 5)) {      
         printf("\n");
      }
   }   
   
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

 #if defined(AXI64)

int PUF_readOutput(MMIO_WINDOW* puf, int cmps, unsigned long long puf_out[], int DBG) { 
	unsigned long long pufout;

#else

int PUF_readOutput(MMIO_WINDOW* puf, int cmps, unsigned int puf_out[], int DBG) {
   unsigned int pufout;

#endif	

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

 #if defined(STANDALONE)
      PUF4R3_mWriteReg(*puf, PUFADDR, pufaddr);
      pufout = PUF4R3_mReadReg(*puf, PUFOUT);
 #else
      writeMMIO(puf, &pufaddr, PUFADDR, sizeof(pufaddr));                     
      readMMIO(puf, &pufout, PUFOUT, sizeof(pufout));
 #endif
 
 if (DBG == 2) {
 #if defined(AXI64)
            printf("         - Register: %3d    -->    pufout: %16.16llX \n", pufaddr, pufout);
 #else
			printf("         - Register: %3d    -->    pufout: %8.8X \n", pufaddr, pufout);
 #endif
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
           
 HammDist PUF_enrollment(MMIO_WINDOW* puf, int DBG, int CHD, unsigned int config,
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

#if defined(AXI64)
   unsigned long long puf_output[MN_REGS/2];
#else	
   unsigned int puf_output[MN_REGS];
#endif

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
 #if defined(AXI64)
        for (int c=15; c>-1; c--) {
            cmp_result = ((puf_output[r]>>c*4)&0xF);
            puf_results[t-1][r*16+15-c] = cmp_result;
 #else
        for (int c=7; c>-1; c--) {
            cmp_result = ((puf_output[r]>>c*4)&0xF);
            puf_results[t-1][r*8+7-c] = cmp_result;
 #endif
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

 HammDist PUF_HD(MMIO_WINDOW* puf, int DBG, unsigned int config, int puf_ref[],
	            int puf_selm[], int N_tests, int N_cmps, int E_cmps) {

   int Status;
   int triesr;
   int last_reg;
   int HD, HDmn, HDmx, HDt;
   HammDist HDintxx;  
   
#if defined(AXI64)
   unsigned long long puf_output[MN_REGS/2];
#else	
   unsigned int puf_output[MN_REGS];
#endif

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
	  
	  //////////////////////////////////////////////  DBG MODE
	  if (0) {
    	 printf("\n       ---  puf_outc: ");    
         for (int c=0; c<N_cmps-E_cmps; c++) {
        	 printf("%1X", puf_outc[c]);
         }
      }
	  //////////////////////////////////////////////  END DBG MODE

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
      
#if defined(AXI64)

void puf_rtob(long long puf_reg[], int n_regs, char* puf_bin) { 

   unsigned long long reg;
   
   for (int addr=0; addr<n_regs; addr++) {
      reg = puf_reg[addr];
      for (int bit=0; bit<64; bit++) {
         if (reg & 1)
            puf_bin[(63-bit)+addr*64] = 1;
         else
            puf_bin[(63-bit)+addr*64] = 0;

         reg >>= 1;
      }
   }
   return;
   
}

#else

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
   
#endif	

/******************************************************************************/
/*                                                                            */
/* Convert PUF output registers into comparisons stored in an int vector      */
/*                                                                            */
/******************************************************************************/
      
#if defined(AXI64)

void puf_rtoc(unsigned long long puf_reg[], int n_regs, int puf_cmp[]) { 

   unsigned long long reg;
   
   for (int addr=0; addr<n_regs; addr++) {
      reg = puf_reg[addr];
      for (int c=0; c<16; c++) {    
            puf_cmp[(15-c)+addr*16] = reg & 0xF;
			reg >>= 4;
	  }
   }
   return;
   
}

#else

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

#endif	

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
      
#if defined(AXI64)
void chl_btor(int puf_selm[], int n_cmps, long long puf_selr[]) { 
   long long selm;
   int b = 0;
   int r = 0;
   for (int cmp=0; cmp<n_cmps; cmp++) {  
      selm = puf_selm[cmp];
      puf_selr[r] = puf_selr[r] + (selm<<(63-b));
	  b++;
	  if (b == 64) {
		 b = 0;
         r++;
      }
  } 
   return;   
}
   
#else
	
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

#endif

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

////////////////////////////////////////////////////////////////////////////////
///////////                    Wtime standalone                      ///////////
////////////////////////////////////////////////////////////////////////////////

#if defined(STANDALONE)
 # if defined(PYNQZ2)
  unsigned long long Wtime() {
	XTime time_val;
	XTime_GetTime(&time_val);
	return time_val*4/1250;
  }
 #else
  unsigned long long Wtime() {
	return 0;
  }
 #endif
# else

////////////////////////////////////////////////////////////////////////////////
///////////                                                          ///////////
///////////          From PYNQ C-API Function Definitions            ///////////
///////////           https://github.com/mesham/pynq_api             ///////////
///////////                                                          ///////////
////////////////////////////////////////////////////////////////////////////////


/**
* Creates an MMIO window at a specific base address of a provided size
*/


int createMMIOWindow(MMIO_WINDOW * state, size_t address_base, size_t length) {
  // Align the base address with the pages
  state->virt_base = address_base & ~(sysconf(_SC_PAGESIZE) - 1);
  state->virt_offset = address_base - state->virt_base;
  state->length=length;
  state->address_base=address_base;

  state->file_handle=open(MEMORY_DEV_PATH, O_RDWR | O_SYNC);
  if (state->file_handle == -1) {
    fprintf(stderr, "Unable to open '%s' to create memory window", MEMORY_DEV_PATH);
    return ERROR;
  }
  state->buffer=mmap(NULL, length+state->virt_offset, PROT_READ | PROT_WRITE, 
                     MAP_SHARED, state->file_handle, state->virt_base);
  if (state->buffer == MAP_FAILED) {
    fprintf(stderr, "Mapping memory to MMIO region failed");
    return ERROR;
  }
  return SUCCESS;
}


/**
* Closes an MMIO window that we have previously created
*/
int closeMMIOWindow(MMIO_WINDOW * state) {
  close(state->file_handle);
  return SUCCESS;
}

/**
* Writes some data, of provided size to the specified offset in the memory window
*/
int writeMMIO(MMIO_WINDOW * state, void * data, size_t offset, size_t size_data) {
  memcpy(&(state->buffer[offset]), data, size_data);
  return SUCCESS;
}

/**
* Reads some data, of provided size to the specified offset from the memory window
*/
int readMMIO(MMIO_WINDOW * state, void * data, size_t offset, size_t size_data) {
  memcpy(data, &(state->buffer[offset]), size_data);
  return SUCCESS;
}

/**
* Returns the time in microseconds since the epoch
*/

unsigned long long Wtime() {
  struct timeval time_val;
  gettimeofday(&time_val, NULL);
  return time_val.tv_sec * 1000000 + time_val.tv_usec;
}

#endif

