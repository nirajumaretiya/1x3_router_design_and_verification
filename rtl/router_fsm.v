module router_fsm (
    input clock, resetn, pkt_vld, fifo_full,
    input fifo_emtpy_0, fifo_emtpy_1, fifo_emtpy_2,
    input soft_reset_0, soft_reset_1, soft_reset_2,
    input [1:0] data_in,
    input parity_done, low_packet_valid,

    output wirte_enb_reg, detect_add, ld_state,
    output laf_state, lfd_state, full_state,
    output rst_int_reg, busy
);

parameter DECODE_ADDRESS   = 3'b000,
          LOAD_FIRST_DATA  = 3'b001,
          WAIT_TILL_EMPTY  = 3'b010,
          LOAD_DATA        = 3'b011,
          LOAD_PARITY      = 3'b100,
          FIFO_FULL_STATE  = 3'b101,
          LOAD_AFTER_FULL  = 3'b110,
          CHECK_PARITY_ERR = 3'b111;

reg [2:0] present_state, next_state;

always @(posedge clock) begin
    if (~resetn)
        present_state <= DECODE_ADDRESS;
    else if (soft_reset_0 || soft_reset_1 || soft_reset_2)
        present_state <= DECODE_ADDRESS;
    else
        present_state <= next_state;
end

always @(*) begin
    next_state = present_state;   
    case (present_state)

        DECODE_ADDRESS: begin
            if ((pkt_vld && data_in==2'd0 && fifo_emtpy_0) ||
                (pkt_vld && data_in==2'd1 && fifo_emtpy_1) ||
                (pkt_vld && data_in==2'd2 && fifo_emtpy_2))
                next_state = LOAD_FIRST_DATA;
            else if ((pkt_vld && data_in==2'd0 && ~fifo_emtpy_0) ||
                     (pkt_vld && data_in==2'd1 && ~fifo_emtpy_1) ||
                     (pkt_vld && data_in==2'd2 && ~fifo_emtpy_2))
                next_state = WAIT_TILL_EMPTY;
        end

        LOAD_FIRST_DATA: next_state = LOAD_DATA;

        WAIT_TILL_EMPTY: begin
            if (fifo_emtpy_0 || fifo_emtpy_1 || fifo_emtpy_2)
                next_state = LOAD_FIRST_DATA;
            else
                next_state = WAIT_TILL_EMPTY;
        end

        LOAD_DATA: begin
            if (fifo_full)
                next_state = FIFO_FULL_STATE;
            else if (!fifo_full && !pkt_vld)
                next_state = LOAD_PARITY;
        end

        LOAD_PARITY: next_state = CHECK_PARITY_ERR;

        FIFO_FULL_STATE: begin
            if (!fifo_full)
                next_state = LOAD_AFTER_FULL;
            else
                next_state = FIFO_FULL_STATE;
        end

        LOAD_AFTER_FULL: begin
            if (!parity_done && low_packet_valid)
                next_state = LOAD_PARITY;
            else if (!parity_done && !low_packet_valid)
                next_state = LOAD_DATA;
            else if (parity_done)
                next_state = DECODE_ADDRESS;
        end

        CHECK_PARITY_ERR: begin
            if (!fifo_full)
                next_state = DECODE_ADDRESS;
            else
                next_state = FIFO_FULL_STATE;
        end

    endcase
end

// Output Logic

assign detect_add   = (present_state == DECODE_ADDRESS);
assign lfd_state    = (present_state == LOAD_FIRST_DATA);
assign busy         = (present_state==LOAD_FIRST_DATA) ||
                      (present_state==LOAD_PARITY) ||
                      (present_state==FIFO_FULL_STATE) ||
                      (present_state==LOAD_AFTER_FULL) ||
                      (present_state==WAIT_TILL_EMPTY) ||
                      (present_state==CHECK_PARITY_ERR);
assign ld_state     = (present_state == LOAD_DATA);
assign wirte_enb_reg= (present_state==LOAD_DATA) ||
                      (present_state==LOAD_PARITY) ||
                      (present_state==LOAD_AFTER_FULL);
assign full_state   = (present_state == FIFO_FULL_STATE);
assign laf_state    = (present_state == LOAD_AFTER_FULL);
assign rst_int_reg  = (present_state == CHECK_PARITY_ERR);

endmodule
