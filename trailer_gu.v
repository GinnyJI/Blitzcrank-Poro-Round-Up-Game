//gu for background needs a ram with img imf in datapath

module trailer_gu
	(
		frame,
		clk,						
		resetn,
		plot,
		
		colour_out,
		x_out,
		y_out,
		writeEn,
		done
	);
	input			frame;
	input			clk;
	input			resetn;
	input			plot;
	// Declare your inputs and outputs here
	output	[2:0]	colour_out;
	output	[8:0]	x_out;
	output	[7:0]	y_out;	
	output			writeEn;
	output			done;

	
	wire [8:0] x_increment;
	wire [7:0] y_increment;
	
	finite_state_machine f2(
		.plot(plot),
		.clk(clk),
		.resetn(resetn),
		.writeEn(writeEn),
		.x_increment(x_increment),
		.y_increment(y_increment),
		.done(done)
	);
	
	data_path dp2(
	.frame(frame),
	.resetn(resetn),
	.clk(clk),
	.x_increment(x_increment),
	.y_increment(y_increment),
	
	.x_out(x_out),
	.y_out(y_out),
	.colour_out(colour_out)
	);
	
endmodule

module data_path(
	input frame,
	input resetn,
	input clk,

	input [8:0] x_increment, // 320*240
	input [7:0] y_increment, // 320*240
	
	output reg [8:0] x_out,
	output reg [7:0] y_out,
	output [2:0] colour_out
	);

	wire [17:0] address;
	assign address = x_increment + y_increment * 10'd320;
	trailer_image ti(address,clk,3'b0,1'b0,colour_out);	
	
	
	always@(posedge clk) begin
		if(!resetn) begin
			x_out <= 9'b0;
			y_out <= 8'b0;
			//colour_out <= 3'b0;
		end
		else begin
				x_out <= x_increment;
				y_out <= y_increment;
			//	colour_out <= 3'b000; //set in to blk temp
		end
	end
endmodule