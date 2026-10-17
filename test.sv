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
