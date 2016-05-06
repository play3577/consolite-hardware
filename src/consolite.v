/**
 * The top level module for Consolite. Instantiates
 * an LPDDR RAM, VGA controller, 7-segment display,
 * processor, etc and hooks them together.
 *
 * @author Robert Fotino, 2016
 */

`include "definitions.vh"

module consolite
  (
   // 100MHz system clock
   input         clk,
   // 7-segment display outputs
   output [7:0]  seven_seg,
   output [2:0]  seven_seg_en,
   // VGA display outputs
   output        hsync,
   output        vsync,
   output [7:0]  rgb,
   // User inputs
   input [5:0]   buttons,
   input [7:0]   switches,
   input [7:0]   gpio_p6,
   input [7:0]   gpio_p7,
   input [7:0]   gpio_p8,
   input [7:0]   gpio_p9,
   // Micro SD card inputs and outputs
   //output        sdcard_cs,
   //output        sdcard_sclk,
   //output        sdcard_mosi,
   //input         sdcard_miso,
   // UART inputs and outputs
   input         uart_rx,
   // LPDDR RAM inputs and outputs
   inout [15:0]  mcb3_dram_dq,
   output [12:0] mcb3_dram_a,
   output [1:0]  mcb3_dram_ba,
   output        mcb3_dram_cke,
   output        mcb3_dram_ras_n,
   output        mcb3_dram_cas_n,
   output        mcb3_dram_we_n,
   output        mcb3_dram_dm,
   inout         mcb3_dram_udqs,
   inout         mcb3_rzq,
   output        mcb3_dram_udm,
   input         c3_sys_rst_n,
   inout         mcb3_dram_dqs,
   output        mcb3_dram_ck,
   output        mcb3_dram_ck_n,
   output        mcb3_calib_done,
   input         mcb3_error
   );

   // Some functions can't be started until we have booted
   wire clear_screen_done;
   wire uart_load_done;
   wire boot_done = mcb3_calib_done & clear_screen_done & uart_load_done;

   // Main memory port 0 (read/write) for data cache
   wire        c3_p0_cmd_clk;
   wire        c3_p0_cmd_en;
   wire [2:0]  c3_p0_cmd_instr;
   wire [5:0]  c3_p0_cmd_bl;
   wire [29:0] c3_p0_cmd_byte_addr;
   wire        c3_p0_cmd_empty;
   wire        c3_p0_cmd_full;
   wire        c3_p0_wr_clk;
   wire        c3_p0_wr_en;
   wire [3:0]  c3_p0_wr_mask;
   wire [31:0] c3_p0_wr_data;
   wire        c3_p0_wr_full;
   wire        c3_p0_wr_empty;
   wire [6:0]  c3_p0_wr_count;
   wire        c3_p0_wr_underrun;
   wire        c3_p0_wr_error;
   wire        c3_p0_rd_clk;
   wire        c3_p0_rd_en;
   wire [31:0] c3_p0_rd_data;
   wire        c3_p0_rd_full;
   wire        c3_p0_rd_empty;
   wire [6:0]  c3_p0_rd_count;
   wire        c3_p0_rd_overflow;
   wire        c3_p0_rd_error;

   // Main memory port 2 (read) for VGA buffer
   wire        c3_p2_cmd_clk;
   wire        c3_p2_cmd_en;
   wire [2:0]  c3_p2_cmd_instr;
   wire [5:0]  c3_p2_cmd_bl; // bl = burst length
   wire [29:0] c3_p2_cmd_byte_addr;
   wire        c3_p2_cmd_empty;
   wire        c3_p2_cmd_full;
   wire        c3_p2_rd_clk;
   wire        c3_p2_rd_en;
   wire [31:0] c3_p2_rd_data;
   wire        c3_p2_rd_full;
   wire        c3_p2_rd_empty;
   wire [6:0]  c3_p2_rd_count;
   wire        c3_p2_rd_overflow;
   wire        c3_p2_rd_error;

   // Main memory port 3 (read) for instruction cache
   wire        c3_p3_cmd_en;
   wire [2:0]  c3_p3_cmd_instr;
   wire [5:0]  c3_p3_cmd_bl; // bl = burst length
   wire [29:0] c3_p3_cmd_byte_addr;
   wire        c3_p3_cmd_empty;
   wire        c3_p3_cmd_full;
   wire        c3_p3_rd_en;
   wire [31:0] c3_p3_rd_data;
   wire        c3_p3_rd_full;
   wire        c3_p3_rd_empty;
   wire [6:0]  c3_p3_rd_count;
   wire        c3_p3_rd_overflow;
   wire        c3_p3_rd_error;

   // Main memory port 4 (write) for pixel writer
   wire        c3_p4_cmd_en;
   wire [2:0]  c3_p4_cmd_instr;
   wire [5:0]  c3_p4_cmd_bl; // bl = burst length
   wire [29:0] c3_p4_cmd_byte_addr;
   wire        c3_p4_cmd_empty;
   wire        c3_p4_cmd_full;
   wire        c3_p4_wr_en;
   wire [3:0]  c3_p4_wr_mask;
   wire [31:0] c3_p4_wr_data;
   wire        c3_p4_wr_full;
   wire        c3_p4_wr_empty;
   wire [6:0]  c3_p4_wr_count;
   wire        c3_p4_wr_underrun;
   wire        c3_p4_wr_error;

   // Main memory port 5 (write) for SD card reader
   wire        c3_p5_cmd_en;
   wire [2:0]  c3_p5_cmd_instr;
   wire [5:0]  c3_p5_cmd_bl; // bl = burst length
   wire [29:0] c3_p5_cmd_byte_addr;
   wire        c3_p5_cmd_empty;
   wire        c3_p5_cmd_full;
   wire        c3_p5_wr_en;
   wire [3:0]  c3_p5_wr_mask;
   wire [31:0] c3_p5_wr_data;
   wire        c3_p5_wr_full;
   wire        c3_p5_wr_empty;
   wire [6:0]  c3_p5_wr_count;
   wire        c3_p5_wr_underrun;
   wire        c3_p5_wr_error;

   // Buffers the input for INPUT instructions
   wire [45:0] buf_inputs;
   input_handler input_handler_
     (
      .clk(clk),
      .buttons(buttons),
      .switches(switches),
      .gpio_p6(gpio_p6),
      .gpio_p7(gpio_p7),
      .gpio_p8(gpio_p8),
      .gpio_p9(gpio_p9),
      .buf_inputs(buf_inputs)
      );

   // A reset-able millisecond timer for TIME and
   // TIMERST instructions
   wire                  ms_time_rst;
   wire [`WORD_BITS-1:0] ms_time;
   ms_timer ms_timer_
     (
      .clk(clk),
      .reset(ms_time_rst),
      .ms_time(ms_time)
      );

   wire [`WORD_BITS-1:0] rnd;
   galois_lfsr rng
     (
      .clk(clk),
      .calib_done(mcb3_calib_done),
      .buf_inputs(buf_inputs),
      .rnd(rnd)
      );

   // Determines the digits for the 7-segment display,
   // based on status/error conditions
   wire [7:0]     uart_progress;
   wire [11:0]    processor_status;
   wire [11:0]    seg_digits;
   seg_status seg_status_
     (
      .mem_calib_done(mcb3_calib_done),
      .mem_error(mcb3_error),
      .clear_screen_done(clear_screen_done),
      .uart_load_done(uart_load_done),
      .uart_progress(uart_progress),
      .processor_status(processor_status),
      .seg_digits(seg_digits)
      );

   // The 7-segment display controller
   seg_display seg_display_
     (
      .clk(clk),
      .digits(seg_digits),
      .seven_seg(seven_seg),
      .seven_seg_en(seven_seg_en)
      );

   // The VGA display controller
   vga_display vga_display_
     (
      .clk(clk),
      .calib_done(mcb3_calib_done),
      .hsync(hsync),
      .vsync(vsync),
      .rgb(rgb),
      .mem_cmd_clk(c3_p2_cmd_clk),
      .mem_cmd_en(c3_p2_cmd_en),
      .mem_cmd_instr(c3_p2_cmd_instr),
      .mem_cmd_bl(c3_p2_cmd_bl),
      .mem_cmd_byte_addr(c3_p2_cmd_byte_addr),
      .mem_cmd_empty(c3_p2_cmd_empty),
      .mem_cmd_full(c3_p2_cmd_full),
      .mem_rd_clk(c3_p2_rd_clk),
      .mem_rd_en(c3_p2_rd_en),
      .mem_rd_data(c3_p2_rd_data),
      .mem_rd_full(c3_p2_rd_full),
      .mem_rd_empty(c3_p2_rd_empty),
      .mem_rd_count(c3_p2_rd_count),
      .mem_rd_overflow(c3_p2_rd_overflow),
      .mem_rd_error(c3_p2_rd_error)
      );

   // A writer to video memory
   wire pixel_wr_done;
   wire pixel_en;
   wire [7:0] pixel_rgb;
   wire [7:0] pixel_x;
   wire [7:0] pixel_y;
   pixel_writer pixel_writer_
     (
      .clk(clk),
      .calib_done(mcb3_calib_done),
      .clear_screen_done(clear_screen_done),
      .pixel_wr_done(pixel_wr_done),
      .pixel_en(pixel_en),
      .pixel_rgb(pixel_rgb),
      .pixel_x(pixel_x),
      .pixel_y(pixel_y),
      .mem_cmd_en(c3_p4_cmd_en),
      .mem_cmd_instr(c3_p4_cmd_instr),
      .mem_cmd_bl(c3_p4_cmd_bl),
      .mem_cmd_byte_addr(c3_p4_cmd_byte_addr),
      .mem_cmd_empty(c3_p4_cmd_empty),
      .mem_cmd_full(c3_p4_cmd_full),
      .mem_wr_en(c3_p4_wr_en),
      .mem_wr_mask(c3_p4_wr_mask),
      .mem_wr_data(c3_p4_wr_data),
      .mem_wr_full(c3_p4_wr_full),
      .mem_wr_empty(c3_p4_wr_empty),
      .mem_wr_count(c3_p4_wr_count),
      .mem_wr_underrun(c3_p4_wr_underrun),
      .mem_wr_error(c3_p4_wr_error)
      );

   // UART receiver, receives the first 64 KiB from the serial
   // port and writes it to RAM for the processor to execute
   uart_loader uart_loader_
     (
      .clk(clk),
      .calib_done(mcb3_calib_done),
      .load_done(uart_load_done),
      .progress(uart_progress),
      .rx(uart_rx),
      .mem_cmd_en(c3_p5_cmd_en),
      .mem_cmd_instr(c3_p5_cmd_instr),
      .mem_cmd_bl(c3_p5_cmd_bl),
      .mem_cmd_byte_addr(c3_p5_cmd_byte_addr),
      .mem_cmd_empty(c3_p5_cmd_empty),
      .mem_cmd_full(c3_p5_cmd_full),
      .mem_wr_en(c3_p5_wr_en),
      .mem_wr_mask(c3_p5_wr_mask),
      .mem_wr_data(c3_p5_wr_data),
      .mem_wr_full(c3_p5_wr_full),
      .mem_wr_empty(c3_p5_wr_empty),
      .mem_wr_count(c3_p5_wr_count),
      .mem_wr_underrun(c3_p5_wr_underrun),
      .mem_wr_error(c3_p5_wr_error)
      );

   // Data cache, handles loads and stores to and from
   // main memory for the processor
   wire                  cache_wr_en;
   wire [`ADDR_BITS-1:0] cache_wr_addr;
   wire [`WORD_BITS-1:0] cache_wr_data;
   wire                  cache_wr_done;
   wire                  cache_rd_en;
   wire [`ADDR_BITS-1:0] cache_rd_addr;
   wire [`WORD_BITS-1:0] cache_rd_data;
   wire                  cache_rd_done;
   data_cache data_cache_
     (
      .clk(clk),
      .boot_done(boot_done),
      .wr_en(cache_wr_en),
      .wr_addr(cache_wr_addr),
      .wr_data(cache_wr_data),
      .wr_done(cache_wr_done),
      .rd_en(cache_rd_en),
      .rd_addr(cache_rd_addr),
      .rd_data(cache_rd_data),
      .rd_done(cache_rd_done),
      .mem_cmd_en(c3_p0_cmd_en),
      .mem_cmd_instr(c3_p0_cmd_instr),
      .mem_cmd_bl(c3_p0_cmd_bl),
      .mem_cmd_byte_addr(c3_p0_cmd_byte_addr),
      .mem_cmd_empty(c3_p0_cmd_empty),
      .mem_cmd_full(c3_p0_cmd_full),
      .mem_wr_en(c3_p0_wr_en),
      .mem_wr_mask(c3_p0_wr_mask),
      .mem_wr_data(c3_p0_wr_data),
      .mem_wr_full(c3_p0_wr_full),
      .mem_wr_empty(c3_p0_wr_empty),
      .mem_wr_count(c3_p0_wr_count),
      .mem_wr_underrun(c3_p0_wr_underrun),
      .mem_wr_error(c3_p0_wr_error),
      .mem_rd_en(c3_p0_rd_en),
      .mem_rd_data(c3_p0_rd_data),
      .mem_rd_full(c3_p0_rd_full),
      .mem_rd_empty(c3_p0_rd_empty),
      .mem_rd_count(c3_p0_rd_count),
      .mem_rd_overflow(c3_p0_rd_overflow),
      .mem_rd_error(c3_p0_rd_error)
      );

   // Instruction cache, handles fetching instructions
   // for the processor to execute
   wire [`ADDR_BITS-1:0]  instr_ptr;
   wire [`INSTR_BITS-1:0] cur_instr;
   wire                   instr_valid;
   instr_cache instr_cache_
     (
      .clk(clk),
      .boot_done(boot_done),
      .instr_ptr(instr_ptr),
      .valid(instr_valid),
      .instr(cur_instr),
      .mem_cmd_en(c3_p3_cmd_en),
      .mem_cmd_instr(c3_p3_cmd_instr),
      .mem_cmd_bl(c3_p3_cmd_bl),
      .mem_cmd_byte_addr(c3_p3_cmd_byte_addr),
      .mem_cmd_empty(c3_p3_cmd_empty),
      .mem_cmd_full(c3_p3_cmd_full),
      .mem_rd_en(c3_p3_rd_en),
      .mem_rd_data(c3_p3_rd_data),
      .mem_rd_full(c3_p3_rd_full),
      .mem_rd_empty(c3_p3_rd_empty),
      .mem_rd_count(c3_p3_rd_count),
      .mem_rd_overflow(c3_p3_rd_overflow),
      .mem_rd_error(c3_p3_rd_error)
      );

   // The central processing unit that actually does
   // the executing of instructions
   processor processor_
     (
      .clk(clk),
      .boot_done(boot_done),
      .status(processor_status),
      // Instruction cache
      .instr_ptr(instr_ptr),
      .instr_valid(instr_valid),
      .cur_instr(cur_instr),
      // Data cache
      .cache_wr_en(cache_wr_en),
      .cache_wr_addr(cache_wr_addr),
      .cache_wr_data(cache_wr_data),
      .cache_wr_done(cache_wr_done),
      .cache_rd_en(cache_rd_en),
      .cache_rd_addr(cache_rd_addr),
      .cache_rd_data(cache_rd_data),
      .cache_rd_done(cache_rd_done),
      // Pixel writer
      .pixel_wr_done(pixel_wr_done),
      .pixel_en(pixel_en),
      .pixel_rgb(pixel_rgb),
      .pixel_x(pixel_x),
      .pixel_y(pixel_y),
      // Random data
      .rnd(rnd),
      // Millisecond timer
      .ms_time_rst(ms_time_rst),
      .ms_time(ms_time),
      // User input
      .buf_inputs(buf_inputs)
      );

   // Create an instance of the LPDDR memory interface
   s6_lpddr_ram main_ram_
     (
      // Main memory port 0 (data cache, read/write)
      .c3_p0_cmd_clk(clk),
      .c3_p0_cmd_en(c3_p0_cmd_en),
      .c3_p0_cmd_instr(c3_p0_cmd_instr),
      .c3_p0_cmd_bl(c3_p0_cmd_bl),
      .c3_p0_cmd_byte_addr(c3_p0_cmd_byte_addr),
      .c3_p0_cmd_empty(c3_p0_cmd_empty),
      .c3_p0_cmd_full(c3_p0_cmd_full),
      .c3_p0_wr_clk(clk),
      .c3_p0_wr_en(c3_p0_wr_en),
      .c3_p0_wr_mask(c3_p0_wr_mask),
      .c3_p0_wr_data(c3_p0_wr_data),
      .c3_p0_wr_full(c3_p0_wr_full),
      .c3_p0_wr_empty(c3_p0_wr_empty),
      .c3_p0_wr_count(c3_p0_wr_count),
      .c3_p0_wr_underrun(c3_p0_wr_underrun),
      .c3_p0_wr_error(c3_p0_wr_error),
      .c3_p0_rd_clk(clk),
      .c3_p0_rd_en(c3_p0_rd_en),
      .c3_p0_rd_data(c3_p0_rd_data),
      .c3_p0_rd_full(c3_p0_rd_full),
      .c3_p0_rd_empty(c3_p0_rd_empty),
      .c3_p0_rd_count(c3_p0_rd_count),
      .c3_p0_rd_overflow(c3_p0_rd_overflow),
      .c3_p0_rd_error(c3_p0_rd_error),

      // Main memory port 2 (VGA buffer, read only)
      .c3_p2_cmd_clk(c3_p2_cmd_clk),
      .c3_p2_cmd_en(c3_p2_cmd_en),
      .c3_p2_cmd_instr(c3_p2_cmd_instr),
      .c3_p2_cmd_bl(c3_p2_cmd_bl),
      .c3_p2_cmd_byte_addr(c3_p2_cmd_byte_addr),
      .c3_p2_cmd_empty(c3_p2_cmd_empty),
      .c3_p2_cmd_full(c3_p2_cmd_full),
      .c3_p2_rd_clk(c3_p2_rd_clk),
      .c3_p2_rd_en(c3_p2_rd_en),
      .c3_p2_rd_data(c3_p2_rd_data),
      .c3_p2_rd_full(c3_p2_rd_full),
      .c3_p2_rd_empty(c3_p2_rd_empty),
      .c3_p2_rd_count(c3_p2_rd_count),
      .c3_p2_rd_overflow(c3_p2_rd_overflow),
      .c3_p2_rd_error(c3_p2_rd_error),

      // Main memory port 3 (instruction cache, read only)
      .c3_p3_cmd_clk(clk),
      .c3_p3_cmd_en(c3_p3_cmd_en),
      .c3_p3_cmd_instr(c3_p3_cmd_instr),
      .c3_p3_cmd_bl(c3_p3_cmd_bl),
      .c3_p3_cmd_byte_addr(c3_p3_cmd_byte_addr),
      .c3_p3_cmd_empty(c3_p3_cmd_empty),
      .c3_p3_cmd_full(c3_p3_cmd_full),
      .c3_p3_rd_clk(clk),
      .c3_p3_rd_en(c3_p3_rd_en),
      .c3_p3_rd_data(c3_p3_rd_data),
      .c3_p3_rd_full(c3_p3_rd_full),
      .c3_p3_rd_empty(c3_p3_rd_empty),
      .c3_p3_rd_count(c3_p3_rd_count),
      .c3_p3_rd_overflow(c3_p3_rd_overflow),
      .c3_p3_rd_error(c3_p3_rd_error),

      // Main memory port 4 (pixel writer, write only)
      .c3_p4_cmd_clk(clk),
      .c3_p4_cmd_en(c3_p4_cmd_en),
      .c3_p4_cmd_instr(c3_p4_cmd_instr),
      .c3_p4_cmd_bl(c3_p4_cmd_bl),
      .c3_p4_cmd_byte_addr(c3_p4_cmd_byte_addr),
      .c3_p4_cmd_empty(c3_p4_cmd_empty),
      .c3_p4_cmd_full(c3_p4_cmd_full),
      .c3_p4_wr_clk(clk),
      .c3_p4_wr_en(c3_p4_wr_en),
      .c3_p4_wr_mask(c3_p4_wr_mask),
      .c3_p4_wr_data(c3_p4_wr_data),
      .c3_p4_wr_full(c3_p4_wr_full),
      .c3_p4_wr_empty(c3_p4_wr_empty),
      .c3_p4_wr_count(c3_p4_wr_count),
      .c3_p4_wr_underrun(c3_p4_wr_underrun),
      .c3_p4_wr_error(c3_p4_wr_error),

      // Main memory port 5 (SD card reader, write only)
      .c3_p5_cmd_clk(clk),
      .c3_p5_cmd_en(c3_p5_cmd_en),
      .c3_p5_cmd_instr(c3_p5_cmd_instr),
      .c3_p5_cmd_bl(c3_p5_cmd_bl),
      .c3_p5_cmd_byte_addr(c3_p5_cmd_byte_addr),
      .c3_p5_cmd_empty(c3_p5_cmd_empty),
      .c3_p5_cmd_full(c3_p5_cmd_full),
      .c3_p5_wr_clk(clk),
      .c3_p5_wr_en(c3_p5_wr_en),
      .c3_p5_wr_mask(c3_p5_wr_mask),
      .c3_p5_wr_data(c3_p5_wr_data),
      .c3_p5_wr_full(c3_p5_wr_full),
      .c3_p5_wr_empty(c3_p5_wr_empty),
      .c3_p5_wr_count(c3_p5_wr_count),
      .c3_p5_wr_underrun(c3_p5_wr_underrun),
      .c3_p5_wr_error(c3_p5_wr_error),

      // Memory interface signals
      .mcb3_dram_dq(mcb3_dram_dq),
      .mcb3_dram_a(mcb3_dram_a),
      .mcb3_dram_ba(mcb3_dram_ba),
      .mcb3_dram_cke(mcb3_dram_cke),
      .mcb3_dram_ras_n(mcb3_dram_ras_n),
      .mcb3_dram_cas_n(mcb3_dram_cas_n),
      .mcb3_dram_we_n(mcb3_dram_we_n),
      .mcb3_dram_dm(mcb3_dram_dm),
      .mcb3_dram_udqs(mcb3_dram_udqs),
      .mcb3_rzq(mcb3_rzq),
      .mcb3_dram_udm(mcb3_dram_udm),
      .c3_sys_clk(clk),
      .c3_sys_rst_n(c3_sys_rst_n),
      .c3_calib_done(mcb3_calib_done),
      .mcb3_dram_dqs(mcb3_dram_dqs),
      .mcb3_dram_ck(mcb3_dram_ck),
      .mcb3_dram_ck_n(mcb3_dram_ck_n)
      );

endmodule
