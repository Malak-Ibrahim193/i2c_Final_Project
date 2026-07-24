`timescale 1ns / 1ps

module tb_i2c_master();

    reg        clk_i;
    reg        rst_i;
    reg        m_w_r_i;
    reg        m_start_i;
    reg        m_stop_i;
    reg  [6:0] m_slv_add_i;
    reg  [7:0] m_data_i;
    reg        m_ack_i;

    wire [7:0] m_data_o;
    wire       m_busy_o;
    wire       m_error_o;
    wire       m_data_ready_o;

    wire       sda;
    wire       scl;

    reg drive_sda;
    reg sda_val;

    pullup(sda);
    pullup(scl);

    assign sda = (drive_sda) ? sda_val : 1'bz;

    i2c_master dut (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .m_w_r_i(m_w_r_i),
        .m_start_i(m_start_i),
        .m_stop_i(m_stop_i),
        .m_slv_add_i(m_slv_add_i),
        .m_data_i(m_data_i),
        .m_ack_i(m_ack_i),
        .m_data_o(m_data_o),
        .m_busy_o(m_busy_o),
        .m_error_o(m_error_o),
        .m_data_ready_o(m_data_ready_o),
        .sda(sda),
        .scl(scl)
    );

    always #10 clk_i = ~clk_i;

    initial begin
        clk_i       = 0;
        rst_i       = 1;
        m_w_r_i     = 0;
        m_start_i   = 0;
        m_stop_i    = 0;
        m_slv_add_i = 7'h00;
        m_data_i    = 8'h00;
        m_ack_i     = 0;
        drive_sda   = 0;
        sda_val     = 0;

        #40;
        rst_i = 0;
        #40;

        // Write Operation 
        m_slv_add_i = 7'h3A;
        m_w_r_i     = 1'b0;
        m_data_i    = 8'hA5;
        m_start_i   = 1'b1;
        #20;
        m_start_i   = 1'b0;

        // Drive Slave ACK on Address Phase
        #180;
        drive_sda = 1'b1; sda_val = 1'b0;
        #20;
        drive_sda = 1'b0;

        // Drive Slave ACK on Data Phase
        #160;
        drive_sda = 1'b1; 
        drive_sda = 1'b1; sda_val = 1'b0;
        #20;
        drive_sda = 1'b0;

        m_stop_i = 1'b1;
        #40;
        m_stop_i = 1'b0;

        #200;
        $display("DONE");
        $finish;
    end

endmodule