`include "RCA.v"

module Mul_Mod (
    input  [22:0] A,
    input  [22:0] B,
    output [23:0] Z
);

wire [47:0] full_product;
wire [23:0] high_part;
wire [23:0] reduced_value;
wire [23:0] correction_term;
wire borrow;
wire [47:0] temp1;
wire [47:0] temp2;
wire [47:0] temp3;
wire [47:0] temp4;
wire [10:0] w_value;
wire [23:0] adjusted_low;
wire [23:0] final_result;

wire [28:0] high_mul = A * B[22:17];
wire [39:0] low_mul = A * B[16:0];

Adder #(.DATA_WIDTH(48)) add1(
	.x({2'b0, high_mul, 17'b0}),
	.y({8'b0, low_mul}),
	.s(full_product)
);

// V stage

assign high_part[23:0] = full_product[45:22];

Adder #(.DATA_WIDTH(48)) add2(
	.x({24'b0, high_part}),
	.y({34'b0, high_part[23:10]}),
	.s(temp1)
);

wire [47:0] concat = {13'b0, temp1[24:0], high_part[9:0]};

Adder #(.DATA_WIDTH(48)) add3(
	.x({23'b0, high_part[23:0], 1'b0}),
	.y({24'b0, high_part[23:0]}),
	.s(temp2)
);

Adder #(.DATA_WIDTH(48)) add4(
	.x(temp2),
	.y({25'b0, high_part[23:1]}),
	.s(temp3)
);

Adder #(.DATA_WIDTH(48)) add5(
	.x({34'b0, temp3[25:12]}),
	.y(concat),
	.s(temp4)
);

// W stage

assign reduced_value = temp4[34:11];
assign w_value = reduced_value[23:13] - reduced_value[10:0];
wire temp = w_value[10] ^ reduced_value[0];
// X stage
assign correction_term = {temp, w_value[9:0], reduced_value[12:0]};
// Z stage
assign adjusted_low = full_product[23:0] - correction_term[23:0];
assign {borrow, final_result} = adjusted_low - 24'd8380417;
assign Z = borrow ? adjusted_low : final_result;

endmodule


module Adder #(
    parameter DATA_WIDTH  = 48, 
    parameter BLOCK_WIDTH = 4   
)(
    input  [DATA_WIDTH-1:0] x,
    input  [DATA_WIDTH-1:0] y,
    output [DATA_WIDTH-1:0] s
);

    localparam NUM_BLOCKS = DATA_WIDTH / BLOCK_WIDTH;

    wire [NUM_BLOCKS:0] carry;
    assign carry[0] = 1'b0;

    genvar i; 
    generate
        for (i = 0; i < NUM_BLOCKS; i = i + 1) begin : rca_gen_block
            
            localparam MSB = (i + 1) * BLOCK_WIDTH - 1;
            localparam LSB = i * BLOCK_WIDTH;

            RCA rca_inst (
                .x      (x[MSB:LSB]),         
                .y      (y[MSB:LSB]),         
                .s      (s[MSB:LSB]),         
                .c_in   (carry[i]),           
                .c_out  (carry[i+1])          
            );
        end
    endgenerate


endmodule