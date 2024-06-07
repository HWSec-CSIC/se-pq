`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.03.2024 12:07:10
// Design Name: 
// Module Name: tb_sha3
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_sha3(
    
    );
    
  parameter PERIOD = 10;
  parameter D_WIDTH = 64;
  
    // Declaración de señales para conectar con el DUT (Device Under Test)
  reg                   clk;
  reg                   rst; 
  reg   [D_WIDTH-1:0]   data_in;
  reg   [7:0]           add;
  reg   [3:0]           control;
  wire  [D_WIDTH-1:0]   data_out;
  wire                  end_op;

  // Instanciación del DUT
  sha3_xl sha3_xl (
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .add(add),
    .control(control),
    .data_out(data_out),
    .end_op(end_op)
  );

  integer i;
  
    reg [D_WIDTH - 1:0] MEM_IN [0:24];
    reg [D_WIDTH - 1:0] LEN;
  // Bloque de inicialización para las señales de prueba
  initial begin
    LEN = 64;
    MEM_IN[0] = 64'hb2cfa3f83ffa53af; 
    MEM_IN[1] = 0;
    MEM_IN[2] = 0;
    MEM_IN[3] = 0;
    MEM_IN[4] = 0;
    MEM_IN[5] = 0; 
    MEM_IN[6] = 0;
    MEM_IN[7] = 0;
    MEM_IN[8] = 0;
    MEM_IN[9] = 0;
    MEM_IN[10] = 0;
    MEM_IN[11] = 0;
    MEM_IN[12] = 0;
    MEM_IN[13] = 0;
    MEM_IN[14] = 0;
    MEM_IN[15] = 0; 
    MEM_IN[16] = 0;
    MEM_IN[17] = 0;
    MEM_IN[18] = 0;
    MEM_IN[19] = 0;
    MEM_IN[20] = 0;
    MEM_IN[21] = 0;
    MEM_IN[22] = 0;
    MEM_IN[23] = 0;
    MEM_IN[24] = 0;
       
    rst = 1; control = 4'b0100; add = 0; data_in = 0; #(10*PERIOD);
    rst = 0; control = 4'b0100; add = 0; data_in = 0; #(10*PERIOD);
    rst = 1; control = 4'b0100; add = 0; data_in = 0; #(10*PERIOD);
    rst = 1; control = 4'b0101; add = 0; data_in = LEN / 8; #(5*PERIOD); // Load length
    
    for (i = 0; i < 25; i = i + 1) begin
        rst = 1; control = 4'b0110; add = i; data_in = MEM_IN[i]; #(PERIOD); // Load add
        rst = 1; control = 4'b0110; add = i; data_in = MEM_IN[i]; #(PERIOD); // Load data
    end
    
    rst = 1; control = 4'b0111; add = 0; data_in = 0; #(PERIOD); // Load data

  end
  
  // Generación de la señal de reloj
  initial begin
    clk = 0;
    forever #(PERIOD) clk = ~clk; // Cambia el estado del reloj cada 5 unidades de tiempo
  end
endmodule
