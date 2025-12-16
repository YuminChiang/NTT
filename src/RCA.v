module RCA(
	input  [3:0]   x,
	input  [3:0]   y,
	input 		c_in,
	output [3:0]   s,
	output     c_out
);

wire [4:0] c;
assign c[0] = c_in;

generate
	genvar k;
		for (k = 0; k < 4; k = k + 1)
		begin: FA
			FA u_fa(
				.x(x[k]),
				.y(y[k]),
				.c_in(c[k]),
				.s(s[k]),
				.c_out(c[k + 1])
			);
		end
endgenerate

assign c_out = c[4];


endmodule
