//
// Copyright (C) 2009-2012 Chris McClelland
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
module
	swled(
		input  wire      clk_in,
		input  wire      reset_in,

		// DVR interface -----------------------------------------------------------------------------
		input  wire[6:0] chanAddr_in,   // the selected channel (0-127)

		// Host >> FPGA pipe:
		input  wire[7:0] h2fData_in,    // data lines used when the host writes to a channel
		input  wire      h2fValid_in,   // '1' means "on the next clock rising edge, please accept the data on h2fData"
		output wire      h2fReady_out,  // channel logic can drive this low to say "I'm not ready for more data yet"

		// Host << FPGA pipe:
		output wire[7:0] f2hData_out,   // data lines used when the host reads from a channel
		output wire      f2hValid_out,  // channel logic can drive this low to say "I don't have data ready for you"
		input  wire      f2hReady_in,   // '1' means "on the next clock rising edge, put your next byte of data on f2hData"

		// Peripheral interface ----------------------------------------------------------------------
		output wire[7:0] sseg_out,      // seven-segment display cathodes (one for each segment)
		output wire[3:0] anode_out,     // seven-segment display anodes (one for each digit)
		output wire[7:0] led_out,       // eight LEDs
		input  wire[7:0] sw_in          // eight switches
	);

	// Flags for display on the 7-seg decimal points
	wire[3:0]  flags;

	// Registers implementing the channels
	reg[7:0]   reg0           = 8'h00;
	wire[7:0]  reg0_next;
	reg[15:0]  checksum       = 16'h0000;
	wire[15:0] checksum_next;
                                                                          //BEGIN_SNIPPET(registers)
	// Infer registers
	always @(posedge clk_in)
	begin
		if ( reset_in == 1'b1 )
			begin
				reg0 <= 8'h00;
				checksum <= 16'h0000;
			end
		else
			begin
				reg0 <= reg0_next;
				checksum <= checksum_next;
			end
	end

	// Drive register inputs for each channel when the host is writing
	assign reg0_next =
		(chanAddr_in == 7'b0000000 && h2fValid_in == 1'b1) ? h2fData_in :
		reg0;
	assign checksum_next =
		(chanAddr_in == 7'b0000000 && h2fValid_in == 1'b1) ?
			checksum + h2fData_in :
		(chanAddr_in == 7'b0000001 && h2fValid_in == 1'b1) ?
			{h2fData_in, checksum[7:0]} :
		(chanAddr_in == 7'b0000010 && h2fValid_in == 1'b1) ?
			{checksum[15:8], h2fData_in} :
		checksum;
	
	// Select values to return for each channel when the host is reading
	assign f2hData_out =
		(chanAddr_in == 7'b0000000) ? sw_in :
		(chanAddr_in == 7'b0000001) ? checksum[15:8] :
		(chanAddr_in == 7'b0000010) ? checksum[7:0] :
		8'h00;

	// Assert that there's always data for reading, and always room for writing
	assign f2hValid_out = 1'b1;
	assign h2fReady_out = 1'b1;                                              //END_SNIPPET(registers)
	
	// LEDs and 7-seg display
	assign led_out = reg0;
	assign flags = {3'b00, f2hReady_in, reset_in};
	seven_seg seven_seg(
		.clk_in(clk_in),
		.data_in(checksum),
		.dots_in(flags),
		.segs_out(sseg_out),
		.anodes_out(anode_out)
	);
endmodule
