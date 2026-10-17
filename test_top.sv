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
endmodule
