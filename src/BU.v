`include "Mul_Mod.v"

module BU(
    input       [22:0] X,
    input       [22:0] Y,
    input       [22:0] TF,
    output reg  [22:0] A,
    output reg  [22:0] B
);

localparam [22:0] q = 23'd8380417;

wire [23:0] sum, zY;

Mul_Mod u_Mul_Mod (
    .A(TF),
    .B(Y),
    .Z(zY)
);

assign sum  = X + zY;

always @(*) begin
    A = (sum >= q) ? sum - q : sum[22:0];
    B = (X < zY) ? (X + q - zY) : (X - zY);
end

endmodule