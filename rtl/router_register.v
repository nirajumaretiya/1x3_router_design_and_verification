module router_register(clock,resetn,lfd_state,rst_int_reg,pkt_vld,fifo_full,detect_add,ld_state,laf_state,full_state,data_in,error,low_packet_valid,parity_done,dout);

input clock,resetn,lfd_state,rst_int_reg,pkt_vld,fifo_full,detect_add,ld_state,laf_state,full_state;
input [7:0] data_in;

output reg error,low_packet_valid,parity_done;
output reg [7:0] dout;
reg [7:0] full_state_byte,internal_parity,header,packet_parity;


// dout
always @(posedge clock) begin
    if(~resetn) dout<=0;
    else begin 
        if(~(detect_add)) begin
            if(~(lfd_state)) begin
                if(~(ld_state && ~fifo_full)) begin
                    if(~(ld_state && fifo_full)) begin
                    if(~(laf_state)) dout<=dout;
                    else dout<=full_state_byte;
                    end
                    else dout<=dout;
                end
                else dout<=dout;
                end
                else dout<=data_in;
        end
            else dout<=header;
        end
    else dout<=dout;
end

// fifo_full_byte
always @(posedge clock) begin
    if(~resetn) full_state_byte<=0;
    else begin
        if(ld_state && fifo_full) full_state_byte<=data_in;
        else full_state_byte<=full_state_byte;
    end
end

// header
always @(posedge clock) begin
    if(~resetn) header<=0;
    else begin 
        if(detect_add && pkt_vld && (data_in[1:0]!=3)) 
            header<=data_in;
        else header<=header;
    end
end

// parity
always @(posedge clock) begin
    if(~resetn) internal_parity<=0;
    else begin
        if(detect_add) internal_parity<=0;
        else if(lfd_state) internal_parity<=internal_parity^header;
        else if(ld_state && pkt_vld && ~fifo_full) internal_parity<=internal_parity^data_in;
    end
end

// low_packet_valid
always @(posedge clock) begin
    if(~resetn) low_packet_valid<=0;
    else begin
        if(rst_int_reg) low_packet_valid<=1'b0;
        else if(ld_state && ~pkt_vld) low_packet_valid<=1'b1;
        else low_packet_valid<=low_packet_valid;
    end
end

// parity_done

always @(posedge clock) begin
    if(~resetn) parity_done<=0;
    else begin
        if(detect_add) parity_done<=0;
        else if( (ld_state && ~(plt_valid) && ~fifo_full) || (laf_state && (low_packet_valid) && ~parity_done)) parity_done<=1'b1;
        else parity_done<=parity_done;
    end
end

// packet_parity
always @(posedge clock) begin 
    if(~resetn) packet_parity<=0;
    else if(ld_state && ~pkt_vld) packet_parity<=data_in;
    else packet_parity<=packet_parity;
end

// error
always @(posedge clock) begin
    if(~resetn) error<=0;
    else begin
        if(parity_done) begin
            if(internal_parity!=packet_parity) error<=1'b0;
            else error<=1'b1;
        end
        else error=1'b0;
    end
end

endmodule