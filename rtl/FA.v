module FA(
	input 	   x,
	input 	   y,
	input 	c_in,
	output     s, 
	output  c_out
);

wire w_s1, w_c1, w_c2;

HA u_ha1(
	.x(x),
	.y(y),
	.s(w_s1),
	.c(w_c1)
);
HA u_ha2(
	.x(c_in),
	.y(w_s1),
	.s(s),
	.c(w_c2)
);

assign c_out = w_c1 | w_c2;

endmodule

