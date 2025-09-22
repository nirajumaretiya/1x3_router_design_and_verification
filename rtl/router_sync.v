module router_sync(clock,resetn,detect_add,full_0,full_1,full_2,data_in,empty_0,empty_1,empty_2,write_enb_reg,read_enb_0,read_enb_1,read_enb_2,fifo_full,vld_out_0,vld_out_1,vld_out_2,soft_reset_0,soft_reset_1,soft_reset_2,write_enb);

input clock,resetn,detect_add,write_enb_reg,read_enb_0,read_enb_1,read_enb_2,full_0,full_1,full_2,empty_0,empty_1,empty_2;
input [1:0] data_in;

output vld_out_0,vld_out_1,vld_out_2,soft_reset_0,soft_reset_1,soft_reset_2;
output reg [2:0] write_enb;
output reg fifo_full;

reg [1:0] temp;
reg [5:0] counter0,counter1,counter2; 
reg soft_reset_0,soft_reset_1,soft_reset_2;

always @(temp or full_0 or full_1 or full_2) begin
    case(temp) 
    2'b00: fifo_full=full_0;
    2'b01: fifo_full=full_1;
    2'b10: fifo_full=full_2;
    default : fifo_full=0;
    endcase
end

always @(posedge clock) begin
    if(~resetn) temp<=0;
    else if(detect_add) temp<=data_in;
    else temp<=temp;
end


always @(temp or write_enb or write_enb_reg) begin
    if(write_enb_reg) begin
        case(temp) 
            2'b00: write_enb=3'b001;
            2'b01: write_enb=3'b010;
            2'b10: write_enb=3'b100;
        endcase
    end
    else write_enb=0;
end

assign vld_out_0=~empty_0;
assign vld_out_1=~empty_1;
assign vld_out_2=~empty_2;

always @(posedge clock) begin
    if(~resetn) begin 
        counter0<=0;
        soft_reset_0<=0;
    end
    else if(!read_enb_0 && vld_out_0) begin
        if(counter0<29) counter0<=counter0+1;
        if(counter0>=29) soft_reset_0<=1'b1;
        if(read_enb_0) counter0<=0;
    end
end

always @(posedge clock) begin
    if(~resetn) begin 
        counter1<=0;
        soft_reset_1<=0;
    end
    else if(!read_enb_1 && vld_out_1) begin
        if(counter1<29) counter1<=counter1+1;
        if(counter1>=29) soft_reset_1<=1'b1;
        if(read_enb_1) counter1<=0;
    end 
end

always @(posedge clock) begin
    if(~resetn) begin 
        counter2<=0;
        soft_reset_2<=0;
    end
    else if(!read_enb_2 && vld_out_2) begin
        if(counter2<29) counter2<=counter2+1;
        if(counter2>=29) soft_reset_2<=1'b1;
        if(read_enb_2) counter2<=0;
    end
end

endmodule


