`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:50:39 05/07/2013 
// Design Name: 
// Module Name:    final_project_working 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module final_project_working(
    input clock, pb,
	 input [2:0] x,
    output reg led, open, close,
	 output reg [3:0] leds,
    output reg [3:0] msbs,
    output reg [3:0] lsbs,
    output reg [6:0] sevseg,
    output reg [3:0] an,
	 output reg [1:0] clk
    );
	reg [3:0] i;
	reg [3:0] j;
	integer count_a = 0;
	integer count_50M = 0;
	integer lock = 0;
	reg pb_press;
	reg [1:0] pb_state;
	reg [3:0] p_state;
	reg [3:0] n_state;
	reg [2:0] x_reg;
	
	initial begin
		an[0] <= 0;
		an[1] <= 1;
		an[2] <= 1;
		an[3] <= 1;
		pb_state <= 2'b01;
		open <= 0;
		close <= 1;
		p_state <= 4'b0000;
		i <= 6;
		j <= 0;
	end		
	
	parameter sa_o = 4'b0000, sb_o = 4'b0111, sc_o = 4'b1100, sd_o = 4'b1010;
	parameter sa_c = 4'b0000, sb_c = 4'b0111, sc_c = 4'b1110, sd_c = 4'b1111, se_c = 4'b0110;
	
	always @ (posedge clock)
	begin
		x_reg <= #5 x;
		p_state <= #5 n_state;
		led <= open;
		close <= ~open;
	end
	
	always @ (posedge clk[0])
	begin
		an[0] <= ~an[0];
		an[1] <= ~an[1];
		an[2] <= 1;
		an[3] <= 1;
		msbs <= i;
		lsbs <= j;
		pb_press <= pb;
	end
	
	always @ (posedge pb_press)
	begin
		if(close == 1 && open == 0 && i == 0 && j == 0 || i == 6 && j == 0)
			pb_state <= ~pb_state;
		else
			pb_state <= pb_state;
	end
	
	always @ (posedge clk[1])
	begin
		if(close == 1 && open == 0) //counter sets up only if closed
		begin
			if(pb_state == 2'b10)   //counter starts only if pb is pressed
			begin
				if (i == 0)
				begin
					j = j - 1;
					if(j == 0) begin
						i = 0;
						j = 0;
						lock = 1;		//after 60 seconds, program locks user out
					end
				end
				else if (j == 0)
					begin
						i = i - 1;
						j = 9;
					end
				else begin
					j = j - 1; end
			end
		end
		else if(open == 1 && close == 0) begin
			j = 0;
			i = 6; end
	end
	
	always @ (x_reg or p_state)
	begin
		if (lock == 1) begin //lock system sequence
		n_state = 4'b000;    //forces system to sit in this state
		case(p_state)			//if input is not entered in 60 sec.
			sa_c: if (x_reg == 3'b000 || x_reg == 3'b010 || x_reg == 3'b100 || x_reg == 3'b110) begin
					n_state = sa_c;
					open <= 0;
					leds <= 4'b0101; end
					else begin
					n_state = sa_c;
					open <= 0;
					leds <= 4'b1010; end
			default: n_state = sa_c;
		endcase
		end
		else if (open == 1 && close == 0) begin	//sequence to close the lock
		n_state = 4'b0000;								//000->100->101->001->000
		case(p_state)
			sa_c: if (x_reg == 3'b001 || x_reg == 3'b010 || x_reg == 3'b110) begin
					n_state = sb_c;
					open <= 1;
					leds <= sb_c; end
				else if (x_reg == 3'b101) begin
					n_state = sc_c;
					open <= 1;
					leds <= sc_c; end
				else begin
					n_state = sa_c;
					open <= 1;
					leds <= sa_c; end
					
			sb_c: if (x_reg != 3'b000) begin
					n_state = sb_c;
					open <= 1;
					leds <= sb_c; end
				else begin
					n_state = sa_c;
					open <= 1; 
					leds <= sa_c; end
					
			sc_c: if (x_reg == 3'b101) begin
					n_state = sc_c;
					open <= 1; 
					leds <= sc_c; end
				else if (x_reg == 3'b001) begin
					n_state = sd_c;
					open <= 1; 
					leds <= sd_c; end
				else begin
					n_state = sb_c;
					open <= 1; 
					leds <= sb_c; end
					
			sd_c: if (x_reg == 3'b001) begin
					n_state = sd_c;
					open <= 1; 
					leds <= sd_c; end
				else if (x_reg == 3'b000) begin
					n_state = se_c;
					open <= 0; 
					leds <= se_c; end
				else begin
					n_state = sb_c;
					open <= 1; 
					leds <= sb_c; end
					
			se_c: if (x_reg == 3'b000) begin
					n_state = se_c;
					open <= 0;
					leds <= se_c; end
				else begin
					n_state = sb_c;
					open <= 1;
					leds <= sb_c; end
					
			default: n_state = sa_c;
			
			endcase
	end
	
	else if(open == 0 && close == 1) begin //sequence to open the lock
	if(pb_state == 2'b10) begin				//000 -> 010 -> 110 ->
		n_state = 4'b0000;						//111 -> 011 -> 001
		case(p_state)								//only active if timer is active
			sa_o: if (x_reg == 3'b010) begin
					n_state = sb_o;
					open <= 0;
					leds <= sb_o; end
				else begin
					n_state = sa_o;
					open <= 0;
					leds <= sa_o; end
			sb_o: if (x_reg == 3'b010 || x_reg == 3'b110) begin
					n_state = sb_o;
					open <= 0;
					leds <= sb_o; end
				else if (x_reg == 3'b001) begin
					n_state = sb_o;
					open <= 1;
					leds <= sb_o; end
				else if (x_reg == 3'b111) begin
					n_state = sc_o;
					open <= 0; 
					leds <= sc_o; end
				else begin
					n_state = sa_o;
					open <= 0; 
					leds <= sa_o; end
			sc_o: if (x_reg == 3'b111) begin
					n_state = sc_o;
					open <= 0; 
					leds <= sc_o; end
				else if (x_reg == 3'b011) begin
					n_state = sd_o;
					open <= 0; 
					leds <= sd_o; end
				else begin
					n_state = sa_o;
					open <= 0; 
					leds <= sa_o; end
			sd_o: if (x_reg == 3'b001) begin
					n_state = sb_o;
					open <= 0; 
					leds <= sb_o; end
				else if (x_reg == 3'b011) begin
					n_state = sd_o;
					open <= 0; 
					leds <= sd_o; end
				else begin
					n_state = sa_o;
					open <= 0; 
					leds <= sa_o; end
			default: n_state = sa_o;
			
			endcase
	end
	end
	end


	always @ (posedge clk[0]) //sets up sevenseg digits
	begin
	if (an[1])
	begin
		case(msbs)
			0: sevseg = 7'b0000001;
			1: sevseg = 7'b1001111;
			2: sevseg = 7'b0010010;
			3: sevseg = 7'b0000110;
			4: sevseg = 7'b1001100;
			5: sevseg = 7'b0100100;
			6: sevseg = 7'b0100000;
			7: sevseg = 7'b0001101;
			8: sevseg = 7'b0000000;
			9: sevseg = 7'b0000100;
			default: sevseg = 7'b0000001;
		endcase
	end
	if (an[0])
	begin
		case(lsbs)
			0: sevseg = 7'b0000001;
			1: sevseg = 7'b1001111;
			2: sevseg = 7'b0010010;
			3: sevseg = 7'b0000110;
			4: sevseg = 7'b1001100;
			5: sevseg = 7'b0100100;
			6: sevseg = 7'b0100000;
			7: sevseg = 7'b0001101;
			8: sevseg = 7'b0000000;
			9: sevseg = 7'b0000100;
			default: sevseg = 7'b0000001;
		endcase
	end
	end

	always @ (posedge clock) //slower clock
		if (count_50M < 25000000) count_50M = count_50M + 1;
		else
		begin
			clk[1] = ~clk[1];
			count_50M = 0;
		end
		
	always @ (posedge clock) //slow clock
		if (count_a < 25000) count_a = count_a + 1;
		else
		begin
			clk[0] = ~clk[0];
			count_a = 0;
		end

endmodule