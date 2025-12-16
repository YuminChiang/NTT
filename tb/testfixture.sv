`timescale 1ns/10ps

`include "./TF_ROM.sv"

`define CYCLE       10.0            // Modify your clock period here
`define End_CYCLE   100000          // Modify cycle times once your design need more cycle times!

`define PAT_NUM     8
`define N           256

`define PATTERN_FILE    "./dat/PATTERN.dat"
`define GOLDEN_FILE     "./dat/GOLDEN.dat"
`define LOG_FILE        "./tb_NTT_log.txt"

module testfixture;

// top interface
logic             clk;
logic             rst;
logic             NTT_input_valid;
logic             NTT_input_ready;
logic     [22:0]  NTT_input_data;

logic      [7:0]  NTT_tf_addr;
logic     [22:0]  NTT_tf_data;

logic             NTT_output_valid;
logic     [22:0]  NTT_output_data;
logic             NTT_busy;

// PATTERN GOLDEN MEMORY
logic [22:0] PATTERN_1D[0 : `PAT_NUM * `N - 1];
logic [22:0] GOLDEN_1D [0 : `PAT_NUM * `N - 1];
logic [22:0] PATTERN_2D[0 : `PAT_NUM - 1][0 : `N - 1];
logic [22:0] GOLDEN_2D [0 : `PAT_NUM - 1][0 : `N - 1];

// Test signal 
integer cycleCount = 0;
integer expect_dat, actual_dat;
integer error_cnt, output_cnt;

logic [31:0] in_pat_cnt, in_n_cnt;
logic [31:0] out_pat_cnt, out_n_cnt;

integer log_file;

logic [22:0] OUTPUT_BUFFER[0 : `PAT_NUM - 1][0 : `N - 1];

initial log_file = $fopen(`LOG_FILE, "w");
initial $readmemh(`PATTERN_FILE, PATTERN_1D);
initial $readmemh(`GOLDEN_FILE,  GOLDEN_1D);

NTT top(
    .clk         (clk             ), 
    .rst         (rst             ), 
    .input_valid (NTT_input_valid ),
    .input_ready (NTT_input_ready ),
    .input_data  (NTT_input_data  ),
    .tf_addr     (NTT_tf_addr     ),
    .tf_data     (NTT_tf_data     ),
    .output_valid(NTT_output_valid),
    .output_data (NTT_output_data )
);

TF_ROM TF_ROM_u(
    .tf_case(NTT_tf_addr), 
    .tf_data(NTT_tf_data)
);

// 2D to 1D
always_comb begin
    for(int pat_idx = 0; pat_idx < `PAT_NUM; pat_idx++)begin
        for(int n_idx = 0; n_idx < `N; n_idx++)begin
            PATTERN_2D[pat_idx][n_idx] = PATTERN_1D[pat_idx * `N + n_idx];
            GOLDEN_2D[pat_idx][n_idx]  = GOLDEN_1D[pat_idx * `N + n_idx];
        end
    end
end

// clock generate
always begin #(`CYCLE/2) clk = ~clk; end

// cycle count
always @(posedge clk or posedge rst) begin
    if(rst) cycleCount <= 0; 
    else    cycleCount <= cycleCount + 1; 
end

// Timeout error
always@(posedge clk) begin
    if(cycleCount >= `End_CYCLE)begin
        $display("=======================================================");
        $display(" [ERROR] TIMEOUT ERROR, cycles = %d.", cycleCount);
        $display("=========================FAIL==========================");
        $fwrite(log_file, "=======================================================\n");
        $fwrite(log_file, " [ERROR] TIMEOUT ERROR, cycles = %d.\n", cycleCount);
        $fwrite(log_file, "=========================FAIL==========================\n");

        for(int chk_pat_idx = 0; chk_pat_idx < out_pat_cnt; chk_pat_idx++)begin
            for(int chk_n_idx = 0; chk_n_idx < `N; chk_n_idx++)begin
                expect_dat = GOLDEN_2D[chk_pat_idx][chk_n_idx];
                actual_dat = OUTPUT_BUFFER[chk_pat_idx][chk_n_idx];
                if(expect_dat === actual_dat)begin
                    $fwrite(log_file, "[ PASS] NTT[%1d][%3d]   match!\n", chk_pat_idx, chk_n_idx);
                    $fwrite(log_file, "\tNTT_expect_data : %6X (%7d)\n",  expect_dat, expect_dat);
                    $fwrite(log_file, "\tNTT_actual_data : %6X (%7d)\n\n",  actual_dat, actual_dat);
                end else begin
                    if(error_cnt <= 256)begin
                        $display("[ERROR] NTT[%1d][%3d] mismatch!", chk_pat_idx, chk_n_idx);
                        $display("\texpect_data : %6X (%7d)",       expect_dat, expect_dat);
                        $display("\tactual_data : %6X (%7d)\n",     actual_dat, actual_dat);
                    end
                    $fwrite(log_file, "[ERROR] NTT[%1d][%3d] mismatch!\n", chk_pat_idx, chk_n_idx);
                    $fwrite(log_file, "\texpect_data : %6X (%7d)\n",   expect_dat, expect_dat);
                    $fwrite(log_file, "\tactual_data : %6X (%7d)\n\n", actual_dat, actual_dat);
                    error_cnt++;
                end
            end
        end

        $display("=======================================================");
        $fwrite(log_file, "=======================================================\n");
        if(in_pat_cnt <= `PAT_NUM)begin
            $display(" Your NTT module only read in %0d / %0d patterns.", in_pat_cnt, `PAT_NUM);
            $display(" Please check your design");
            $fwrite(log_file, " Your NTT module only read in %0d / %0d patterns.\n", in_pat_cnt, `PAT_NUM);
            $fwrite(log_file, " Please check your design\n");
        end

        if(out_pat_cnt < `PAT_NUM)begin
            $display(" Your NTT module only output %0d / %0d patterns.", out_pat_cnt, `PAT_NUM);
            $display(" Please check your design");
            $fwrite(log_file, " Your NTT module only output %0d / %0d patterns.\n", out_pat_cnt, `PAT_NUM);
            $fwrite(log_file, " Please check your design\n");
        end
        $display("=======================================================");
        $fwrite(log_file, "=======================================================\n");

        $fclose(log_file);
        $finish();
    end
end

always_comb begin
    NTT_input_data  = PATTERN_2D[in_pat_cnt][in_n_cnt];
    NTT_input_valid = (~rst) & (in_pat_cnt < `PAT_NUM);
end

always_ff @(posedge clk or posedge rst)begin
    if(rst)begin
        in_pat_cnt  <= 0;
        in_n_cnt    <= 0;
    end begin
        if(NTT_input_ready & NTT_input_valid)begin
            if(in_n_cnt==`N-1)begin
                in_pat_cnt  <= in_pat_cnt + 1;
                in_n_cnt    <= 0;
            end else begin
                in_n_cnt    <= in_n_cnt + 1;
            end
        end
    end
end

always_ff @(posedge clk or posedge rst)begin
    if(rst)begin
        out_pat_cnt  <= 0;
        out_n_cnt    <= 0;
    end begin
        if(NTT_output_valid)begin
            if(out_n_cnt==`N-1)begin
                out_pat_cnt <= out_pat_cnt + 1;
                out_n_cnt   <= 0;
            end else begin
                out_n_cnt   <= out_n_cnt + 1;
            end
            OUTPUT_BUFFER[out_pat_cnt][out_n_cnt] <= NTT_output_data;
        end
    end
end

// main
initial begin
    error_cnt   = 0;
    output_cnt  = 0;
    clk  = 0;
    rst  = 1; 
    #(`CYCLE);
    @(negedge clk);
    rst  = 0;
    
    wait(out_pat_cnt >= `PAT_NUM);

    // check output
    for(int chk_pat_idx = 0; chk_pat_idx < `PAT_NUM; chk_pat_idx++)begin
        for(int chk_n_idx = 0; chk_n_idx < `N; chk_n_idx++)begin
            expect_dat = GOLDEN_2D[chk_pat_idx][chk_n_idx];
            actual_dat = OUTPUT_BUFFER[chk_pat_idx][chk_n_idx];
            if(expect_dat === actual_dat)begin
                $fwrite(log_file, "[ PASS] NTT[%1d][%3d]   match!\n", chk_pat_idx, chk_n_idx);
                $fwrite(log_file, "\tNTT_expect_data : %6X (%7d)\n",  expect_dat, expect_dat);
                $fwrite(log_file, "\tNTT_actual_data : %6X (%7d)\n\n",  actual_dat, actual_dat);
            end else begin
                if(error_cnt <= 256)begin
                    $display("[ERROR] NTT[%1d][%3d] mismatch!", chk_pat_idx, chk_n_idx);
                    $display("\texpect_data : %6X (%7d)",       expect_dat, expect_dat);
                    $display("\tactual_data : %6X (%7d)\n",     actual_dat, actual_dat);
                end
                $fwrite(log_file, "[ERROR] NTT[%1d][%3d] mismatch!\n", chk_pat_idx, chk_n_idx);
                $fwrite(log_file, "\texpect_data : %6X (%7d)\n",   expect_dat, expect_dat);
                $fwrite(log_file, "\tactual_data : %6X (%7d)\n\n", actual_dat, actual_dat);
                error_cnt++;
            end
        end
    end

    $display("====================== RESULT ======================");
    $fwrite(log_file, "\n====================== RESULT ======================\n");
    if (error_cnt == 0)begin
        $display("All %0d x %0d patterns passed!", `PAT_NUM, `N);
        $display("Cycle:        %0d", cycleCount);
        $display("Clock period: %.2f", `CYCLE);
        $fwrite(log_file, "All %0d x %0d patterns passed!\n\n", `PAT_NUM, `N);
        $fwrite(log_file, "Cycle:        %0d \n", cycleCount);
        $fwrite(log_file, "Clock period: %.2f\n", `CYCLE);
    end else begin
        $display("%0d / %0d patterns failed.", error_cnt, `PAT_NUM * `N);
        $display("Cycle:        %0d", cycleCount);
        $display("Clock period: %.2f", `CYCLE);
        $fwrite(log_file, "%0d / %0d patterns failed.\n\n", error_cnt, `PAT_NUM * `N);
        $fwrite(log_file, "Cycle:        %0d \n", cycleCount);
        $fwrite(log_file, "Clock period: %.2f\n", `CYCLE);
    end
    $display("====================== RESULT ======================");
    $fwrite(log_file, "====================== RESULT ======================\n");
    $fclose(log_file);
    $finish;
end

endmodule
