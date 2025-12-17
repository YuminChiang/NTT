module NTT(
    input             clk, 
    input             rst, 
    output            input_ready,
    input             input_valid,
    input      [22:0] input_data,
    output     [7:0]  tf_addr,
    input      [22:0] tf_data,
    output reg        output_valid,
    output reg [22:0] output_data
);

localparam IDLE = 3'd0;
localparam LOAD = 3'd1;
localparam BUTTERFLY = 3'd2;    // BU
localparam BLOCK_NEXT = 3'd3;   // start += len >> 1
localparam STAGE_NEXT = 3'd4;   // len >>= 1
localparam OUTPUT = 3'd5;

reg [2:0] state, next_state;

reg [22:0] memory [0:255];
reg [7:0] len;
reg [7:0] start;
reg [7:0] j;
reg [7:0] m;

reg [7:0] in_cnt, out_cnt;

wire [7:0] j_next = j + 1;
wire [7:0] end_j = start + len - 1; 
wire [22:0] A, B; 

BU u_bu(
    .X(memory[j]), 
    .Y(memory[j + len]), 
    .TF(tf_data), 
    .A(A), 
    .B(B)
);

assign tf_addr = m + 1;
assign input_ready = (state == LOAD);

always @(posedge clk or posedge rst) begin
    if(rst) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

always @(*) begin
    case(state)
        IDLE: 
            next_state = input_valid ? LOAD : IDLE;
        LOAD:
            next_state = in_cnt == 255 ? BUTTERFLY : LOAD;
        BUTTERFLY:
            next_state = (j_next <= end_j) ? BUTTERFLY : BLOCK_NEXT;
        BLOCK_NEXT:
            next_state = start + (len << 1) < 256 ? BUTTERFLY : STAGE_NEXT;
        STAGE_NEXT:
            next_state = len > 1 ? BUTTERFLY : OUTPUT;
        OUTPUT:
            next_state = (out_cnt == 255) ? IDLE : OUTPUT;
        default: next_state = IDLE;
    endcase
end

always @(posedge clk or posedge rst) begin
    if(rst) begin
        in_cnt <= 0;
        m <= 0;
        len <= 128;
        start <= 0;
        j <= 0;
        out_cnt <= 0;
        output_valid <= 0;
    end else begin
        case (state)
            IDLE: begin
                in_cnt <= 0;
                m <= 0;
                len <= 128;
                start <= 0;
                j <= 0;
                out_cnt <= 0;
                output_valid <= 0;
            end
            LOAD: begin
                memory[in_cnt] <= input_data;
                in_cnt <= in_cnt + 1;
            end
            BUTTERFLY: begin
                memory[j] <= A;
                memory[j + len] <= B;
                if (j_next <= end_j)
                    j <= j_next;
            end
            BLOCK_NEXT: begin
                start <= start + (len << 1);
                j <= start + (len << 1);
                m <= m + 1;
            end
            STAGE_NEXT: begin
                len <= len >> 1;
                start <= 0;
                j <= 0;
            end
            OUTPUT: begin
                output_valid <= 1;
                output_data <= memory[out_cnt];
                out_cnt <= out_cnt + 1;
            end
        endcase
    end
end

endmodule