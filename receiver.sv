`include "receiverbase.sv"
class receiver extends receiverbase;
        pkt_mbox out_box;

        extern function new( pkt_mbox out_box,int da,virtual infc.tb rtr_io);
        extern virtual task start();
endclass

function receiver::new(pkt_mbox out_box,int da,virtual infc.tb rtr_io);
        super.new(rtr_io);
        this.da = da;
        this.out_box=out_box;
endfunction

task receiver::start();
        fork
        begin
                @(this.rtr_io.cb);
                forever begin
                        transaction pkt;
                        this.recv();
                        if(this.trans1.payload.size() >0) begin
                                $display("[%0t] receiver DA=%h received payload size=%0d",$time,this.trans1.da,this.trans1.payload.size());

                                pkt =  this.trans1.copy();
                                this.out_box.put(pkt);
                        end
                end
        end
        join_none
endtask
