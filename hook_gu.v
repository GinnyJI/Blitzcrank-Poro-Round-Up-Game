module blitz_hook_gu(
		clk,						
		x_in,
		y_in,
		resetn,
		plot,
		
		colour_out,
		x_out,
		y_out,
		writeEn,
		done
	);

	input			clk;
	input	[8:0]	x_in;
	input	[7:0]	y_in;
	input			resetn;
	input			plot;
	// Declare your inputs and outputs here
	output	[2:0]	colour_out;
	output	[8:0]	x_out;
	output	[7:0]	y_out;	
	output			writeEn;
	output			done;
	
	wire [3:0] x_increment; //0-7
	wire [3:0] y_increment; //0-7
	wire ld_xy;
	
	hook_finite_state_machine f1(
		.plot(plot),
		.clk(clk),
		.y_in(y_in),
		.resetn(resetn),
		.writeEn(writeEn),
		.x_increment(x_increment),
		.y_increment(y_increment),
		.ld_xy(ld_xy),
		.done(done)
	);
	
	hook_data_path dp1(
	.x_in(x_in),
	.y_in(y_in),
	.resetn(resetn),
	.clk(clk),
	.x_increment(x_increment),
	.y_increment(y_increment),
	.ld_xy(ld_xy),
	
	.x_out(x_out),
	.y_out(y_out),
	.colour_out(colour_out)
	);
		
endmodule

module hook_finite_state_machine(
		input plot,
		input clk,
		input resetn,
		input [7:0] y_in,
		output reg writeEn,
		output reg [3:0] x_increment,  //0-7
		output reg [3:0] y_increment,  //0-7
		output reg ld_xy,
		output reg done
	);
	
	reg [4:0] current_state, next_state;
	reg [7:0] counter;
	
	localparam  S_LOAD_XY       = 5'd0,
                S_CYCLE_0       = 5'd1,
                S_CYCLE_1       = 5'd2,
				S_CYCLE_DONE	= 5'd3,
				size			= 8'd255;

					 
	
	always@(*)
    begin: state_table 
            case (current_state)
                S_LOAD_XY: next_state = plot ? ((y_in==0) ? S_CYCLE_DONE : S_CYCLE_0) : S_LOAD_XY; // Loop in current state until value is input
                S_CYCLE_0: next_state = S_CYCLE_1;
				S_CYCLE_1: next_state = (counter < size) ? S_CYCLE_0 : S_CYCLE_DONE;
				S_CYCLE_DONE: next_state = S_LOAD_XY;
				
            default:     next_state = S_LOAD_XY;
		endcase
    end // state_table
	 
	 
	
	always @(*)
    begin: enable_signals
        // By default make all our signals 0
		writeEn = 1'b0;
		x_increment = 4'b0;
		y_increment = 4'b0;
		ld_xy = 1'b0;
		done = 1'b0;
		
        case (current_state)
            S_LOAD_XY: begin
                ld_xy = 1'b1;
                end
            S_CYCLE_0: begin 
				x_increment = counter[3:0];
				y_increment = counter[7:4];
            end
			S_CYCLE_1: begin 
				writeEn = 1'b1;
            end
			S_CYCLE_DONE: begin
				done = 1;
			end
			
        endcase
    end 
	   
   always @(posedge clk)
   begin
		if(!resetn || ((current_state != S_CYCLE_1) && (current_state != S_CYCLE_0)))
	      counter <= 6'b0;
		if (current_state == S_CYCLE_1)
	      counter <= counter + 1'b1;
   end
   
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_LOAD_XY;
        else
            current_state <= next_state;
    end // state_FFS
	
endmodule

module hook_data_path(
	input [8:0] x_in,
	input [7:0] y_in,
	input resetn,
	input clk,

	input [3:0] x_increment, //0-7 depents on size
	input [3:0] y_increment, //0-7
	input ld_xy,
	
	output reg [8:0] x_out,
	output reg [7:0] y_out,
	output [2:0] colour_out
	);
	
	reg [8:0] last_x;
	reg [7:0] last_y;
	
	wire [7:0] address;
	assign address = {y_increment,x_increment};
	hook_image hi1(address,clk,3'b0,1'b0,colour_out);
	
	always@(posedge clk) begin
		if(!resetn) begin
			x_out <= 9'b0;
			y_out <= 8'b0;
			last_x <= 9'b0;
			last_y <= 8'b0;
			//colour_out <= 3'b0;
		end
		else if(ld_xy) begin
			last_x <= x_in - 9'd8;
			last_y <= y_in;
			end
		else begin
				x_out <= (last_x + x_increment);
				y_out <= (last_y + y_increment);
				//colour_out <= ((last_y + y_increment) >= 8'd240 ||(last_x + x_increment >= 9'd320)) ? 3'b100 : 3'b100;  //set it to yellow temp
		end
	end
endmodule