`timescale 1ns / 1ps

module i2c_master (
    input  wire       clk_i,
    input  wire       rst_i,
    input  wire       m_w_r_i,
    input  wire       m_start_i,
    input  wire       m_stop_i,
    input  wire [6:0] m_slv_add_i,
    input  wire [7:0] m_data_i,
    input  wire       m_ack_i,
    output reg  [7:0] m_data_o,
    output reg        m_busy_o,
    output reg        m_error_o,
    output reg        m_data_ready_o,
    inout  wire       sda,
    inout  wire       scl
);

    parameter IDLE      = 3'd0;
    parameter START     = 3'd1;
    parameter ADDR      = 3'd2;
    parameter ACK_ADDR  = 3'd3;
    parameter WRITE     = 3'd4;
    parameter READ      = 3'd5;
    parameter ACK_DATA  = 3'd6;
    parameter STOP      = 3'd7;

    reg [2:0] state;
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;
    reg       sda_out;
    reg       scl_out;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            state          <= IDLE;
            bit_cnt        <= 3'd7;
            shift_reg      <= 8'd0;
            sda_out        <= 1'b1;
            scl_out        <= 1'b1;
            m_busy_o       <= 1'b0;
            m_error_o      <= 1'b0;
            m_data_ready_o <= 1'b0;
            m_data_o       <= 8'd0;
        end else begin
            m_data_ready_o <= 1'b0;

            case (state)
                IDLE: begin
                    m_busy_o  <= 1'b0;
                    sda_out   <= 1'b1;
                    scl_out   <= 1'b1;
                    m_error_o <= 1'b0;
                    if (m_start_i) begin
                        state     <= START;
                        shift_reg <= {m_slv_add_i, m_w_r_i};
                        m_busy_o  <= 1'b1;
                    end
                end

                START: begin
                    sda_out <= 1'b0;
                    scl_out <= 1'b1;
                    bit_cnt <= 3'd7;
                    state   <= ADDR;
                end

                ADDR: begin
                    scl_out <= 1'b0;
                    sda_out <= shift_reg[bit_cnt];
                    if (bit_cnt == 3'd0) begin
                        state <= ACK_ADDR;
                    end else begin
                        bit_cnt <= bit_cnt - 1'b1;
                    end
                end

                ACK_ADDR: begin
                    scl_out <= 1'b1;
                    sda_out <= 1'b1;
                    if (sda == 1'b0) begin
                        bit_cnt <= 3'd7;
                        if (shift_reg[0] == 1'b0) begin
                            shift_reg <= m_data_i;
                            state     <= WRITE;
                        end else begin
                            state     <= READ;
                        end
                    end else begin
                        m_error_o <= 1'b1;
                        state     <= STOP;
                    end
                end

                WRITE: begin
                    scl_out <= 1'b0;
                    sda_out <= shift_reg[bit_cnt];
                    if (bit_cnt == 3'd0) begin
                        state <= ACK_DATA;
                    end else begin
                        bit_cnt <= bit_cnt - 1'b1;
                    end
                end

                READ: begin
                    scl_out <= 1'b0;
                    sda_out <= 1'b1;
                    shift_reg[bit_cnt] <= sda;
                    if (bit_cnt == 3'd0) begin
                        m_data_o       <= {shift_reg[7:1], sda};
                        m_data_ready_o <= 1'b1;
                        state          <= ACK_DATA;
                    end else begin
                        bit_cnt <= bit_cnt - 1'b1;
                    end
                end

                ACK_DATA: begin
                    scl_out <= 1'b1;
                    if (m_w_r_i == 1'b1) begin
                        sda_out <= m_ack_i;
                    end else begin
                        sda_out <= 1'b1;
                    end

                    if (m_stop_i || m_error_o) begin
                        state <= STOP;
                    end else begin
                        bit_cnt <= 3'd7;
                        if (m_w_r_i == 1'b0) shift_reg <= m_data_i;
                        state   <= (m_w_r_i) ? READ : WRITE;
                    end
                end

                STOP: begin
                    sda_out <= 1'b0;
                    scl_out <= 1'b1;
                    state   <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

    assign sda = (sda_out == 1'b0) ? 1'b0 : 1'bz;
    assign scl = (scl_out == 1'b0) ? 1'b0 : 1'bz;

endmodule