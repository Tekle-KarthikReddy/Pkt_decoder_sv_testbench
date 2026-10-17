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
