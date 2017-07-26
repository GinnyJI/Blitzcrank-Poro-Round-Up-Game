module blitz_pos (
	input go_up,
	input go_down,
	input clk,
	input frame,
	input resetn,
	input grab,
	input grab_success,
	output reg [8:0] blitz_hook_x,
	output reg [7:0] blitz_hook_y,
	output reg [7:0] y
	// output reg writeEn
	);
	
	localparam S_SATIONARY =3'd0,
			   S_MOVE_UP   =3'd1,
			   S_MOVE_DOWN =3'd2,
			   S_HOOK_EXTENTION  = 3'd3,
			   S_HOOK_RETRACTION = 3'd4;
			   
	localparam MAX_EXTENSION = 7'd94,
			   MIN_EXTENSION = 7'd42,
			   grabV = 9'd2;
	
	reg [2:0] current_state, next_state;
	reg up_done, down_done;
		
	// next state logic
	always @(*) begin
		case(current_state)
			S_SATIONARY: next_state = (go_up&&(y>8'd48)) ? S_MOVE_UP : ((go_down&&(y<8'd138)) ? S_MOVE_DOWN : (grab ? S_HOOK_EXTENTION : S_SATIONARY));
			S_MOVE_UP: next_state = up_done ? S_SATIONARY : S_MOVE_UP;
			S_MOVE_DOWN : next_state = down_done ? S_SATIONARY : S_MOVE_DOWN;
			S_HOOK_EXTENTION : next_state = (grab_success||(blitz_hook_x >= MAX_EXTENSION)) ? S_HOOK_RETRACTION : S_HOOK_EXTENTION;
			S_HOOK_RETRACTION : next_state = (blitz_hook_x <= MIN_EXTENSION) ? S_SATIONARY : S_HOOK_RETRACTION;
			default: next_state = S_SATIONARY;
		endcase
	end
	
	
	//enable signals
	always@ (posedge clk) begin
		if (!resetn) begin
			y <= 8'd120 - 8'b1;
			up_done <= 0;
			down_done <= 0;
			blitz_hook_x <= 9'd42;
			blitz_hook_y <= 0; //8'd130 - 8'b1;
		end 
		else begin
			case(current_state)
				S_SATIONARY: begin 
					up_done <= 0;
					down_done <= 0;
					blitz_hook_x <= 9'd42;
					blitz_hook_y <= 0;
				end
				S_MOVE_UP: if(frame) begin
					y <= y - 8'd2;
					up_done <= 1;
				end 
				S_MOVE_DOWN: if(frame) begin 
					y <= y + 8'd2;
					down_done <= 1;
				end
				S_HOOK_EXTENTION: if(frame) begin
					blitz_hook_x <= blitz_hook_x + grabV;
					blitz_hook_y <= y + 8'd22;
				end
				S_HOOK_RETRACTION: if(frame) begin
					blitz_hook_x <= blitz_hook_x - grabV - grabV;
					blitz_hook_y <= y + 8'd22;
				end
			endcase
		
		end 
		
	end 
	
	// current_state registers
    always@(posedge clk)
    begin
        if(!resetn)
            current_state <= S_SATIONARY;
        else
            current_state <= next_state;
    end 
	
endmodule 
