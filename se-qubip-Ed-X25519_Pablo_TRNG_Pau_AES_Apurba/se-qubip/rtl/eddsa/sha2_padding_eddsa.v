`timescale 1ns / 1ps

module sha2_padding #(
    parameter WIDTH = 32,
    parameter MODE = 256
    )(
    input wire                  clk,
    input wire                  rst,
    input wire [3:0]            control,
    input wire [4:0]            ad_in,
    input wire [WIDTH-1:0]      data_in,
    output wire [WIDTH-1:0]     data_out
    );
    
    reg     [2*WIDTH-1:0] LENGTH;
    reg     [2*WIDTH-1:0] LENGTH_BLOCK;
    wire    [2*WIDTH-1:0] LENGTH_CURRENT;
    
    assign LENGTH_CURRENT = LENGTH_BLOCK - (ad_in * WIDTH);
    
    wire reset;
    wire load;
    wire start;
    assign reset    = ~control[0] & rst;
    assign load     =  control[1];
    assign start    =  control[2];
    
    wire load_length;
    assign load_length = control[3];
    
    reg  [WIDTH-1:0]     data_out_reg;
    assign data_out = data_out_reg;
    
    reg save_length;
    reg flag;
    
    always @(posedge clk) begin
        if(!reset) save_length <= 0;
        else begin
            if(start & !flag)       save_length <= 1;
            else if(start & flag)   save_length <= 0;
            else                    save_length <= save_length;
        end
    end
    
    always @(posedge clk) begin
        if(!reset) flag <= 0;
        else begin
            if(load)                flag <= 0;
            else if(save_length)    flag <= 1;
            else                    flag <= flag;
        end
    end
    
    generate
        if(MODE == 224 | MODE == 256) begin
            localparam BLOCK_SIZE = 512;
            
            always @(posedge clk) begin
                if(!reset) LENGTH_BLOCK <= 0;
                else begin
                    if(load_length)                         LENGTH_BLOCK <= LENGTH;
                    else if(start & save_length & !flag)    LENGTH_BLOCK <= LENGTH_BLOCK - BLOCK_SIZE;
                    else                                    LENGTH_BLOCK <= LENGTH_BLOCK;
                end
            end
            
            wire [2:0] control_pad;
            assign control_pad[0] = ((LENGTH_BLOCK + 2*WIDTH)   < BLOCK_SIZE) ? 1 : 0;
            assign control_pad[1] = (LENGTH_CURRENT             < WIDTH)      ? 1 : 0;
            assign control_pad[2] = (LENGTH_CURRENT             < 0)          ? 1 : 0; 
            
            wire [2:0] condition;
            assign condition[0] = control_pad[0] & (ad_in == 4'b1110); // OUTPUT LENGTH 1
            assign condition[1] = control_pad[0] & (ad_in == 4'b1111); // OUTPUT LENGTH 2
            assign condition[2] = control_pad[1];
            
            always @* begin
                if      (condition[0]) data_out_reg = LENGTH[2*WIDTH-1:WIDTH];
                else if (condition[1]) data_out_reg = LENGTH[WIDTH-1:0];
                else if (condition[2]) data_out_reg = data_in + (1'b1 << (WIDTH - 1 - LENGTH_CURRENT));
                else                   data_out_reg = data_in;
            end
            
        end
        else if(MODE == 384 | MODE == 512) begin
            localparam BLOCK_SIZE = 1024;

            always @(posedge clk) begin
                if(!reset) LENGTH_BLOCK <= 0;
                else begin
                    if(load_length)                         LENGTH_BLOCK <= LENGTH;
                    else if(start & save_length & !flag)    LENGTH_BLOCK <= LENGTH_BLOCK - BLOCK_SIZE;
                    else                                    LENGTH_BLOCK <= LENGTH_BLOCK;
                end
            end
            
            wire [2:0] control_pad;
            assign control_pad[0] = ((LENGTH_BLOCK + 2*WIDTH)   < BLOCK_SIZE) ? 1 : 0;
            assign control_pad[1] = (LENGTH_CURRENT             < WIDTH)      ? 1 : 0;
            assign control_pad[2] = (LENGTH_CURRENT             < 0)          ? 1 : 0; 
            
            wire [2:0] condition;
            assign condition[0] = control_pad[0] & (ad_in == 4'b1110); // OUTPUT LENGTH 1
            assign condition[1] = control_pad[0] & (ad_in == 4'b1111); // OUTPUT LENGTH 2
            assign condition[2] = control_pad[1];
            
            always @* begin
                if      (condition[0]) data_out_reg = LENGTH[2*WIDTH-1:WIDTH];
                else if (condition[1]) data_out_reg = LENGTH[WIDTH-1:0];
                else if (condition[2]) data_out_reg = data_in + (1'b1 << (WIDTH - 1 - LENGTH_CURRENT));
                else                   data_out_reg = data_in;
            end
            
        end
        else begin
            localparam BLOCK_SIZE = 512;
            
            always @(posedge clk) begin
                if(!reset) LENGTH_BLOCK <= 0;
                else begin
                    if(load_length)                         LENGTH_BLOCK <= LENGTH;
                    else if(start & save_length & !flag)    LENGTH_BLOCK <= LENGTH_BLOCK - BLOCK_SIZE;
                    else                                    LENGTH_BLOCK <= LENGTH_BLOCK;
                end
            end
            
            wire [2:0] control_pad;
            assign control_pad[0] = ((LENGTH_BLOCK + 2*WIDTH)   < BLOCK_SIZE) ? 1 : 0;
            assign control_pad[1] = (LENGTH_CURRENT             < WIDTH)      ? 1 : 0;
            assign control_pad[2] = (LENGTH_CURRENT             < 0)          ? 1 : 0; 
            
            wire [2:0] condition;
            assign condition[0] = control_pad[0] & (ad_in == 4'b1110); // OUTPUT LENGTH 1
            assign condition[1] = control_pad[0] & (ad_in == 4'b1111); // OUTPUT LENGTH 2
            assign condition[2] = control_pad[1];
            
            always @* begin
                if      (condition[0]) data_out_reg = LENGTH[2*WIDTH-1:WIDTH];
                else if (condition[1]) data_out_reg = LENGTH[WIDTH-1:0];
                else if (condition[2]) data_out_reg = data_in + (1'b1 << (WIDTH - 1 - LENGTH_CURRENT));
                else                   data_out_reg = data_in;
            end            
        end
  
    endgenerate
    
    always @(posedge clk) begin
        if(!reset)              LENGTH <= 0;
        else begin
            if(load_length & ad_in[0])         LENGTH[WIDTH-1:0]       <= data_in;
            else if(load_length & !ad_in[0])   LENGTH[2*WIDTH-1:WIDTH] <= data_in;
            else                               LENGTH                  <= LENGTH;
        end
    end
    
    
endmodule
