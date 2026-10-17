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
