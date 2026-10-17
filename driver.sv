`include "driverbase.sv"
class driver extends driverbase;
        pkt_mbox in_box;
        pkt_mbox out_box;
        semaphore sem[];
        transaction trans;

        extern function new(semaphore sem[],pkt_mbox in_box,out_box, virtual infc.tb rtr_io);
        extern virtual task start();
endclass

function driver::new(semaphore sem[],pkt_mbox in_box,out_box, virtual infc.tb rtr_io);
        super.new(rtr_io);
        this.sem=sem;
        this.in_box=in_box;
        this.out_box=out_box;
endfunction

task driver::start();
        fork
                forever begin
                        transaction ref_pkt;
                        this.in_box.get(this.trans);
                        this.da=this.trans.da;
                        this.payload_len=this.trans.payload_len;
                        this.payload = {};
                        foreach(this.trans.payload[i])
                                this.payload.push_back(this.trans.payload[i]);
                        this.crc=this.trans.crc;
                        this.sem[0].get(1);
                        ref_pkt =this.trans.copy();
                        this.out_box.put(ref_pkt);
                        this.send();
                        this.sem[0].put(1);
                end
        join_none
endtask
