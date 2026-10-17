module pkt_decoder #(parameter WIDTH=8 ,WIDTH1=2 ,DEPTH=16)(
        input  clk,reset,
        input [WIDTH-1:0]data_in,
        input valid_in,
        output reg valid_out,
        output reg [WIDTH1-1:0]valid_port,
        output reg [WIDTH-1:0] aa,
        output reg [WIDTH-1:0] bb,
        output reg [WIDTH-1:0] cc,
        output reg [WIDTH-1:0] dd);

reg [WIDTH-1:0] destination_addr;
reg [WIDTH-1:0] payload_count;
reg [WIDTH-1:0] payload_len;
reg [WIDTH-1:0] recieved_crc;
reg [WIDTH-1:0] calculated_crc;
reg [WIDTH1:0] state,next_state;
reg [WIDTH-1:0] payload_mem [0:DEPTH-1];
reg [WIDTH-1:0] output_count;
localparam [WIDTH-1:0] AA=8'hAA;
localparam [WIDTH-1:0] BB=8'hBB;
localparam [WIDTH-1:0] CC=8'hCC;
localparam [WIDTH-1:0] DD=8'hDD;
integer i;
localparam [2:0] HEADER1=3'd0, HEADER2=3'd1, PAYLOAD=3'd2, CRC=3'd3, OUTPUT=3'd4;
/*function [WIDTH-1:0]crc_cal;
        input [WIDTH-1:0]payload;
        begin
                crc_cal=8'h0;
                for( i=0;i<payload;i=i+1) begin
                        crc_cal=crc_cal^payload_mem[i];
                end
        end
endfunction
*/
always @(posedge clk) begin
        if(reset) begin
                aa<=0;
                bb<=0;
                cc<=0;
                dd<=0;
                valid_out<=0;
                payload_count<=0;
                payload_len<=0;
                destination_addr<=0;
                recieved_crc<=0;
                calculated_crc<=0;
                output_count<=0;
                state<=HEADER1;
                for(i=0;i<DEPTH;i=i+1) begin
                        payload_mem[i]<=0;
                end
        end
        else begin
                state<=next_state;
                case(state)
                        HEADER1:begin
                                output_count<=0;
                                valid_out<=0;
                                valid_port<=0;
                                calculated_crc<=0;
                                if(valid_in && (data_in ==AA || data_in ==BB || data_in == CC || data_in == DD))
                                        destination_addr<=data_in;

                        end
                        HEADER2:begin
                                valid_out<=0;
                                if(valid_in) begin
                                        payload_len<=data_in;
                                        payload_count<=0;
                                end
                        end
                        PAYLOAD:begin
                                valid_out<=0;
                                if(valid_in) begin
                                        if(payload_count< payload_len) begin
                                                payload_mem[payload_count]<=data_in;
                                                calculated_crc<=calculated_crc^data_in;
                                                payload_count<=payload_count+1;

                                        end
                                end
                        end
                        CRC:begin
                                valid_out<=0;
                                output_count<=0;
                        end
                        OUTPUT:begin
                                valid_out<=1'b1;
                                case(destination_addr)
                                        AA:
                                        begin
                                                valid_port<=2'b00;
                                                aa<=payload_mem[output_count];
                                        end
                                        BB:begin
                                                valid_port<=2'b01;
                                                bb<=payload_mem[output_count];

                                        end
                                        CC:begin
                                                valid_port<=2'b10;
                                                cc<=payload_mem[output_count];
                                        end
                                        DD:begin
                                                valid_port<=2'b11;
                                                dd<=payload_mem[output_count];
                                        end
                                        default:begin
                                                valid_out<=1'b0;
                                                valid_port<=2'b00;
                                        end
                                endcase
                                output_count<=output_count+1;
                        end
                        default:begin
                                valid_out<=1'b0;
                        end
                endcase

        end

end

always @(*) begin
        next_state = state;
        case(state)
                HEADER1:next_state=(valid_in && ( data_in == AA || data_in == BB || data_in == CC || data_in == DD)) ? HEADER2:HEADER1;
                HEADER2:next_state=valid_in? PAYLOAD:HEADER2;
                PAYLOAD:next_state=(valid_in && (payload_count==payload_len-1))? CRC: PAYLOAD;
                CRC: next_state=valid_in?((data_in==calculated_crc)? OUTPUT: HEADER1):CRC;
                OUTPUT: next_state=(output_count == (payload_len-1))? HEADER1: OUTPUT;
                default: next_state=HEADER1;
        endcase
end
endmodule
