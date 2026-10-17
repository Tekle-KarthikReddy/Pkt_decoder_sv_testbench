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
