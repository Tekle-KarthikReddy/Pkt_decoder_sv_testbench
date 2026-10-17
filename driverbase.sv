class driverbase;
        virtual infc.tb rtr_io;
        logic [7:0] da;
        int payload_len;
        logic [7:0] payload[$];
        logic [7:0] crc;

        extern function new( virtual infc.tb rtr_io);
        extern virtual task send();
        extern virtual task send_header();
        extern virtual task send_payload();
        extern virtual task send_crc();
        extern virtual task wait_output();
endclass


function driverbase::new( virtual infc.tb rtr_io);
        this.rtr_io=rtr_io;
endfunction

task driverbase::send();
        this.send_header();
        this.send_payload();
        this.send_crc();
        this.wait_output();
endtask

task driverbase::send_header();
        this.rtr_io.cb.valid_in <= 1'b1;
        this.rtr_io.cb.data_in <= this.da;
        @(this.rtr_io.cb);
        this.rtr_io.cb.data_in <= this.payload_len;
        @(this.rtr_io.cb);
endtask
task driverbase::send_payload();
        foreach(payload[i]) begin
                this.rtr_io.cb.data_in <=this.payload[i];
                @(this.rtr_io.cb);
        end
endtask

task driverbase::send_crc();
        this.rtr_io.cb.data_in <= this.crc;
        this.rtr_io.cb.valid_in <=1'b1;
        @(this.rtr_io.cb);
        this.rtr_io.cb.valid_in <=1'b0;
        this.rtr_io.cb.data_in <= 8'h00;
endtask

task driverbase::wait_output();
        int timeout=0;
while(timeout<64 && this.rtr_io.cb.valid_out !== 1'b1) begin
        @(this.rtr_io.cb);
        timeout++;
end

while(this.rtr_io.cb.valid_out == 1'b1) begin
        @(this.rtr_io.cb);
end
repeat(2) @(this.rtr_io.cb);
endtask
