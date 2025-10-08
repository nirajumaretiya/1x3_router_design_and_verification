module router_top_tb();

reg clock,resetn,pkt_valid,read_enb_0,read_enb_1,read_enb_2;
reg [7:0]data_in;
wire vld_out_0,vld_out_1,vld_out_2,err,busy;
wire[7:0] data_out_0,data_out_1,data_out_2;
parameter cycle =10;
integer i;
router_top dut(clock,resetn,data_in,read_enb_0,read_enb_1,read_enb_2,pkt_valid,data_out_0,data_out_1,data_out_2,vld_out_0,vld_out_1,vld_out_2,err,busy);


//clock
always
begin
  #(cycle/2) clock=1'b0;
  #(cycle/2) clock=1'b1;
end

//reset
task resetf;
begin
  @(negedge clock);
  resetn= 1'b0;
  @(negedge clock);
  resetn= 1'b1;
end
endtask

task initialize;
begin
read_enb_0=1'b0;
read_enb_1=1'b0;
read_enb_2=1'b0;
//	read_enb_0=1'b1;
//	read_enb_1=1'b1;
//	read_enb_2=1'b1;

end
endtask

task pkt_gen_random;

reg[7:0]payload_data,parity,header;
reg[5:0]payload_len;
reg[1:0]addr;

begin
  @(negedge clock);
  wait(~busy);
  @(negedge clock);
  // Random payload length (1-8 bytes) - shorter to avoid timeouts
  payload_len=($random % 8) + 1;
  // Random destination address (0, 1, or 2)
  addr=$random % 3;
  header={payload_len,addr};
  parity=0;
  data_in=header;
  pkt_valid=1;
  parity=parity^header;
  @(negedge clock);
  wait(~busy);
  
  for(i=0;i<payload_len;i=i+1)
  begin
    @(negedge clock);
    wait(~busy);
    payload_data={$random}%256;
    data_in=payload_data;
    parity=parity^payload_data;
  end

  @(negedge clock);
  wait(~busy);
  pkt_valid=0;
  data_in=parity;
  @(negedge clock);
  wait(~busy);
  end
endtask

initial
begin
  initialize;
  resetf;
  
  // Generate packets and read them immediately to avoid timeouts
  repeat(5) begin
    pkt_gen_random;
    
    // Read from the appropriate output based on packet destination
    @(negedge clock);
    if(vld_out_0) begin
      read_enb_0 = 1;
      repeat(10) @(negedge clock);
      read_enb_0 = 0;
    end
    if(vld_out_1) begin
      read_enb_1 = 1;
      repeat(10) @(negedge clock);
      read_enb_1 = 0;
    end
    if(vld_out_2) begin
      read_enb_2 = 1;
      repeat(10) @(negedge clock);
      read_enb_2 = 0;
    end
    
    @(negedge clock);
  end
  
  // Keep reading any remaining data
  repeat(50) begin
    @(negedge clock);
    if(vld_out_0) read_enb_0 = 1; else read_enb_0 = 0;
    if(vld_out_1) read_enb_1 = 1; else read_enb_1 = 0;
    if(vld_out_2) read_enb_2 = 1; else read_enb_2 = 0;
  end
  
  read_enb_0=0; read_enb_1=0; read_enb_2=0;
end

initial
  $monitor("clock=%b,resetn=%b,pkt_valid=%b,read_enb_0=%b,read_enb_1=%b,read_enb_2=%b, vld_out_0=%b,vld_out_1=%b,vld_out_2=%b,err,busy=%b, data_out_0=%b,data_out_1=%b,data_out_2=%b,data_in=%b",clock,resetn,pkt_valid,read_enb_0,read_enb_1,read_enb_2,vld_out_0,vld_out_1,vld_out_2,err,busy,data_out_0,data_out_1,data_out_2);


initial
begin
  $dumpfile("top.vcd");
  $dumpvars();
  #2000 $finish;
end
endmodule