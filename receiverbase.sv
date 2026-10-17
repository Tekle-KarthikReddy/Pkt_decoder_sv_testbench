class receiverbase;
        virtual infc.tb rtr_io;
        logic [7:0] da;
        logic [7:0] payload_rec[$];
        transaction trans1;

        extern function new(virtual infc.tb rtr_io);
        extern virtual task recv();
        extern virtual task get_payload();
endclass

function receiverbase::new(virtual infc.tb rtr_io);
        this.rtr_io=rtr_io;
        this.trans1=new();
endfunction

task receiverbase::recv();
        this.get_payload();
        this.trans1=new();
        this.trans1.da=this.da;
        this.trans1.payload_len = this.payload_rec.size();
        this.trans1.payload ={};
        foreach(this.payload_rec[i])
                this.trans1.payload.push_back(this.payload_rec[i]);
endtask

task receiverbase::get_payload();
        logic [1:0] my_port;
        int idle;
        case(da)
                8'hAA:my_port=2'b00;
                8'hBB:my_port=2'b01;
                8'hCC:my_port=2'b10;
                8'hDD:my_port=2'b11;
                default:my_port=2'b00;
        endcase
        this.payload_rec.delete();
        idle=0;
while(!(this.rtr_io.cb.valid_out === 1'b1 &&  this.rtr_io.cb.valid_port === my_port)) begin
        @(this.rtr_io.cb);
        idle++;
        if(idle>1000000) begin
                $display( "%0t receiver DA =%h timout waiting for pkt",$time,da);
                return;
        end
end


while(this.rtr_io.cb.valid_out === 1'b1 &&  this.rtr_io.cb.valid_port ===my_port) begin

        logic [7:0] datum;
        case(da)
                8'hAA:datum = this.rtr_io.cb.aa;
                8'hBB:datum = this.rtr_io.cb.bb;
                8'hCC:datum = this.rtr_io.cb.cc;
                8'hDD:datum = this.rtr_io.cb.dd;
        endcase
        this.payload_rec.push_back(datum);

        @(this.rtr_io.cb);
end
endtask
