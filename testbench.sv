interface infc(input clk);
        logic reset;
        logic [7:0] data_in;
        logic valid_in,valid_out;
        logic [1:0] valid_port;
        logic [7:0] aa,bb,cc,dd;

        clocking cb @(posedge clk) ;
                default input #1ns output #1ns;
                output data_in;
                output valid_in;
                input valid_out;
                input valid_port;
                input aa;
                input bb;
                input cc;
                input dd;
        endclocking:cb

        modport tb(clocking cb,output reset);
endinterface

package packet_test_pkg;
        int run_for_n_pkts=0;
class transaction;
        rand logic [7:0] da;
        int id;
        static int id_counter=0;
        rand int payload_len;
        rand logic [7:0] payload[$];
        logic [7:0] crc;

        constraint a{da inside {8'hAA,8'hBB,8'hCC,8'hDD};}
        constraint c{payload_len inside{[1:5]};}
        constraint b{payload.size()==payload_len;}

        function logic [7:0]crc_cal();
                logic [7:0] crc1;
                crc1=8'h00;
                for(int i=0;i<payload.size();i++) begin
                        crc1 = crc1^payload[i];
                end
                return crc1;
        endfunction
        function void post_randomize();
                id=id_counter++;
                crc=crc_cal();
        endfunction
        function transaction copy();
                transaction pkt;
                pkt=new();
                pkt.da=this.da;
                pkt.id = this.id;
                pkt.payload_len=this.payload_len;
                pkt.crc=this.crc;
                pkt.payload = {};
                foreach (this.payload[i])
                        pkt.payload.push_back(this.payload[i]);
                return pkt;
        endfunction
        extern function bit compare(transaction trans1,ref string message);
endclass

function bit transaction::compare(transaction trans1,ref string message);
        if(da!==trans1.da) begin
                message=$sformatf("DA mismatch exp-%h got=%h",da,trans1.da);
                return 0;
        end

        if(payload.size()!=trans1.payload.size()) begin
                message=$sformatf("payload size mismatch exp=%0d  got=%0d",payload.size(),trans1.payload.size());
                return(0);
        end
        if(payload!=trans1.payload) begin
                message = "payload content mismatch";
                return(0);

        end
        message="successfully compared";
        return(1);
endfunction
`ifndef PACKET_TEST_H
`define PACKET_TEST_H
typedef mailbox #(transaction) pkt_mbox;
`endif
class generator;
        transaction trans;
        pkt_mbox out_box;
        extern function new();
        extern virtual task gen();
        extern virtual task start();
endclass


function generator::new();
        this.out_box=new();
endfunction

task generator::gen();
        this.trans=new();
        if(!this.trans.randomize()) begin
                $display("error");
                $finish;
        end
endtask

task generator::start();
        fork
        begin
                for(int i=0;i<run_for_n_pkts;i++)
                begin
                        this.gen();
                        out_box.put(this.trans.copy());

                end
        end
        join_none
endtask
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
class scoreboard;
        event DONE;
        transaction refpkt[$];
        transaction trans;
        transaction trans1;
        pkt_mbox driver_mbox;
        pkt_mbox receiver_mbox;

        logic [7:0] da,crc;
        int payload_len;
        int drops=0;

        covergroup packet_cov;
                coverpoint da { bins dest[] ={8'hAA,8'hBB,8'hCC,8'hDD};}
                coverpoint crc { option.auto_bin_max =16;}
                coverpoint payload_len { bins len[] = {[1:5]};}
        endgroup

        extern function new(pkt_mbox driver_mbox=null,receiver_mbox=null);
        extern virtual task start();
        extern virtual task check();
endclass

function scoreboard::new(pkt_mbox driver_mbox,receiver_mbox);
        if(driver_mbox==null) driver_mbox=new();
        this.driver_mbox = driver_mbox;
        if(receiver_mbox==null) receiver_mbox=new();
        this.receiver_mbox = receiver_mbox;
        packet_cov  = new();
endfunction

task scoreboard::start();
        fork
                forever begin
                        transaction pkt;
                        driver_mbox.get(pkt);
                        refpkt.push_back(pkt);
                end
                forever begin
                        receiver_mbox.get(trans1);
                        check();
                end
        join_none
endtask

task scoreboard::check();
        string message;
        static int pkts_checked= 0;
        real coverage_result;
        int idx=-1;
        foreach(refpkt[i]) begin
                if(refpkt[i].da == trans1.da) begin
                        idx=i;
                        break;
                end
        end
        if(idx==-1) begin
                message =$sformatf("no matching ref pkt for DA=%h",trans1.da);
                $display("error %s",message);
        end
        else begin
                if(!refpkt[idx].compare(trans1,message)) begin
                        $display("error comparing");
                end
                this.da=refpkt[idx].da;
                this.payload_len=refpkt[idx].payload_len;
                this.crc=refpkt[idx].crc;
                refpkt.delete(idx);
        end
        packet_cov.sample();
        coverage_result=packet_cov.get_coverage();
        $display(" packet %0d %s coverage = %3.2f",pkts_checked,message,coverage_result);
        pkts_checked++;
        if((pkts_checked>=run_for_n_pkts) || (coverage_result==100))
                ->DONE;
endtask
class environment;
        rand int run_for_n_pkts;
        virtual infc.tb rtr_io;

        semaphore sem[];
        driver drvr[];
        receiver rcvr[];
        generator gen;
        scoreboard sb;

        constraint valid{ this.run_for_n_pkts inside {[1500:2000]};}

        extern function new(virtual infc.tb rtr_io);
        extern virtual task run();
        extern virtual function void configure();
        extern virtual function void build();
        extern virtual task start();
        extern virtual task wait_for_end();
        extern virtual task reset();
endclass

function environment::new(virtual infc.tb rtr_io);
        this.rtr_io=rtr_io;
endfunction

task environment::run();
        this.build();
        this.reset();
        this.start();
        this.wait_for_end();
endtask

function void environment::configure();
        if(!this.randomize()) begin
                $display("environment randomize failed");
                this.run_for_n_pkts = 1500;
        end
endfunction

function void environment::build();
        if(this.run_for_n_pkts==0) this.run_for_n_pkts=2000;
        this.sem = new[1];
        this.drvr = new[1];
        this.rcvr = new[4];
        this.gen=new();
        this.sb=new();
        foreach(sem[i])
                this.sem[i]=new(1);
        for(int i=0;i<drvr.size();i++)
                this.drvr[i]=new(this.sem,this.gen.out_box,this.sb.driver_mbox,this.rtr_io);
        for(int i=0;i<rcvr.size();i++)
                this.rcvr[i]=new(this.sb.receiver_mbox,8'hAA+(8'h11*i),this.rtr_io);
endfunction

task environment::reset();
        this.rtr_io.reset <= 1'b1;
        this.rtr_io.cb.data_in <= 8'b0;
        this.rtr_io.cb.valid_in <=1'b0;
        repeat(4) @(this.rtr_io.cb);
        this.rtr_io.reset <= 1'b0;
        repeat(2) @(this.rtr_io.cb);
endtask

task environment::start();
        this.gen.start();
        this.sb.start();
        foreach(this.drvr[i])
                this.drvr[i].start();
        foreach(this.rcvr[i])
                this.rcvr[i].start();
endtask

task environment::wait_for_end();
        fork
                @(this.sb.DONE);
        begin
                repeat(run_for_n_pkts * 80 + 5000) @(this.rtr_io.cb);
                $display("%0t timout waiting for scoreboard  DONE",$time);
        end
        join_any
        disable fork;
        repeat(20) @(this.rtr_io.cb);
        $display("test completed");
endtask
endpackage

program automatic test(infc.tb rtr_io);
        import packet_test_pkg::*;

        environment env;
        initial begin
                env = new(rtr_io);
                env.configure();
                run_for_n_pkts=env.run_for_n_pkts;
                $display("running %0d packets",run_for_n_pkts);
                env.run();
                $finish;
        end
endprogram

module test_top;
parameter clk_simulation=100;
bit system_clk;

infc top_io(system_clk);
test t(top_io);



pkt_decoder dut(.reset(top_io.reset),
        .clk(top_io.clk),
        .data_in(top_io.data_in),
        .valid_in(top_io.valid_in),
        .valid_out(top_io.valid_out),
        .valid_port(top_io.valid_port),
        .aa(top_io.aa),
        .bb(top_io.bb),
        .cc(top_io.cc),
        .dd(top_io.dd));
initial begin
        system_clk=0;
        forever begin
                #(clk_simulation/2)
                system_clk=~system_clk;
        end
end
initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, test_top);
end
endmodule
