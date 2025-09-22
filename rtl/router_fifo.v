module router_fifo #(parameter WIDTH = 9, DEPTH = 16) (
    clock,resetn,data_in,read_enb,write_enb,data_out,empty,full,lfd_state,soft_reset
);

input clock,resetn,read_enb,write_enb,lfd_state,soft_reset;
input [WIDTH-2:0] data_in; 
output reg [WIDTH-2:0] data_out;
output empty,full;

reg [4:0] wr_ptr,rd_ptr;
reg [6:0] counter;
reg [WIDTH-1:0] mem[DEPTH-1:0];
reg temp;   

assign empty = (wr_ptr == rd_ptr);
assign full = ((wr_ptr[4]!=rd_ptr[4]) && (wr_ptr[3:0] == rd_ptr[3:0]));

integer i;

always @(posedge clock) begin
    if(~resetn) temp=0;
    else temp=lfd_state;
end

// write operation
always @(posedge clock) begin
    if(~resetn) begin
        for(i=0;i<=DEPTH-1;i=i+1)
            mem[i]<=0;
    end
    else if(soft_reset) begin
        for(i=0;i<=DEPTH-1;i=i+1)
            mem[i]<=0;
    end
    else if(write_enb && !full) begin
        if(lfd_state) begin
            {mem[wr_ptr[3:0]][8],mem[wr_ptr[3:0]][7:0]}<={temp,data_in};
        end
        else begin
            {mem[wr_ptr[3:0]][8],mem[wr_ptr[3:0]][7:0]}<={temp,data_in};
        end
    end
end

// read operation
always @(posedge clock) begin
    if(~resetn) begin
        data_out<=0;
    end
    else if(soft_reset) begin
        data_out<='bz;
    end
    else if(read_enb && !empty) begin
        data_out<=mem[rd_ptr[3:0]][7:0];
    end
    else if(counter==0 && data_out!=0) begin
        data_out<=8'bzzzzzzzz;
    end
end

// counter operation
always @(posedge clock) begin
    if(read_enb && !empty) begin
        if(mem[rd_ptr[3:0]][8]) begin
            counter<=mem[rd_ptr[3:0]][7:2]+1;
        end
        else if(counter!=0) begin
            counter<=counter-1;
        end
    end
end

// pointer operation
always @(posedge clock) begin
    if(~resetn || soft_reset) begin
        rd_ptr<=0;
        wr_ptr<=0;
    end
    else begin
        if(write_enb && !full) wr_ptr<=wr_ptr+1;
        if(read_enb && !empty) rd_ptr<=rd_ptr+1;
    end
end

endmodule
