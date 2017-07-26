module grab_check(
	input grab,
	input [8:0] blitz_hook_x,
	input [7:0] blitz_hook_y,
	input [8:0] poro_x,
	input [7:0] poro_y,
	output grab_success
	);
	
	wire x_match, y_match;
	
	assign y_match = (poro_y >= blitz_hook_y - 9'd14) && (poro_y <= blitz_hook_y + 9'd10);
	assign x_match = poro_x == blitz_hook_x;
	
	assign grab_success = x_match && y_match;
endmodule

