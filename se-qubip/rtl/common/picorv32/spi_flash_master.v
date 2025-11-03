////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 21/10/2025
// Design Name: spi_flash_master.v
// Module Name: spi_flash_master
// Project Name: SE-QUBIP
// Target Devices: ZCU104
// Tool Versions: Vivado 2024.1.2
// Description: 
//		
//		Firmware-driven SPI Flash Master for the PicoSoC
//
////////////////////////////////////////////////////////////////////////////////////

module spi_flash_master (
                         // PicoSoC Bus Interface
                         input  wire         clk,
                         input  wire         resetn,
                         input  wire         sel,         // Peripheral is selected
                         input  wire         write,       // Bus write cycle
                         input  wire [7:0]   addr,        // Register address offset
                         input  wire [31:0]  wdata,       // Write data from CPU
                         output reg  [31:0]  rdata,       // Read data to CPU
                         output reg          valid,       // Valid signal to CPU
                     
                         // Pmod SF3 Interface
                         output reg          spi_sclk,
                         output wire         spi_csn,
                         output wire         spi_dq0_o,   // MOSI
                         input  wire         spi_dq1_i    // MISO
                         );

    //================================================================
    // Register Addresses (Byte offsets from peripheral base)
    //================================================================
    localparam SPI_CMD      = 8'hDC;
    localparam SPI_CONFIG   = 8'hE0;
    localparam SPI_DATA     = 8'hE4;

    //================================================================
    // Internal Registers and Buffers
    //================================================================
    // Configuration and Control
    reg [2:0]  reg_tx_len;          // Bytes to transmit from buffer (0-4)
    reg [4:0]  reg_dummy_cycles;    // Dummy CLOCK CYCLES to wait (0-31)
    reg [2:0]  reg_rx_len;          // Bytes to receive into buffer (0-4)
    reg [7:0]  reg_clk_div;         // SCLK = clk / (2 * (clk_div+1))
    reg        reg_csn_manual;      // Firmware's direct control over CS

    assign spi_csn = reg_csn_manual;

    //================================================================
    // FSM and Datapath
    //================================================================
    localparam FSM_IDLE         = 3'd0;
    localparam FSM_TX_BYTE      = 3'd1;
    localparam FSM_DUMMY_CYCLE  = 3'd2;
    localparam FSM_RX_BYTE      = 3'd3;
    
    reg [2:0]  state;
    reg        go_busy; // Single-cycle 'go' trigger

    // Counters and Shifters
    reg [2:0]  byte_count;
    reg [2:0]  bit_count;
    reg [4:0]  dummy_cycle_count;
    reg [7:0]  sclk_div_count;
    reg [7:0]  tx_shifter;
    reg [7:0]  rx_shifter;
    reg [31:0] read_buffer;
    reg [31:0] write_buffer;

    assign spi_dq0_o = tx_shifter[7];

    // --- SCLK Generation ---
    always @(posedge clk) begin
        if (!resetn || state == FSM_IDLE) begin
            sclk_div_count  <= 0;
            spi_sclk        <= 1'b0; // SPI Mode 0: Clock is idle LOW
        end 
        else if (!reg_csn_manual) begin // Only generate clock when CS is active
            if (sclk_div_count == reg_clk_div) begin
                spi_sclk        <= ~spi_sclk;
                sclk_div_count  <= 0;
            end 
            else begin
                sclk_div_count <= sclk_div_count + 1;
            end
        end
    end

    // Edge Detection
    wire sclk_posedge = (sclk_div_count == reg_clk_div) ? ~spi_sclk : 0;
    wire sclk_negedge = (sclk_div_count == reg_clk_div) ?  spi_sclk : 0;

    // --- Main FSM ---
    always @(posedge clk) begin
        if (!resetn) begin
            byte_count          <= 0;
            bit_count           <= 0;
            dummy_cycle_count   <= 0;
            tx_shifter          <= 0;
            rx_shifter          <= 0;
            read_buffer         <= 0;
            valid               <= 0;
            state               <= FSM_IDLE;
        end 
        else begin
            case (state)
                FSM_IDLE: begin
                    valid <= 0;
                    if (go_busy && !reg_csn_manual) begin
                        byte_count        <= 0;
                        bit_count         <= 0;
                        dummy_cycle_count <= 0;
                        tx_shifter        <= write_buffer[31:24]; // Pre-load first byte
                        if (reg_tx_len > 0)
                            state <= FSM_TX_BYTE;
                        else if (reg_dummy_cycles > 0)
                            state <= FSM_DUMMY_CYCLE;
                        else if (reg_rx_len > 0)
                            state <= FSM_RX_BYTE;
                    end
                end
                
                FSM_TX_BYTE: begin
                    if (byte_count < reg_tx_len) begin
                        if (sclk_negedge) begin
                            if (bit_count == 3'd7) begin
                                bit_count  <= 0;
                                byte_count <= byte_count + 1;
                                tx_shifter <= write_buffer[(2-byte_count)*8+:8];
                            end 
                            else begin
                                bit_count   <= bit_count + 1;
                                tx_shifter  <= {tx_shifter[6:0], 1'b0};
                            end
                        end
                    end 
                    else begin // TX phase is done, transition to next phase
                        byte_count <= 0;
                        bit_count  <= 0;
                        if (reg_dummy_cycles > 0)
                            state <= FSM_DUMMY_CYCLE;
                        else if (reg_rx_len > 0)
                            state <= FSM_RX_BYTE;
                        else begin
                            valid <= 1;
                            state <= FSM_IDLE;
                        end
                    end
                end

                FSM_DUMMY_CYCLE: begin
                    if (dummy_cycle_count < reg_dummy_cycles) begin
                        if (sclk_posedge) begin // We can just count any edge
                            dummy_cycle_count <= dummy_cycle_count + 1;
                        end
                    end 
                    else begin // Dummy phase done
                        byte_count <= 0;
                        bit_count  <= 0;
                        if (reg_rx_len > 0) 
                            state <= FSM_RX_BYTE;
                        else begin
                            valid <= 1;
                            state <= FSM_IDLE;
                        end
                    end
                end

                FSM_RX_BYTE: begin
                    if (byte_count < reg_rx_len) begin
                        if (sclk_posedge) begin
                            rx_shifter <= {rx_shifter[6:0], spi_dq1_i};
                            if (bit_count == 3'd7) begin
                                case (byte_count[1:0])
                                    2'd0: read_buffer[31:24] <= {rx_shifter[6:0], spi_dq1_i};
                                    2'd1: read_buffer[23:16] <= {rx_shifter[6:0], spi_dq1_i};
                                    2'd2: read_buffer[15: 8] <= {rx_shifter[6:0], spi_dq1_i};
                                    2'd3: read_buffer[ 7: 0] <= {rx_shifter[6:0], spi_dq1_i};
                                endcase
                                bit_count  <= 0;
                                byte_count <= byte_count + 1;
                            end 
                            else begin
                                bit_count <= bit_count + 1;
                            end
                        end
                    end 
                    else begin  // RX phase done
                        byte_count  <= 0;
                        bit_count   <= 0;
                        valid       <= 1;
                        state       <= FSM_IDLE;
                    end
                end
            endcase
        end
    end

    //================================================================
    // Memory-Mapped Register Access
    //================================================================

    reg sel_and_write_last;
    always @(posedge clk) begin
        if (!resetn) begin
            sel_and_write_last <= 1'b0;
        end 
        else begin
            sel_and_write_last <= sel && write;
        end
    end

    wire is_new_write = (sel && write) && !sel_and_write_last;

    always @(posedge clk) begin
        
        if (!resetn) begin
            go_busy             <= 0;
            reg_tx_len          <= 0;
            reg_dummy_cycles    <= 0;
            reg_rx_len          <= 0;
            reg_clk_div         <= 0;
            reg_csn_manual      <= 1;
            write_buffer        <= 0;
        end
        else begin
            go_busy <= 1'b0; // Default to a one-shot pulse

            // Use the edge detector 'is_new_write' as the primary condition
            if (is_new_write && (addr == SPI_CMD)) begin
                go_busy <= 1'b1;
            end

            if (sel && write) begin
                case (addr)
                    SPI_CMD: begin
                        reg_tx_len          <= wdata[18:16];
                        reg_dummy_cycles    <= wdata[12:8];
                        reg_rx_len          <= wdata[2:0];
                    end
                    SPI_CONFIG: begin
                        reg_clk_div     <= wdata[7:0];
                        reg_csn_manual  <= wdata[8];
                    end
                    SPI_DATA: write_buffer <= wdata;
                endcase
            end
        end
    end

    always @(*) begin
        rdata = 32'h0;
        if (sel && !write) begin
            case (addr)
                SPI_CMD:    rdata = {13'b0, reg_tx_len, 3'b0, reg_dummy_cycles, 5'b0, reg_rx_len};
                SPI_CONFIG: rdata = {23'b0, reg_csn_manual, reg_clk_div};
                SPI_DATA:   rdata = read_buffer;
                default:    rdata = 32'hDEADBEEF;
            endcase
        end
    end

endmodule