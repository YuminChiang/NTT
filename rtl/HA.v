module HA(
	input  x,
	input  y,
	output s, 
	output c
);

assign {c, s} = x + y;

endmodule
