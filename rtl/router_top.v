module router_top(clock,resetn,data_in,read_enb_0,read_enb_1,read_enb_2,pkt_valid,data_out_0,data_out_1,data_out_2,vld_out_0,vld_out_1,vld_out_2,err,busy);

input clock,resetn,pkt_valid,read_enb_0,read_enb_1,read_enb_2;
input [7:0]data_in;

output vld_out_0,vld_out_1,vld_out_2,err,busy;
output [7:0] data_out_0,data_out_1,data_out_2;

wire [2:0] write_enb;
wire full_0,empty_0,soft_reset_0;
wire full_1,empty_1,soft_reset_1;
wire full_2,empty_2,soft_reset_2;
wire lfd_state, ld_state, laf_state, full_state;
wire detect_add, write_enb_reg, rst_int_reg;
wire fifo_full, parity_done, low_pkt_valid;
wire [7:0] dout;

router_fifo f1(.clock(clock),.resetn(resetn),.data_in(dout),.read_enb(read_enb_0),.write_enb(write_enb[0]),.data_out(data_out_0),.empty(empty_0),.full(full_0),.lfd_state(lfd_state),.soft_reset(soft_reset_0));
router_fifo f2(.clock(clock),.resetn(resetn),.data_in(dout),.read_enb(read_enb_1),.write_enb(write_enb[1]),.data_out(data_out_1),.empty(empty_1),.full(full_1),.lfd_state(lfd_state),.soft_reset(soft_reset_1));
router_fifo f3(.clock(clock),.resetn(resetn),.data_in(dout),.read_enb(read_enb_2),.write_enb(write_enb[2]),.data_out(data_out_2),.empty(empty_2),.full(full_2),.lfd_state(lfd_state),.soft_reset(soft_reset_2));

router_sync s1(.clock(clock),.resetn(resetn),.detect_add(detect_add),.full_0(full_0),.full_1(full_1),.full_2(full_2),.data_in(data_in[1:0]),.empty_0(empty_0),.empty_1(empty_1),.empty_2(empty_2),.write_enb_reg(write_enb_reg),.read_enb_0(read_enb_0),.read_enb_1(read_enb_1),.read_enb_2(read_enb_2),.fifo_full(fifo_full),.vld_out_0(vld_out_0),.vld_out_1(vld_out_1),.vld_out_2(vld_out_2),.soft_reset_0(soft_reset_0),.soft_reset_1(soft_reset_1),.soft_reset_2(soft_reset_2),.write_enb(write_enb));

router_fsm fsm1(.clock(clock),.resetn(resetn),.pkt_vld(pkt_valid),.fifo_full(fifo_full),.fifo_emtpy_0(empty_0),.fifo_emtpy_1(empty_1),.fifo_emtpy_2(empty_2),.soft_reset_0(soft_reset_0),.soft_reset_1(soft_reset_1),.soft_reset_2(soft_reset_2),.data_in(data_in[1:0]),.parity_done(parity_done),.low_packet_valid(low_pkt_valid),.wirte_enb_reg(write_enb_reg),.detect_add(detect_add),.ld_state(ld_state),.laf_state(laf_state),.lfd_state(lfd_state),.full_state(full_state),.rst_int_reg(rst_int_reg),.busy(busy));

router_register r1(.clock(clock),.resetn(resetn),.lfd_state(lfd_state),.rst_int_reg(rst_int_reg),.pkt_vld(pkt_valid),.fifo_full(fifo_full),.detect_add(detect_add),.ld_state(ld_state),.laf_state(laf_state),.full_state(full_state),.data_in(data_in),.error(err),.low_packet_valid(low_pkt_valid),.parity_done(parity_done),.dout(dout));

endmodule