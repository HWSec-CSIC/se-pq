/**
  * @file tb_core.v
  * @brief MLKEM Core Test Bench
  *
  * @section License
  *
  * Secure Element for QUBIP Project
  *
  * This Secure Element repository for QUBIP Project is subject to the
  * BSD 3-Clause License below.
  *
  * Copyright (c) 2024,
  *         Eros Camacho-Ruiz
  *         Pablo Navarro-Torrero
  *         Pau Ortega-Castro
  *         Apurba Karmakar
  *         Macarena C. Martínez-Rodríguez
  *         Piedad Brox
  *
  * All rights reserved.
  *
  * This Secure Element was developed by Instituto de Microelectrónica de
  * Sevilla - IMSE (CSIC/US) as part of the QUBIP Project, co-funded by the
  * European Union under the Horizon Europe framework programme
  * [grant agreement no. 101119746].
  *
  * -----------------------------------------------------------------------
  *
  * Redistribution and use in source and binary forms, with or without
  * modification, are permitted provided that the following conditions are met:
  *
  * 1. Redistributions of source code must retain the above copyright notice, this
  *    list of conditions and the following disclaimer.
  *
  * 2. Redistributions in binary form must reproduce the above copyright notice,
  *    this list of conditions and the following disclaimer in the documentation
  *    and/or other materials provided with the distribution.
  *
  * 3. Neither the name of the copyright holder nor the names of its
  *    contributors may be used to endorse or promote products derived from
  *    this software without specific prior written permission.
  *
  * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
  * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  *
  *
  *
  *
  * @author Eros Camacho-Ruiz (camacho@imse-cnm.csic.es)
  * @version 1.0
  **/

`timescale 1ns / 1ps

module tb_core();

    parameter PERIOD = 20;
    parameter CYCLES = 10;
    parameter VERBOSE = 1; 
    parameter N_TEST = 2;
    parameter RANDOM = 1;
    
    // parameter K = 2;
    parameter K_MAX = 4;
    
    parameter RESET         = 4'b0001;
    parameter LOAD_COINS    = 4'b0010;
    parameter LOAD_SK       = 4'b0011;
    parameter READ_SK       = 4'b0100;
    parameter LOAD_PK       = 4'b0101;
    parameter READ_PK       = 4'b0110;
    parameter LOAD_CT       = 4'b0111;
    parameter READ_CT       = 4'b1000;
    parameter LOAD_SS       = 4'b1001;
    parameter READ_SS       = 4'b1010;
    parameter LOAD_HEK      = 4'b1011;
    parameter READ_HEK      = 4'b1100;
    parameter LOAD_PS       = 4'b1101;
    parameter READ_PS       = 4'b1110;
    
    
    parameter START        = 4'b1111;
    
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
    
    reg     [63:0]  r_in;
    reg     [15:0]  add;
    
    wire    [63:0]  r_out;
    wire    [1:0]   end_op;
    
    reg     [7:0]  ek_array         [0:1568-1];
    reg     [7:0]  dk_array         [0:3168-1];
    reg     [63:0]  coins_array     [0:3];
    reg     [63:0]  z_array         [0:3];
    reg     [63:0]  m_array         [0:3];
    reg     [7:0]   ct_array        [0:2047];
    reg     [7:0]  ss_array          [0:31];
    reg     [7:0]  ss2_array         [0:31];
   
    integer i;
    integer j;
    integer comp;
    integer test;
    integer K;
    integer i_end;
    integer add_2;
    
    integer LEN_EK;
    integer LEN_DK;
    integer LEN_CT;
    integer LEN_PKE;
    
    /*
    CORE_MLKEM CORE_MLKEM
    (   .clk(clk), .rst(rst), 
        .control(control), .end_op(end_op),
        .add(add), .data_in(r_in), .data_out(r_out));
    */
        
    TOP_MLKEM TOP_MLKEM
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
    
    GEN_COINS();
    
    rst = 1; oper = RESET; #(CYCLES * 10 * PERIOD); // INIT MODULE
    rst = 0; oper = RESET; #(CYCLES * 10 * PERIOD); // RESET MODULE
    rst = 1; oper = RESET; #(CYCLES * 10 * PERIOD); // INIT MO
    
    for (test = 0; test < N_TEST; test = test + 1) begin
        K = 2; GEN_COINS(); TEST();
    end
    
    for (test = 0; test < N_TEST; test = test + 1) begin
        K = 3; GEN_COINS(); TEST();
    end
    
    for (test = 0; test < N_TEST; test = test + 1) begin
        K = 4; GEN_COINS(); TEST();
    end
    
    /*
    for (test = 0; test < N_TEST; test = test + 1) begin
        K = 2;  TEST();
    end
    for (test = 0; test < N_TEST; test = test + 1) begin
        K = 3;  TEST();
    end
    for (test = 0; test < N_TEST; test = test + 1) begin
        K = 4;  TEST();
    end
    */
    
    
end
    
    // generate clock
    always     
        begin 
            clk=0; #(PERIOD/2); clk=1; #(PERIOD/2); 
		end
    task GEN_COINS();
        begin
            
            // ACVP Test "tcId": 1 ML-KEM-512 https://github.com/usnistgov/ACVP-Server/blob/master/gen-val/json-files/ML-KEM-keyGen-FIPS203/internalProjection.json
            // "d": "1EB4400A01629D517974E2CD85B9DEF59082DE508E6F9C2B0E341E12965955CA"
            // "z": "1A394111163803FE2E8519C335A6867556338EADAFA22B5FC557430560CCD693",
            // "ek": "5B318622F73E6FC6CBA5571D0537894AA890426B835640489AA218972180BB2534BCC477C62CC839135934F3B14CD0808A11557D331103B30F9A8C0CB0FA8F0A2A152E802E48E408087510D5114D4D2399A51530616C7E310528308176D0042710BC8344EC3D4CA810A92978BFABB516D81CAB0753CDF325AC2377A1F96EFC73C15F5AA367A1582A13651B0337C7943C1D54637669686BEBBD392511FFFC9E3A68CBEEC0CE2CF59A8D51C4DE288EB4641DF6610C82D09CDDA418ACD83F0DCA2859B27117E87981AAA8EBA47515812DA2C27ADF9C682E373D5AF294BE3104474B8D14173788965ECCD80322B6CA04240E7D150F2CD4B04066C1924039B9E4A9E06C2B55DBA2FDDABB4065CFE7EBC5AE01CD45C76374683CB1820C34A841836391B9D8C2AA22B29E7436CFCAB789B3CE8AE2700351C1165B7B4F72CC53E913E5668AE75170352A0DE68A5E3819443DB4113161A2019C4930C97011F31540B833E9A890503A7EC3F38C0D94BE3C7501C6161F39099E3CAC0139ACC7271B70D1664A36A89FA4D22857C6C15AD4C52D5C26E23B81DCDA9FD7A49980C5818888AB2538AD91F54E691B7558C63FAE433A7FAB51485989F4335E6187B65041401238AA0A5A932356207796AF2C70363034546F4615499245E1228BFF2C76674634A60C9A04E00FB276C6C00A114BF1B2C8961E740A082940CEEAAB464370BBBB3919C7421BC81C732415A711AA935A4C2C02CB5D0BCBB99CE830EDDBAE4C228E4F095E29FBC27EA2B881697A1D309D28C480C3E9691FB63480BC5C6239B6CCAA41CD52A6209038C2C887BC71C1BD514A0FAA21721A2A5B30ACB168227833A8260422C1F4815EC2ADB207389FB1B817D78FC96063434B6728E18469475DB5D712BC403D8231CF9C8926D0A94B6830881FA5678AD04499F40D5CA83479BA85A70B1196C32A68A6B7FFB40EA6FC3FF020768B91B27F653746546C5E256B14069E827C1616FC7647F8B70F8A32DB551CF715BBB315B7B9BC20FF76847CFC4AEAC23DDC1302EC928CFE40447C761143194DA1415D3D8389F61BAB41EB605729123A320BB54B3B3FBCBC787C46F354C7D7D60F8DFE3729375AEF1891C08A79DE237E39E860061D",
            // "dk": "EA35075D429C8E81ADA6C4BB97D78624C602FB173DFFC78E5C744FF2FAC345B55E04A3B7325A63F58B43EEF168E259910C35A0952A7ADCF43634889C98918A1CE7B62671C1968A02688160C09B7DE9978B77A557D265A40F7C79F3124247FA0C14F8A9F2C2B939470CAD5ACA5E664ADD7B5444643B559C4BF84C524A063DA7E552C9107BB0887BC22C73F76B63ABA60955A06D1CF34491275859D46FEDEA738FEC14D9920458A7C31E657549A6160480784D5C229AD88932B384A0B0A16DD6C8FCEA56B61A50E67442FB9928B4676D92A6717A564D8E939BB7957D750BB70D2B20D8445A8912BC7940489AE01584DC7D7952A686F245D09C547EF40B74C6748B318059F66F2B76C72ECBB3A64167CAE08C27368902B76DFF684A14482AFAE5837CB6838E685987FA4E3FF7CC4A36631CBA1F77915E7C580853E3C6C84859ADC8C2A15CB131E78305F4BCB4A8100AAB206EC97D14862CF5DA4D3AE2066D4C41BBA9187BECBE0809CE6AAC1FE20BCAE87714BE1542BA9053F1802B65C82909594984A186841B2BFCB3AF38100C5E685E7B9B85515C469CA50B1F799229E024B68A4A412A185677444491689957A576F5029C742DB64C3F63614B43AA23C433A1B37811CDC1184E11BB7D9C20E587A862B364EF59651259B26F8375E4510CBB12A475816A364BA72C07566D50A2B4E4503188B7B465080DB88EE663928C894367492E1617CCBF36CF844B9D17072A3178809629B4B9729CF82C9935AA9B1205AEA6631C8EE23CEE832C46E0583FAC43C5BC5131B934527740AB12877D295C72089073E6A2567B655CCB2965FAA3DECA8315815E7B6514F05BACE8A7000B548993734DE3964F2709542496122BE58A7E536CC827839693492AE88E75EA13154AB109E6BD16F4486EE1C3EA61B8FA259283B3BC2BFB589D3206A3C77521AA08C253B4E4CC8B5F87467EEA18EBD48D92604382DB0C0087A3B501066CB55EC9602D2696380A6A5DF33C05C9B01700B61D0FC169DEBC28B3108B096B24D93B8FFE67066286B0E1461265896E33A8089D8B0B81A9781700A983B28022125A4934575220325B318622F73E6FC6CBA5571D0537894AA890426B835640489AA218972180BB2534BCC477C62CC839135934F3B14CD0808A11557D331103B30F9A8C0CB0FA8F0A2A152E802E48E408087510D5114D4D2399A51530616C7E310528308176D0042710BC8344EC3D4CA810A92978BFABB516D81CAB0753CDF325AC2377A1F96EFC73C15F5AA367A1582A13651B0337C7943C1D54637669686BEBBD392511FFFC9E3A68CBEEC0CE2CF59A8D51C4DE288EB4641DF6610C82D09CDDA418ACD83F0DCA2859B27117E87981AAA8EBA47515812DA2C27ADF9C682E373D5AF294BE3104474B8D14173788965ECCD80322B6CA04240E7D150F2CD4B04066C1924039B9E4A9E06C2B55DBA2FDDABB4065CFE7EBC5AE01CD45C76374683CB1820C34A841836391B9D8C2AA22B29E7436CFCAB789B3CE8AE2700351C1165B7B4F72CC53E913E5668AE75170352A0DE68A5E3819443DB4113161A2019C4930C97011F31540B833E9A890503A7EC3F38C0D94BE3C7501C6161F39099E3CAC0139ACC7271B70D1664A36A89FA4D22857C6C15AD4C52D5C26E23B81DCDA9FD7A49980C5818888AB2538AD91F54E691B7558C63FAE433A7FAB51485989F4335E6187B65041401238AA0A5A932356207796AF2C70363034546F4615499245E1228BFF2C76674634A60C9A04E00FB276C6C00A114BF1B2C8961E740A082940CEEAAB464370BBBB3919C7421BC81C732415A711AA935A4C2C02CB5D0BCBB99CE830EDDBAE4C228E4F095E29FBC27EA2B881697A1D309D28C480C3E9691FB63480BC5C6239B6CCAA41CD52A6209038C2C887BC71C1BD514A0FAA21721A2A5B30ACB168227833A8260422C1F4815EC2ADB207389FB1B817D78FC96063434B6728E18469475DB5D712BC403D8231CF9C8926D0A94B6830881FA5678AD04499F40D5CA83479BA85A70B1196C32A68A6B7FFB40EA6FC3FF020768B91B27F653746546C5E256B14069E827C1616FC7647F8B70F8A32DB551CF715BBB315B7B9BC20FF76847CFC4AEAC23DDC1302EC928CFE40447C761143194DA1415D3D8389F61BAB41EB605729123A320BB54B3B3FBCBC787C46F354C7D7D60F8DFE3729375AEF1891C08A79DE237E39E860061D2B87926182B602639ABB65FEBAF116F6A2FCCC167A51A2E2E6F4494C58336A2E1A394111163803FE2E8519C335A6867556338EADAFA22B5FC557430560CCD693"
            if(RANDOM == 0) begin
                coins_array[0]  = 64'h51_9d_62_01_0a_40_b4_1e;
                coins_array[1]  = 64'hf5_de_b9_85_cd_e2_74_79;
                coins_array[2]  = 64'h2b_9c_6f_8e_50_de_82_90;
                coins_array[3]  = 64'hca_55_59_96_12_1e_34_0e;
                
                z_array[0]      = 64'hfe_03_38_16_11_41_39_1a;
                z_array[1]      = 64'h75_86_a6_35_c3_19_85_2e;
                z_array[2]      = 64'h5f_2b_a2_af_ad_8e_33_56;
                z_array[3]      = 64'h93_d6_cc_60_05_43_57_c5;
                
                m_array[0]      = 64'h72_40_7c_18_ae_6c_9b_af;
                m_array[1]      = 64'h10_70_e3_3b_3f_9d_fc_56;
                m_array[2]      = 64'h28_a1_87_e6_d0_55_af_ff;
                m_array[3]      = 64'hd3_84_68_eb_62_7f_7c_f1;
            end
            else begin
                for (i = 0; i < 4; i = i + 1) begin
                    coins_array[i] = {$urandom%65536,$urandom%65536,$urandom%65536,$urandom%65536};
                    z_array[i] = {$urandom%65536,$urandom%65536,$urandom%65536,$urandom%65536};
                    m_array[i] = {$urandom%65536,$urandom%65536,$urandom%65536,$urandom%65536};
                end
            end
        end
    endtask
    
    task TEST();
        begin
        // ----------------------------- //
        // ---------- KEY GEN ---------  //
        // ----------------------------- //
        if(K == 2) mode = GEN_KEYS_512;
        if(K == 3) mode = GEN_KEYS_768;
        if(K == 4) mode = GEN_KEYS_1024;
        
        if(K == 2) LEN_EK = 800;
        if(K == 3) LEN_EK = 1184;
        if(K == 4) LEN_EK = 1568;
        
        if(K == 2) LEN_DK = 1632;
        if(K == 3) LEN_DK = 2400;
        if(K == 4) LEN_DK = 3168;
        
        // ------ RESET ------ //
        rst = 1; oper = RESET;  #(CYCLES * 10 * PERIOD); // INIT MO
        
        // ---- LOAD_COINS ---- //
        rst = 1; oper = LOAD_COINS;  #(CYCLES * PERIOD); // LOAD_COINS
        for (i = 0; i < 4; i = i + 1) begin
            add     = i;                #(CYCLES * PERIOD);
            r_in    = coins_array[i];   #(CYCLES * PERIOD);
        end
        
        // ---- LOAD_Z ---- //
        rst = 1; oper = LOAD_SS;  #(CYCLES * PERIOD); // LOAD_Z
        for (i = 0; i < 4; i = i + 1) begin
            add     = i;                #(CYCLES * PERIOD);
            r_in    = z_array[i];       #(CYCLES * PERIOD);
        end
       
        // ------ START ------ //
        rst = 1; oper = START;  #(CYCLES * PERIOD); // START
        
        while(!end_op[0]) #(CYCLES * PERIOD);
        
        #(CYCLES * 10 * PERIOD);
        
        // ---- READ PK ---- //
        rst = 1; oper = READ_PK;  #(CYCLES * PERIOD); // READ_PK
        for (i = 0; i < LEN_EK / 8; i = i + 1) begin
            add                 = i;                #(CYCLES * PERIOD);                                                                  
            ek_array[8*i + 0] = r_out[07:00];     
            ek_array[8*i + 1] = r_out[15:08]; 
            ek_array[8*i + 2] = r_out[23:16];     
            ek_array[8*i + 3] = r_out[31:24];        
            ek_array[8*i + 4] = r_out[39:32];     
            ek_array[8*i + 5] = r_out[47:40]; 
            ek_array[8*i + 6] = r_out[55:48];     
            ek_array[8*i + 7] = r_out[63:56]; 
            #(CYCLES * PERIOD);
        end
        rst = 1; oper = READ_SK;  #(CYCLES * PERIOD); // READ_SK
        for (i = 0; i < (LEN_DK / 8); i = i + 1) begin
            add                 = i + (LEN_EK / 8);                #(CYCLES * PERIOD);                                                                  
            dk_array[8*i + 0] = r_out[07:00];     
            dk_array[8*i + 1] = r_out[15:08]; 
            dk_array[8*i + 2] = r_out[23:16];     
            dk_array[8*i + 3] = r_out[31:24];        
            dk_array[8*i + 4] = r_out[39:32];     
            dk_array[8*i + 5] = r_out[47:40]; 
            dk_array[8*i + 6] = r_out[55:48];     
            dk_array[8*i + 7] = r_out[63:56]; 
            #(CYCLES * PERIOD);
        end

        
        if (VERBOSE >= 2) begin
            // ---- PRINT ek ---- //
            $write("\n");
            for (i = 0; i < LEN_EK; i = i + 1) begin
                if(i % 32 == 0) $write("\n");
                $write("%02x",ek_array[i]);
            end
            // ---- PRINT dk ---- //
            $write("\n");
            for (i = 0; i < LEN_DK; i = i + 1) begin
                if(i % 32 == 0) $write("\n");
                $write("%02x",dk_array[i]);
            end
        end
        
        
        // ----------------------------- //
        // -------- ENCRYPTION --------  //
        // ----------------------------- //
        if(K == 2) mode = ENCAP_512;
        if(K == 3) mode = ENCAP_768;
        if(K == 4) mode = ENCAP_1024;
        
        if(K == 2) LEN_CT = 768;
        if(K == 3) LEN_CT = 1088;
        if(K == 4) LEN_CT = 1568;
         
        // ------ LOAD_EK ------ //
        rst = 1; oper = RESET; #(CYCLES * 10 * PERIOD); // INIT MO
        rst = 1; oper = LOAD_PK;  #(CYCLES * PERIOD); // LOAD PK
        for (i = 0; i < ((LEN_EK - 32) / 8); i = i + 1) begin
            add     = i;            #(CYCLES * PERIOD);
            r_in    = { ek_array[8*i+7], ek_array[8*i+6],
                        ek_array[8*i+5], ek_array[8*i+4],
                        ek_array[8*i+3], ek_array[8*i+2], 
                        ek_array[8*i+1], ek_array[8*i+0]};  #(CYCLES * PERIOD);
        end
        #(CYCLES * PERIOD);
        
        // ------ LOAD_SEED ------ //
        add_2   = (LEN_EK-32);
        rst = 1; oper = LOAD_COINS;  #(CYCLES*PERIOD); // LOAD SEED
        for (i = 0; i < 4; i = i + 1) begin
            add     = i;                                #(CYCLES*PERIOD);
            add_2   = 8*i + (LEN_EK-32);
            r_in    = { ek_array[add_2+7], ek_array[add_2+6],
                        ek_array[add_2+5], ek_array[add_2+4],
                        ek_array[add_2+3], ek_array[add_2+2], 
                        ek_array[add_2+1], ek_array[add_2+0]};
            #(CYCLES*PERIOD);
        end
        #(CYCLES*PERIOD);
        
        // ------ LOAD_M ------ //
        rst = 1; oper = LOAD_SS;  #(CYCLES * PERIOD); // LOAD SS
        for (i = 0; i < 4; i = i + 1) begin
            add     = i;             #(CYCLES*PERIOD);
            r_in    = m_array[i];    #(CYCLES*PERIOD);
        end
        #(CYCLES * PERIOD);
        
        // ----- START ----- //
        rst = 1; oper = START;  #(CYCLES*PERIOD); // START
        
        while(!end_op[0]) #(CYCLES*PERIOD);
        
        #(CYCLES*PERIOD);
        
        // ---- READ CIPHERTEXT ---- //
        rst = 1; oper = READ_CT;  #(CYCLES * PERIOD); // READ_CT
        for (i = 0; i < (LEN_CT / 8); i = i + 1) begin
            add                 = i;                #(CYCLES * PERIOD);                                                                  
            ct_array[8*i + 0] = r_out[07:00];     
            ct_array[8*i + 1] = r_out[15:08]; 
            ct_array[8*i + 2] = r_out[23:16];     
            ct_array[8*i + 3] = r_out[31:24];        
            ct_array[8*i + 4] = r_out[39:32];     
            ct_array[8*i + 5] = r_out[47:40]; 
            ct_array[8*i + 6] = r_out[55:48];     
            ct_array[8*i + 7] = r_out[63:56]; 
            #(CYCLES * PERIOD);
        end
        
        // ------ READ_SS ------ //
        rst = 1; oper = READ_SS;  #(CYCLES * PERIOD); // READ_SK
        for (i = 0; i < 4; i = i + 1) begin
            add                 = i + (LEN_CT / 8);                #(CYCLES * PERIOD);                                                                  
            ss_array[8*i + 0] = r_out[07:00];     
            ss_array[8*i + 1] = r_out[15:08]; 
            ss_array[8*i + 2] = r_out[23:16];     
            ss_array[8*i + 3] = r_out[31:24];        
            ss_array[8*i + 4] = r_out[39:32];     
            ss_array[8*i + 5] = r_out[47:40]; 
            ss_array[8*i + 6] = r_out[55:48];     
            ss_array[8*i + 7] = r_out[63:56]; 
            #(CYCLES * PERIOD);
        end
        
        // ---- PRINT CIPHERTEXT ---- //
        if(VERBOSE >= 2) begin
            $write("\n");
            for (i = 0; i < LEN_CT; i = i + 1) begin
                if(i % 32 == 0) $write("\n");
                $write("%02x",ct_array[i]);
            end
        end
        
        // ---- PRINT SS ---- //
        if(VERBOSE >= 1) begin
            $write("\n"); $write("\t K: %d \t TEST: %d", K, test);
            for (i = 0; i < 32; i = i + 1) begin
                if(i % 32 == 0) $write("\n");
                $write("%02x",ss_array[i]);
            end
        end
        
        // ----------------------------- //
        // -------- DECRYPTION --------  //
        // ----------------------------- //
        
        if(K == 2) mode = DECAP_512;
        if(K == 3) mode = DECAP_768;
        if(K == 4) mode = DECAP_1024;
        
        // ------ LOAD_DK ------ //
        
        LEN_PKE = LEN_DK - LEN_EK - 32 - 32;
        
        rst = 1; oper = RESET; #(CYCLES * PERIOD); // INIT MO
        rst = 1; oper = LOAD_SK;  #(CYCLES * PERIOD);    // LOAD SK
        for (i = 0; i < ((LEN_PKE) / 8); i = i + 1) begin
            add     = i;            #(CYCLES * PERIOD);
            r_in    = { dk_array[8*i+7], dk_array[8*i+6],
                        dk_array[8*i+5], dk_array[8*i+4],
                        dk_array[8*i+3], dk_array[8*i+2], 
                        dk_array[8*i+1], dk_array[8*i+0]};  #(CYCLES * PERIOD);
        end
        #(CYCLES * PERIOD);
        
        rst = 1; oper = LOAD_PK;  #(CYCLES * PERIOD);    // LOAD PK
        for (i = 0; i < ((LEN_PKE) / 8); i = i + 1) begin
            add     = i;            #(CYCLES * PERIOD);
            add_2   = 8*i + (LEN_PKE); 
            r_in    = { dk_array[add_2+7], dk_array[add_2+6],
                        dk_array[add_2+5], dk_array[add_2+4],
                        dk_array[add_2+3], dk_array[add_2+2], 
                        dk_array[add_2+1], dk_array[add_2+0]};  #(CYCLES * PERIOD);
        end
        #(CYCLES * PERIOD);
        
        // ---- LOAD CIPHERTEXT ---- //
        rst = 1; oper = LOAD_CT;  #(CYCLES * PERIOD); // LOAD CT
        for (i = 0; i < (LEN_CT/8); i = i + 1) begin
            add     = i;                                    #(CYCLES * PERIOD);
            r_in    = { ct_array[8*i+7], ct_array[8*i+6],
                        ct_array[8*i+5], ct_array[8*i+4],
                        ct_array[8*i+3], ct_array[8*i+2], 
                        ct_array[8*i+1], ct_array[8*i+0]};  #(CYCLES * PERIOD);
        end
        #(CYCLES * PERIOD);
        
        // ------ LOAD_SEED ------ //
        add_2   = (LEN_EK-32);
        rst = 1; oper = LOAD_COINS;  #(CYCLES*PERIOD); // LOAD SEED
        for (i = 0; i < 4; i = i + 1) begin
            add     = i;                                #(CYCLES*PERIOD);
            add_2   = 8*i + (LEN_DK - 32 - 32 - 32);
            r_in    = { dk_array[add_2+7], dk_array[add_2+6],
                        dk_array[add_2+5], dk_array[add_2+4],
                        dk_array[add_2+3], dk_array[add_2+2], 
                        dk_array[add_2+1], dk_array[add_2+0]};
            #(CYCLES*PERIOD);
        end
        #(CYCLES*PERIOD);
        
        // ------ LOAD_HEK ------ //
        rst = 1; oper = LOAD_HEK;  #(CYCLES * PERIOD);    // LOAD HK
        for (i = 0; i < 4; i = i + 1) begin
            add     = i;            #(CYCLES * PERIOD);
            add_2   = 8*i + (LEN_DK - 32 - 32);
            r_in    = { dk_array[add_2+7], dk_array[add_2+6],
                        dk_array[add_2+5], dk_array[add_2+4],
                        dk_array[add_2+3], dk_array[add_2+2], 
                        dk_array[add_2+1], dk_array[add_2+0]};  #(CYCLES * PERIOD);
        end
        #(CYCLES * PERIOD);
        
        // ------ LOAD_Z ------ //
        rst = 1; oper = LOAD_PS;  #(CYCLES * PERIOD);    // LOAD Z
        for (i = 0; i < 4; i = i + 1) begin
            add     = i;            #(CYCLES * PERIOD);
            add_2   = 8*i + (LEN_DK - 32);
            r_in    = { dk_array[add_2+7], dk_array[add_2+6],
                        dk_array[add_2+5], dk_array[add_2+4],
                        dk_array[add_2+3], dk_array[add_2+2], 
                        dk_array[add_2+1], dk_array[add_2+0]};  #(CYCLES * PERIOD);
        end
        #(CYCLES * PERIOD);
        
        // ----- START ----- //
        rst = 1; oper = START;  #(CYCLES * PERIOD); // START
        
        while(!end_op[0]) #(CYCLES * PERIOD);
        
        #(CYCLES * 10 * PERIOD);
        
        // ---- READ SS ---- //
        rst = 1; oper = READ_SS;  #(CYCLES * PERIOD); // READ SS
        for (i = 0; i < 4; i = i + 1) begin
            add                 = i;                #(CYCLES * PERIOD);                                                                  
            ss2_array[8*i + 0] = r_out[07:00];     
            ss2_array[8*i + 1] = r_out[15:08]; 
            ss2_array[8*i + 2] = r_out[23:16];     
            ss2_array[8*i + 3] = r_out[31:24];        
            ss2_array[8*i + 4] = r_out[39:32];     
            ss2_array[8*i + 5] = r_out[47:40]; 
            ss2_array[8*i + 6] = r_out[55:48];     
            ss2_array[8*i + 7] = r_out[63:56]; 
            #(CYCLES * PERIOD);
        end
        
        // ---- PRINT SS ---- //
        comp = 0; 
        if(VERBOSE >= 1) begin
            for (i = 0; i < 32; i = i + 1) begin
                if(ss_array[i] != ss2_array[i]) comp = 1; 
                
                if(i % 32 == 0) $write("\n");
                $write("%02x",ss2_array[i]);
            end
            
            if(comp) $write("\t COMP: FAIL");
            else     $write("\t COMP: OK");
            
            if(end_op == 2'b01) $write("\t RESULT: FAIL");
            else $write("\t RESULT: OK");
        end
        end
    endtask
    
endmodule

