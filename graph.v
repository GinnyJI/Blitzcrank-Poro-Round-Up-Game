// top module

module graph
	(
		CLOCK_50,						//	On Board 50 MHz
		KEY,
		SW,
		HEX0,
		HEX1,
		HEX2,
		HEX3,
		// Your inputs and outputs here
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);
	output [6:0] HEX0, HEX1, HEX2, HEX3;
	input			CLOCK_50;				//	50 MHz
	input	[3:0]	KEY;
	input	[9:0]	SW;
	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	reg go_up, go_down, grab;
	reg go_up_buf, go_down_buf, grab_buf;
	reg restart;
	assign resetn = KEY[0] && !restart;
	
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.

	reg [2:0] colour;
	reg [8:0] x;
	reg [7:0] y;
	
	
	wire [18:0]	writeEn; //0 -> blitz, 1-9 -> poro, 10 ->BG, ll -> hook, 12 -> arm, 13->trailer, 14->hp, 15-17 -> scores, 18 -> gameover
	reg writeEn_vga;
	
	reg [18:0]	plot; //0 -> blitz, 1-9 -> poro, 10 ->BG, ll -> hook, 12 -> arm, 13 -> trailer, 14 -> hp, 15-17 -> scores, 18 -> gameover
	wire [18:0]  done; //0 -> blitz, 1-9 -> poro, 10 ->BG, ll -> hook, 12 -> arm, 13 -> trailer, 14 -> hp, 15-17 -> scores, 18 -> gameover
	wire clk;
	wire frame; // empty for now
	
	DelayCounter dc(.clock(CLOCK_50), .reset_n(resetn), .maxcount(28'd833334), .enable(frame)); //60 fps
	
	assign clk = CLOCK_50;
	
	always@(posedge clk) begin
		go_up_buf <= ~KEY[3];
		go_down_buf <= ~KEY[2];
		grab_buf <= gameOver ? 1'b0 : ~KEY[1];
	end 
	
	always@(posedge clk) begin
		go_up <= go_up_buf;
		go_down <=go_down_buf;
		grab <= grab_buf;
	end
	
	//========================= control and gu connection =================================
	wire [7:0] blitz_y, blitz_hook_y;
	wire [8:0] blitz_hook_x;
	wire [7:0] plot_y_b, plot_y_bh, plot_y_ba, plot_y_hp; //bh for blitz hook, ba for arm
	wire [8:0] plot_x_b, plot_x_bh, plot_x_ba, plot_x_hp;
	wire [2:0] colour_b, colour_bh, colour_ba, colour_hp;
	
	wire [8:0] grab_success;
	wire blitz_grab_success = |grab_success;
	
	// *scores so,st,sh: score ones, tens, hundreds
	wire [7:0] plot_y_so, plot_y_st, plot_y_sh;
	wire [8:0] plot_x_so, plot_x_st, plot_x_sh;
	wire [2:0] colour_so, colour_st, colour_sh;
	score_gu sgu_ones(clk,9'd176,gameOver?9'd30:9'd0,score_counter_ones,gameOver,resetn,plot[15],colour_so,plot_x_so,plot_y_so,writeEn[15],done[15]);
	score_gu sgu_tens(clk,9'd144,gameOver?9'd30:9'd0,score_counter_tens,gameOver,resetn,plot[16],colour_st,plot_x_st,plot_y_st,writeEn[16],done[16]);
	score_gu sgu_hdrs(clk,9'd112,gameOver?9'd30:9'd0,score_counter_hundreds,gameOver,resetn,plot[17],colour_sh,plot_x_sh,plot_y_sh,writeEn[17],done[17]);
	
	// *gameOver
	wire [7:0] plot_y_go;
	wire [8:0] plot_x_go;
	wire [2:0] colour_go;
	gameover_gu go_gu(frame,clk,resetn,plot[18],colour_go,plot_x_go,plot_y_go,writeEn[18],done[18]);
	
	// *blitz
	blitz_pos 		blitz(go_up,go_down,clk,frame,resetn,grab, blitz_grab_success,blitz_hook_x,blitz_hook_y,blitz_y);
	blitz_gu		b_gu(clk,blitz_y,resetn,plot[0],colour_b,plot_x_b,plot_y_b,writeEn[0],done[0]);
	blitz_hook_gu	bh_gu(clk,blitz_hook_x,blitz_hook_y,resetn,plot[11],colour_bh,plot_x_bh,plot_y_bh,writeEn[11],done[11]);
	blitz_arm_gu	ba_gu(clk,blitz_hook_x,blitz_hook_y,resetn,plot[12],colour_ba,plot_x_ba,plot_y_ba,writeEn[12],done[12]);
	
	// -hp
	reg [2:0] death_counter;
	
	always@(posedge clk)begin
		if(!resetn)begin
			gameOver = 1'b0;
			death_counter = 3'd0;
		end
		if(isDead_poro[0])
			death_counter = (death_counter + 1'b1);
		if(isDead_poro[1])
			death_counter = (death_counter + 1'b1);
		if(isDead_poro[2])
			death_counter = (death_counter + 1'b1);
		if(isDead_poro[3])
			death_counter = (death_counter + 1'b1);
		if(isDead_poro[4])
			death_counter = (death_counter + 1'b1);
		if(isDead_poro[5])
			death_counter = (death_counter + 1'b1);
		if(isDead_poro[6])
			death_counter = (death_counter + 1'b1);
		if(isDead_poro[7])
			death_counter = (death_counter + 1'b1);
		if(isDead_poro[8])
			death_counter = (death_counter + 1'b1);
		if(death_counter >= 3'd5) begin
			death_counter = 3'd5; //gameover
			gameOver = 1'b1;
			end
		
		
	end
	
	reg gameOver;
	
	wire [2:0] health_points;
	assign health_points = (!gameOver) ? (3'd5 - death_counter) : 3'd0;
	hp_gu  	hpgu1(clk,blitz_y,health_points,resetn,plot[14],colour_hp,plot_x_hp,plot_y_hp,writeEn[14],done[14]);
	
	
	// *poros

	wire [8:0] hold;
	wire [8:0] score_p;
	
	wire [8:0] x_p0;
	wire [8:0] x_p1;
	wire [8:0] x_p2;
	wire [8:0] x_p3;
	wire [8:0] x_p4;
	wire [8:0] x_p5;
	wire [8:0] x_p6;
	wire [8:0] x_p7;
	wire [8:0] x_p8;
	
	wire [7:0] y_p0;
	wire [7:0] y_p1;
	wire [7:0] y_p2;
	wire [7:0] y_p3;
	wire [7:0] y_p4;
	wire [7:0] y_p5;
	wire [7:0] y_p6;
	wire [7:0] y_p7;
	wire [7:0] y_p8;
	
	wire [2:0] colour_p0 ;
	wire [2:0] colour_p1 ;
	wire [2:0] colour_p2 ;
	wire [2:0] colour_p3 ;
	wire [2:0] colour_p4 ;
	wire [2:0] colour_p5 ;
	wire [2:0] colour_p6 ;
	wire [2:0] colour_p7 ;
	wire [2:0] colour_p8 ;
	
	wire [8:0] plot_x_p0;
	wire [8:0] plot_x_p1;
	wire [8:0] plot_x_p2;
	wire [8:0] plot_x_p3;
	wire [8:0] plot_x_p4;
	wire [8:0] plot_x_p5;
	wire [8:0] plot_x_p6;
	wire [8:0] plot_x_p7;
	wire [8:0] plot_x_p8;
	           
	wire [7:0] plot_y_p0;
	wire [7:0] plot_y_p1;
	wire [7:0] plot_y_p2;
	wire [7:0] plot_y_p3;
	wire [7:0] plot_y_p4;
	wire [7:0] plot_y_p5;
	wire [7:0] plot_y_p6;
	wire [7:0] plot_y_p7;
	wire [7:0] plot_y_p8;
	
	wire [8:0] isDead_poro;
	
	
	poro_pos p0(clk, frame, resetn, grab_success[0], hold[0], score_p[0], isDead_poro[0], x_p0);
	poro_pos p1(clk, frame, resetn, grab_success[1], hold[1], score_p[1], isDead_poro[1], x_p1);
	poro_pos p2(clk, frame, resetn, grab_success[2], hold[2], score_p[2], isDead_poro[2], x_p2);
	poro_pos p3(clk, frame, resetn, grab_success[3], hold[3], score_p[3], isDead_poro[3], x_p3);
	poro_pos p4(clk, frame, resetn, grab_success[4], hold[4], score_p[4], isDead_poro[4], x_p4);
	poro_pos p5(clk, frame, resetn, grab_success[5], hold[5], score_p[5], isDead_poro[5], x_p5);
	poro_pos p6(clk, frame, resetn, grab_success[6], hold[6], score_p[6], isDead_poro[6], x_p6);
	poro_pos p7(clk, frame, resetn, grab_success[7], hold[7], score_p[7], isDead_poro[7], x_p7);
	poro_pos p8(clk, frame, resetn, grab_success[8], hold[8], score_p[8], isDead_poro[8], x_p8);
	
	reg [8:0] hold_counter;
	
	assign hold[0] = (!(hold_counter >= 9'd0))||SW[9];
	assign hold[1] = (!(hold_counter >= 9'd63))||SW[8];
	assign hold[2] = (!(hold_counter >= 9'd127))||SW[7];
	assign hold[3] = (!(hold_counter >= 9'd191))||SW[6];
	assign hold[4] = (!(hold_counter >= 9'd255))||SW[5];
	assign hold[5] = (!(hold_counter >= 9'd319))||SW[4];
	assign hold[6] = (!(hold_counter >= 9'd383))||SW[3];
	assign hold[7] = (!(hold_counter >= 9'd447))||SW[2];
	assign hold[8] = (!(hold_counter >= 9'd511))||SW[1];
	
	//hold counter
	always@ (posedge clk) 
	if(frame) begin
		if (!resetn)
			hold_counter <= 9'd0;
		else if (hold_counter < 9'd511)
			hold_counter <= hold_counter + 9'd1;
	end
	
	// randomize y later temp //23 pixels distance starting 48+22 ending 138+22
	assign y_p0 = 8'd70;
	assign y_p1 = 8'd70;
	assign y_p2 = 8'd70;
	assign y_p3 = 8'd115;
	assign y_p4 = 8'd115;
	assign y_p5 = 8'd115;
	assign y_p6 = 8'd160;
	assign y_p7 = 8'd160;
	assign y_p8 = 8'd160;
	
	// *connect hook to poros
	grab_check gc0(grab,blitz_hook_x,blitz_hook_y,plot_x_p0,y_p0,grab_success[0]);
	grab_check gc1(grab,blitz_hook_x,blitz_hook_y,plot_x_p1,y_p1,grab_success[1]);
	grab_check gc2(grab,blitz_hook_x,blitz_hook_y,plot_x_p2,y_p2,grab_success[2]);
	grab_check gc3(grab,blitz_hook_x,blitz_hook_y,plot_x_p3,y_p3,grab_success[3]);
	grab_check gc4(grab,blitz_hook_x,blitz_hook_y,plot_x_p4,y_p4,grab_success[4]);
	grab_check gc5(grab,blitz_hook_x,blitz_hook_y,plot_x_p5,y_p5,grab_success[5]);
	grab_check gc6(grab,blitz_hook_x,blitz_hook_y,plot_x_p6,y_p6,grab_success[6]);
	grab_check gc7(grab,blitz_hook_x,blitz_hook_y,plot_x_p7,y_p7,grab_success[7]);
	grab_check gc8(grab,blitz_hook_x,blitz_hook_y,plot_x_p8,y_p8,grab_success[8]);

	
	// *poro_gu  	
	poro_gu p_gu0(clk,x_p0,y_p0,resetn,plot[1],colour_p0,plot_x_p0,plot_y_p0,writeEn[1],done[1]);
	poro_gu p_gu1(clk,x_p1,y_p1,resetn,plot[2],colour_p1,plot_x_p1,plot_y_p1,writeEn[2],done[2]);
	poro_gu p_gu2(clk,x_p2,y_p2,resetn,plot[3],colour_p2,plot_x_p2,plot_y_p2,writeEn[3],done[3]);
	poro_gu p_gu3(clk,x_p3,y_p3,resetn,plot[4],colour_p3,plot_x_p3,plot_y_p3,writeEn[4],done[4]);
	poro_gu p_gu4(clk,x_p4,y_p4,resetn,plot[5],colour_p4,plot_x_p4,plot_y_p4,writeEn[5],done[5]);
	poro_gu p_gu5(clk,x_p5,y_p5,resetn,plot[6],colour_p5,plot_x_p5,plot_y_p5,writeEn[6],done[6]);
	poro_gu p_gu6(clk,x_p6,y_p6,resetn,plot[7],colour_p6,plot_x_p6,plot_y_p6,writeEn[7],done[7]);
	poro_gu p_gu7(clk,x_p7,y_p7,resetn,plot[8],colour_p7,plot_x_p7,plot_y_p7,writeEn[8],done[8]);
	poro_gu p_gu8(clk,x_p8,y_p8,resetn,plot[9],colour_p8,plot_x_p8,plot_y_p8,writeEn[9],done[9]);
		
	// *background_gu  
	wire [8:0] plot_x_bg;
	wire [7:0] plot_y_bg;	
	wire [2:0] colour_bg ;
	background_gu bg_gu(frame,clk,resetn,plot[10],colour_bg,plot_x_bg,plot_y_bg,writeEn[10],done[10]);
	
	// *trailer_gu
	wire [8:0] plot_x_tl;
	wire [7:0] plot_y_tl;	
	wire [2:0] colour_tl ;
	trailer_gu tl_gu(frame,clk,resetn,plot[13],colour_tl,plot_x_tl,plot_y_tl,writeEn[13],done[13]);
	
	// *FSM
	reg [4:0] current_state, next_state;
	localparam  S_PLOT_WAIT	     		= 5'd0, 
				S_PLOT_BG	     		= 5'd1, 
                S_PLOT_P0        		= 5'd2, 
				S_PLOT_P1        		= 5'd3, 
				S_PLOT_P2 		 		= 5'd4, 
				S_PLOT_P3        		= 5'd5, 
				S_PLOT_P4        		= 5'd6, 
				S_PLOT_P5        		= 5'd7, 
				S_PLOT_P6        		= 5'd8, 
				S_PLOT_P7        		= 5'd9,
				S_PLOT_P8        		= 5'd10,
				S_PLOT_BLITZ     		= 5'd11,
				S_PLOT_BLITZ_HOOK		= 5'd12,
				S_PLOT_BLITZ_ARM		= 5'd13,
				S_PLOT_TRAILER			= 5'd14,
				S_RESTART				= 5'd15,
				S_PLOT_HP				= 5'd16,
				S_PLOT_ONES				= 5'd17,
				S_PLOT_TENS				= 5'd18,
				S_PLOT_HUNDRES			= 5'd19,
				S_PLOT_GAMEOVER			= 5'd20;
			
				
	always@(*)
    begin: state_table 
            case (current_state)
				S_PLOT_TRAILER: next_state = (swap) ? S_RESTART : S_PLOT_TRAILER;
				S_RESTART: next_state = S_PLOT_WAIT;
				S_PLOT_WAIT: next_state = (swap) ? S_PLOT_BG : S_PLOT_WAIT;
				S_PLOT_BG:	 next_state = done[10] ? S_PLOT_P0 : S_PLOT_BG;
				S_PLOT_P0: next_state = done[1] ? S_PLOT_P1: S_PLOT_P0;   
				S_PLOT_P1: next_state = done[2] ? S_PLOT_P2: S_PLOT_P1;
				S_PLOT_P2: next_state = done[3] ? S_PLOT_P3: S_PLOT_P2;
				S_PLOT_P3: next_state = done[4] ? S_PLOT_P4: S_PLOT_P3;
				S_PLOT_P4: next_state = done[5] ? S_PLOT_P5: S_PLOT_P4;
				S_PLOT_P5: next_state = done[6] ? S_PLOT_P6: S_PLOT_P5;
				S_PLOT_P6: next_state = done[7] ? S_PLOT_P7: S_PLOT_P6;
				S_PLOT_P7: next_state = done[8] ? S_PLOT_P8: S_PLOT_P7;
				S_PLOT_P8: next_state = done[9] ? S_PLOT_BLITZ_ARM: S_PLOT_P8;
				S_PLOT_BLITZ_ARM: next_state = done[12] ? S_PLOT_BLITZ_HOOK: S_PLOT_BLITZ_ARM;
				S_PLOT_BLITZ_HOOK: next_state = done[11] ? S_PLOT_BLITZ: S_PLOT_BLITZ_HOOK;		
				S_PLOT_BLITZ: next_state = done[0] ? S_PLOT_HP: S_PLOT_BLITZ;
				S_PLOT_HP: next_state = done[14] ? S_PLOT_GAMEOVER: S_PLOT_HP;
				S_PLOT_GAMEOVER:next_state = gameOver ? (done[18] ? S_PLOT_ONES: S_PLOT_GAMEOVER) : S_PLOT_ONES;
				S_PLOT_ONES:	next_state = done[15] ? S_PLOT_TENS: S_PLOT_ONES;
				S_PLOT_TENS: 	next_state = done[16] ? S_PLOT_HUNDRES: S_PLOT_TENS;
				S_PLOT_HUNDRES: next_state = done[17] ? S_PLOT_WAIT: S_PLOT_HUNDRES;
            default:     next_state = S_PLOT_WAIT;
		endcase
    end // state_table
	
	always@(*)
    begin
	plot = 19'b0;
	restart = 1'b0;
			case (current_state)				
				S_PLOT_BG:		plot[10]=1'b1;
				S_PLOT_BLITZ: 	plot[0]=1'b1;
				S_PLOT_P0: 		plot[1]=1'b1;
				S_PLOT_P1: 		plot[2]=1'b1;
				S_PLOT_P2: 		plot[3]=1'b1;
				S_PLOT_P3: 		plot[4]=1'b1;
				S_PLOT_P4: 		plot[5]=1'b1;
				S_PLOT_P5: 		plot[6]=1'b1;
				S_PLOT_P6: 		plot[7]=1'b1;
				S_PLOT_P7: 		plot[8]=1'b1;
				S_PLOT_P8: 		plot[9]=1'b1;
				S_PLOT_BLITZ_HOOK: plot[11]=1'b1;
				S_PLOT_BLITZ_ARM:  plot[12]=1'b1;
				S_PLOT_HP:		plot[14]=1'b1;
				S_RESTART:		restart = 1'b1;
				S_PLOT_TRAILER:	plot[13]=1'b1;
				S_PLOT_ONES:   	plot[15]=1'b1;
				S_PLOT_TENS:  	plot[16]=1'b1;
				S_PLOT_HUNDRES: plot[17]=1'b1;
				S_PLOT_GAMEOVER: plot[18]=1'b1;
				
				default: plot = 19'b0;
		endcase
    end 

	// current_state registers
    always@(posedge clk)
    begin
		if(SW[0] == 0)
		    current_state <= S_PLOT_TRAILER;
        else
            current_state <= next_state;
    end 
	// *mux
	always@(posedge clk)
    begin
			case (current_state)
				S_PLOT_BG:	    	begin x=plot_x_bg; y=plot_y_bg; colour=colour_bg; writeEn_vga=writeEn[10];		end
				S_PLOT_BLITZ:   	begin x=plot_x_b;  y=plot_y_b;  colour=colour_b;  writeEn_vga=writeEn[0];  		end
				S_PLOT_BLITZ_HOOK:  begin x=plot_x_bh; y=plot_y_bh; colour=colour_bh; writeEn_vga=writeEn[11];		end
				S_PLOT_BLITZ_ARM:   begin x=plot_x_ba; y=plot_y_ba; colour=colour_ba; writeEn_vga=writeEn[12];		end
				S_PLOT_P0:      	begin x=plot_x_p0; y=plot_y_p0; colour=colour_p0; writeEn_vga=writeEn[1];		end
				S_PLOT_P1:      	begin x=plot_x_p1; y=plot_y_p1; colour=colour_p1; writeEn_vga=writeEn[2];		end
				S_PLOT_P2:      	begin x=plot_x_p2; y=plot_y_p2; colour=colour_p2; writeEn_vga=writeEn[3];		end
				S_PLOT_P3:      	begin x=plot_x_p3; y=plot_y_p3; colour=colour_p3; writeEn_vga=writeEn[4];		end
				S_PLOT_P4:      	begin x=plot_x_p4; y=plot_y_p4; colour=colour_p4; writeEn_vga=writeEn[5];		end
				S_PLOT_P5:      	begin x=plot_x_p5; y=plot_y_p5; colour=colour_p5; writeEn_vga=writeEn[6];		end
				S_PLOT_P6:      	begin x=plot_x_p6; y=plot_y_p6; colour=colour_p6; writeEn_vga=writeEn[7];		end
				S_PLOT_P7:      	begin x=plot_x_p7; y=plot_y_p7; colour=colour_p7; writeEn_vga=writeEn[8];		end
				S_PLOT_P8:      	begin x=plot_x_p8; y=plot_y_p8; colour=colour_p8; writeEn_vga=writeEn[9];		end
				S_PLOT_HP:      	begin x=plot_x_hp; y=plot_y_hp; colour=colour_hp; writeEn_vga=writeEn[14];		end
				S_PLOT_TRAILER:   	begin x=plot_x_tl; y=plot_y_tl; colour=colour_tl; writeEn_vga=writeEn[13];		end
				S_PLOT_ONES:   		begin x=plot_x_so; y=plot_y_so; colour=colour_so; writeEn_vga=writeEn[15];		end
				S_PLOT_TENS:  	 	begin x=plot_x_st; y=plot_y_st; colour=colour_st; writeEn_vga=writeEn[16];		end
				S_PLOT_HUNDRES:   	begin x=plot_x_sh; y=plot_y_sh; colour=colour_sh; writeEn_vga=writeEn[17];		end
				S_PLOT_GAMEOVER:	begin x=plot_x_go; y=plot_y_go; colour=colour_go; writeEn_vga=writeEn[18];		end
		endcase
    end 

	reg [3:0] score_counter_ones, score_counter_tens, score_counter_hundreds;
	
	wire score;
	assign score = |score_p;
	
	always@(posedge score, negedge resetn)begin
		if(!resetn)begin
			score_counter_ones <= 4'b0;
			score_counter_tens <= 4'b0;
			score_counter_hundreds <= 4'b0;
		end
		else if(score)
			if(score_counter_ones < 4'd9)
				score_counter_ones <= score_counter_ones + 1'b1;
			else begin
				score_counter_ones <= 4'b0;
				if(score_counter_tens < 4'd9)
					score_counter_tens <= score_counter_tens + 1'b1;
				else begin
					score_counter_tens <= 4'b0;
					score_counter_hundreds <= score_counter_hundreds + 1'b1; // I don't think we need to check if they reach 999 or not since no one can ever do that possibly
				end
			end
	end

	
	hex_decoder H0(
        .hex_digit(score_counter_ones), 
        .segments(HEX0)
        );	
    hex_decoder H1(
        .hex_digit(score_counter_tens), 
        .segments(HEX1)
        );
    hex_decoder H2(
        .hex_digit(score_counter_hundreds), 
        .segments(HEX2)
        );
    hex_decoder H3(
        .hex_digit(4'b0), 
        .segments(HEX3)
        );
	
	wire swap;
	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter_2buffers VGA(
			.frame(frame),
			.swap(swap),
			.resetn(KEY[0]),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn_vga),
			 //Signals for the DAC to drive the monitor. 
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "320x240";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "background.mif";
	
	// Put your code here. Your code should produce signals x,y,colour and writeEn
	// for the VGA controller, in addition to any other functionality your design may require.
	
	
endmodule


//=====================================Delay counter======================================
module DelayCounter(clock, reset_n, maxcount, enable);
	input clock, reset_n;
	input [27:0] maxcount;
	output enable;
	reg [27:0] count;
	
	assign enable = (count == 0) ? (1'b1) : (1'b0);
		
	always @ (posedge clock, negedge reset_n)
	begin
		if (!reset_n)
			count <= 0;
		else if (count == (maxcount-28'b1))
			count <= 0;
		else
			count <= count + 1'b1;
	end

endmodule

module hex_decoder(hex_digit, segments);
	input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule