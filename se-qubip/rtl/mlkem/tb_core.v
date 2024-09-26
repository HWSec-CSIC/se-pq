`timescale 1ns / 1ps

module tb_core();

    parameter PERIOD = 20;
    parameter VERBOSE = 1; 
    parameter N_TEST = 10;
    
    // parameter K = 2;
    parameter K_MAX = 4;
    
    parameter RESET        = 4'b0000;
    parameter LOAD_SK      = 4'b0100;
    parameter READ_SK      = 4'b0101;
    parameter LOAD_PK      = 4'b0110;
    parameter READ_PK      = 4'b0111;
    parameter LOAD_CT      = 4'b1000;
    parameter READ_CT      = 4'b1001;
    parameter LOAD_SS      = 4'b1010;
    parameter READ_SS      = 4'b1011;
    parameter START        = 4'b1100;
    
    parameter GEN_KEYS_512  = 4'b0101;
    parameter GEN_KEYS_768  = 4'b0110;
    parameter GEN_KEYS_1024 = 4'b0111;
    parameter ENCAP_512     = 4'b1001;
    parameter ENCAP_768     = 4'b1010;
    parameter ENCAP_1024    = 4'b1011;
    parameter DECAP_512     = 4'b1101;
    parameter DECAP_768     = 4'b1110;
    parameter DECAP_1024    = 4'b1111;
    
    reg             clk;
    reg             rst;
    wire    [7:0]   control;
    reg     [3:0]   oper;
    reg     [3:0]   mode;
    assign          control = {mode, oper};
    
    reg     [15:0]  r_in;
    reg     [15:0]  add;
    
    reg     [7:0]  m_array  [0:31];
    reg     [7:0]  pk_array  [0:(K_MAX*384)-1];
    reg     [7:0]  sk_array  [0:(K_MAX*384)-1];
    reg     [7:0]  seed_array  [0:31];
    reg     [7:0]  coins_array  [0:31];
    
    wire    [15:0]  r_out;
    reg     [7:0]   ct_array  [0:2047];
    reg     [7:0]   ss_array  [0:31];
    reg     [15:0]  r_out_array  [0:2047];
    
    integer i;
    integer j;
    integer comp;
    integer test;
    integer K;
    integer i_end;
    
    CORE_MLKEM CORE_MLKEM
    (   .clk(clk), .rst(rst), 
        .control(control), .end_op(end_op),
        .add(add), .data_in(r_in), .data_out(r_out));
    
initial begin
    K = 2;
    add = 0;
    r_in = 0;
    
    // Prueba de input data
    /*
    for (i = 0; i < (K_MAX*384); i = i + 1) begin
        if(i < (K*384)) pk_array[i] = i;
        else            pk_array[i] = 0;
    end
    for (i = 0; i < (K_MAX*384); i = i + 1) begin
        if(i < (K*384)) sk_array[i] = i;
        else            sk_array[i] = 0;
    end
    */
    
    for (i = 0; i < 32; i = i + 1) begin
        m_array[i] = i;
        // seed_array[i] = i;
        // coins_array[i] = i;
    end
    
    rst = 1; oper = RESET; #(10 * PERIOD); // INIT MODULE
    rst = 0; oper = RESET; #(10 * PERIOD); // RESET MODULE
    rst = 1; oper = RESET; #(10 * PERIOD); // INIT MO
    
    for (test = 0; test < N_TEST; test = test + 1) begin
        K = 2;  TEST();
    end
    for (test = 0; test < N_TEST; test = test + 1) begin
        K = 3;  TEST();
    end
    for (test = 0; test < N_TEST; test = test + 1) begin
        K = 4;  TEST();
    end
        /*
        // ----------------------------- //
        // ---------- KEY GEN ---------  //
        // ----------------------------- //
        if(K == 2) mode = GEN_KEYS_512;
        if(K == 3) mode = GEN_KEYS_768;
        if(K == 4) mode = GEN_KEYS_1024;
        
        // ------ START ------ //
        rst = 1; oper = RESET; #(10 * PERIOD); // INIT MO
        rst = 1; oper = START;  #(PERIOD); // START
        
        while(!end_op) #(PERIOD);
        
        #(10*PERIOD);
        
        // ---- READ PK ---- //
        rst = 1; oper = READ_PK;  #(PERIOD); // READ_PK
        for (i = 0; i < (K*384); i = i + 1) begin
            add                 = i;                #(PERIOD);                                                                  
            pk_array[i]         = r_out[7:0];        #(PERIOD);
        end
        // ---- READ SEED ---- //
        rst = 1; oper = READ_PK;  #(PERIOD); // READ_PK
        for (i = (K_MAX*384); i < ((K_MAX*384) + 16); i = i + 1) begin
            add                 = i;                #(PERIOD);  
            j                   = i - (K_MAX*384);                                                                   
            seed_array[2*j]     = r_out[7:0];     
            seed_array[2*j + 1] = r_out[15:8];    #(PERIOD);
        end
        // ---- READ SK ---- //
        rst = 1; oper = READ_SK;  #(PERIOD); // READ_SK
        for (i = 0; i < (K*384); i = i + 1) begin
            add                 = i;                #(PERIOD);                                                                  
            sk_array[i]         = r_out[7:0];        #(PERIOD);
        end
        
        if (VERBOSE >= 2) begin
            // ---- PRINT PK---- //
            $write("\n");
            for (i = 0; i < (K*384); i = i + 1) begin
                if(i % 32 == 0) $write("\n");
                $write("%02x",pk_array[i]);
            end
            // ---- PRINT SEED---- //
            for (i = 0; i < 32; i = i + 1) begin
                if(i % 32 == 0) $write("\n");
                $write("%02x",seed_array[i]);
            end
            // ---- PRINT SK ---- //
            $write("\n");
            for (i = 0; i < (K*384); i = i + 1) begin
                if(i % 32 == 0) $write("\n");
                $write("%02x",sk_array[i]);
            end
        end
        
        
        // ----------------------------- //
        // -------- ENCRYPTION --------  //
        // ----------------------------- //
        if(K == 2) mode = ENCAP_512;
        if(K == 3) mode = ENCAP_768;
        if(K == 4) mode = ENCAP_1024;
         
        // ------ LOAD_PK ------ //
        rst = 1; oper = RESET; #(10 * PERIOD); // INIT MO
        rst = 1; oper = LOAD_PK;  #(PERIOD); // LOAD PK
        for (i = 0; i < (K*384); i = i + 1) begin
            add     = i;            #(PERIOD);
            r_in    = pk_array[i];  #(PERIOD);
        end
        #(PERIOD);
        
        // ------ LOAD_SEED ------ //
        rst = 1; oper = LOAD_PK;  #(PERIOD); // LOAD SEED
        for (i = (K_MAX*384); i < ((K_MAX*384) + 16); i = i + 1) begin
            add     = i;                                                                        #(PERIOD);
            j       = i - (K_MAX*384);                                                                    
            r_in    = ((seed_array[2*j+1] & 16'h00FF) << 8) | (seed_array[2*j] & 16'h00FF) ;    #(PERIOD);
        end
        
        #(PERIOD);
        
        // ---- Solo de prueba ---- //
        // ------ LOAD_M ------ //
        rst = 1; oper = LOAD_SS;  #(PERIOD); // LOAD SS
        for (i = 0; i < 32; i = i + 1) begin
            add     = i;             #(PERIOD);                                                                  
            r_in    = m_array[i];    #(PERIOD);
        end
        
        #(PERIOD);
        
        // ----- START ----- //
        rst = 1; oper = START;  #(PERIOD); // START
        
        while(!end_op) #(PERIOD);
        
        #(10*PERIOD);
        
        // ---- READ CIPHERTEXT ---- //
        rst = 1; oper = READ_CT;  #(PERIOD); // LOAD SS
        for (i = 0; i < (K*320+128); i = i + 1) begin
            add                 = i;             #(PERIOD);                                                                  
            ct_array[i]         = r_out[7:0];        #(PERIOD);
        end
        
        // ---- PRINT CIPHERTEXT ---- //
        if(VERBOSE >= 2) begin
            $write("\n");
            for (i = 0; i < (K*320+128); i = i + 1) begin
                if(i % 32 == 0) $write("\n");
                $write("%02x",ct_array[i]);
            end
        end
        
        // ----------------------------- //
        // -------- DECRYPTION --------  //
        // ----------------------------- //
        
        if(K == 2) mode = DECAP_512;
        if(K == 3) mode = DECAP_768;
        if(K == 4) mode = DECAP_1024;
        
        // ------ LOAD_SK ------ //
        rst = 1; oper = RESET; #(10 * PERIOD); // INIT MO
        rst = 1; oper = LOAD_SK;  #(PERIOD); // LOAD SK
        for (i = 0; i < (K_MAX*384); i = i + 1) begin
            add     = i;            #(PERIOD);
            r_in    = sk_array[i];  #(PERIOD);
        end
        #(PERIOD);
        
        // ---- LOAD CIPHERTEXT ---- //
        rst = 1; oper = LOAD_CT;  #(PERIOD); // LOAD CT
        for (i = 0; i < (K*320+128); i = i + 1) begin
            add                 = i;             #(PERIOD);                                                                  
            r_in                = ct_array[i];   #(PERIOD);
        end
        
        #(PERIOD);
        
        // ----- START ----- //
        rst = 1; oper = START;  #(PERIOD); // START
        
        while(!end_op) #(PERIOD);
        
        #(10*PERIOD);
        
        // ---- READ SS ---- //
        rst = 1; oper = READ_SS;  #(PERIOD); // READ SS
        for (i = 0; i < 32; i = i + 1) begin
            add                 = i;             #(PERIOD);                                                                  
            ss_array[i]         = r_out[7:0];        #(PERIOD);
        end
        
        // ---- PRINT SS ---- //
        comp = 0; 
        if(VERBOSE >= 1) begin
            $write("\n");
            for (i = 0; i < 32; i = i + 1) begin
                if(m_array[i] != ss_array[i]) comp = 1; 
                
                if(i % 32 == 0) $write("\n");
                $write("%02x",ss_array[i]);
            end
            
            if(comp) $write("\t FAIL");
            else     $write("\t OK");
        end
        */
    
    // end 
    
    
    
end
    
    // generate clock
    always     
        begin 
            clk=0; #(PERIOD/2); clk=1; #(PERIOD/2); 
		end
		
    task TEST();
        begin
        // ----------------------------- //
        // ---------- KEY GEN ---------  //
        // ----------------------------- //
        if(K == 2) mode = GEN_KEYS_512;
        if(K == 3) mode = GEN_KEYS_768;
        if(K == 4) mode = GEN_KEYS_1024;
        
        // ------ START ------ //
        rst = 1; oper = RESET; #(10 * PERIOD); // INIT MO
        rst = 1; oper = START;  #(PERIOD); // START
        
        while(!end_op) #(PERIOD);
        
        #(10*PERIOD);
        
        // ---- READ PK ---- //
        rst = 1; oper = READ_PK;  #(PERIOD); // READ_PK
        for (i = 0; i < (K*384); i = i + 1) begin
            add                 = i;                #(PERIOD);                                                                  
            pk_array[i]         = r_out[7:0];        #(PERIOD);
        end
        // ---- READ SEED ---- //
        rst = 1; oper = READ_PK;  #(PERIOD); // READ_PK
        for (i = (K_MAX*384); i < ((K_MAX*384) + 16); i = i + 1) begin
            add                 = i;                #(PERIOD);  
            j                   = i - (K_MAX*384);                                                                   
            seed_array[2*j]     = r_out[7:0];     
            seed_array[2*j + 1] = r_out[15:8];    #(PERIOD);
        end
        // ---- READ SK ---- //
        rst = 1; oper = READ_SK;  #(PERIOD); // READ_SK
        for (i = 0; i < (K*384); i = i + 1) begin
            add                 = i;                #(PERIOD);                                                                  
            sk_array[i]         = r_out[7:0];        #(PERIOD);
        end
        
        if (VERBOSE >= 2) begin
            // ---- PRINT PK---- //
            $write("\n");
            for (i = 0; i < (K*384); i = i + 1) begin
                if(i % 32 == 0) $write("\n");
                $write("%02x",pk_array[i]);
            end
            // ---- PRINT SEED---- //
            for (i = 0; i < 32; i = i + 1) begin
                if(i % 32 == 0) $write("\n");
                $write("%02x",seed_array[i]);
            end
            // ---- PRINT SK ---- //
            $write("\n");
            for (i = 0; i < (K*384); i = i + 1) begin
                if(i % 32 == 0) $write("\n");
                $write("%02x",sk_array[i]);
            end
        end
        
        
        // ----------------------------- //
        // -------- ENCRYPTION --------  //
        // ----------------------------- //
        if(K == 2) mode = ENCAP_512;
        if(K == 3) mode = ENCAP_768;
        if(K == 4) mode = ENCAP_1024;
         
        // ------ LOAD_PK ------ //
        rst = 1; oper = RESET; #(10 * PERIOD); // INIT MO
        rst = 1; oper = LOAD_PK;  #(PERIOD); // LOAD PK
        for (i = 0; i < (K*384); i = i + 1) begin
            add     = i;            #(PERIOD);
            r_in    = pk_array[i];  #(PERIOD);
        end
        #(PERIOD);
        
        // ------ LOAD_SEED ------ //
        rst = 1; oper = LOAD_PK;  #(PERIOD); // LOAD SEED
        for (i = (K_MAX*384); i < ((K_MAX*384) + 16); i = i + 1) begin
            add     = i;                                                                        #(PERIOD);
            j       = i - (K_MAX*384);                                                                    
            r_in    = ((seed_array[2*j+1] & 16'h00FF) << 8) | (seed_array[2*j] & 16'h00FF) ;    #(PERIOD);
        end
        
        #(PERIOD);
        
        // ----- START ----- //
        rst = 1; oper = START;  #(PERIOD); // START
        
        while(!end_op) #(PERIOD);
        
        #(10*PERIOD);
        
        // ---- READ CIPHERTEXT ---- //
        rst = 1; oper = READ_CT;  #(PERIOD); // LOAD SS
        
        if(K == 4)  i_end = (K*352+160);
        else        i_end = (K*320+128);
        
        for (i = 0; i < i_end; i = i + 1) begin
            add                 = i;             #(PERIOD);                                                                  
            ct_array[i]         = r_out[7:0];        #(PERIOD);
        end
        
        // ------ READ_SS ------ //
        rst = 1; oper = READ_SS;  #(PERIOD); // READ SS
        for (i = 0; i < 32; i = i + 1) begin
            add          = i;           #(PERIOD);                                                                  
            m_array[i]   = r_out[7:0];  #(PERIOD);
        end
        
        // ---- PRINT CIPHERTEXT ---- //
        if(VERBOSE >= 2) begin
            $write("\n");
            for (i = 0; i < i_end; i = i + 1) begin
                if(i % 32 == 0) $write("\n");
                $write("%02x",ct_array[i]);
            end
        end
        
        // ---- PRINT M ---- //
        if(VERBOSE >= 1) begin
            $write("\n"); $write("\t K: %d \t TEST: %d", K, test);
            for (i = 0; i < 32; i = i + 1) begin
                if(i % 32 == 0) $write("\n");
                $write("%02x",m_array[i]);
            end
        end
        
        // ----------------------------- //
        // -------- DECRYPTION --------  //
        // ----------------------------- //
        
        if(K == 2) mode = DECAP_512;
        if(K == 3) mode = DECAP_768;
        if(K == 4) mode = DECAP_1024;
        
        // ------ LOAD_SK ------ //
        rst = 1; oper = RESET; #(10 * PERIOD); // INIT MO
        rst = 1; oper = LOAD_SK;  #(PERIOD); // LOAD SK
        for (i = 0; i < (K_MAX*384); i = i + 1) begin
            add     = i;            #(PERIOD);
            r_in    = sk_array[i];  #(PERIOD);
        end
        #(PERIOD);
        
        // ---- LOAD CIPHERTEXT ---- //
        rst = 1; oper = LOAD_CT;  #(PERIOD); // LOAD CT
        for (i = 0; i < i_end; i = i + 1) begin
            add                 = i;             #(PERIOD);                                                                  
            r_in                = ct_array[i];   #(PERIOD);
        end
        
        #(PERIOD);
        
        // ----- START ----- //
        rst = 1; oper = START;  #(PERIOD); // START
        
        while(!end_op) #(PERIOD);
        
        #(10*PERIOD);
        
        // ---- READ SS ---- //
        rst = 1; oper = READ_SS;  #(PERIOD); // READ SS
        for (i = 0; i < 32; i = i + 1) begin
            add                 = i;             #(PERIOD);                                                                  
            ss_array[i]         = r_out[7:0];        #(PERIOD);
        end
        
        // ---- PRINT SS ---- //
        comp = 0; 
        if(VERBOSE >= 1) begin
            for (i = 0; i < 32; i = i + 1) begin
                if(m_array[i] != ss_array[i]) comp = 1; 
                
                if(i % 32 == 0) $write("\n");
                $write("%02x",ss_array[i]);
            end
            
            if(comp) $write("\t FAIL");
            else     $write("\t OK");
        end
        end
    endtask
    
endmodule

