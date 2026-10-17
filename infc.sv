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
