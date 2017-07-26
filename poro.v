module poro_pos (
	input clk,
	input frame,
	input resetn,
	input grab_success,
	input hold,
	output score,//reg score,
	output reg isDead,
	output reg [8:0] x
	);
	
	localparam	grabV = 4'd4, //4 pixels per frame
				poroV = 4'd1; //1 pixels per frame
	
	//reg grab_count;
	
	reg [3:0] velocity;
	
    always@(posedge clk)
    begin
	if(x>=9'd43)
		isDead = 1'b0;
	if(grab_success)begin
		velocity = grabV;
		//grab_count = 1'b1;
		end
	if((!resetn)||hold)begin
		//grab_count = 1'b0;
		velocity = poroV;
		isDead = 1'b0;
		if(frame) begin
			x = 9'd319;
		end
	end
	if(x<9'd43)begin
		x = 9'd319;
		isDead = !score;
		velocity = poroV;
	end
	if(frame)
		x = x - velocity;
	end

	assign score = (velocity == grabV);
	/*
	always@(posedge clk)
	begin
		if(!resetn || (!grab_count))
		score = 1'b0;
		else if(grab_count)
		begin
			score = 1'b1;
		end
	end	
	*/
endmodule 

