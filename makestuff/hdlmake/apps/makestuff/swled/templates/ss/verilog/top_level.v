//
// Copyright (C) 2013 Chris McClelland
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
	top_level(
		// USB interface -----------------------------------------------------------------------------
		input  wire      sysClk_in,    // 50MHz system clock

		input  wire      serClk_in,    // serial clock (async to sysClk_in)
		input  wire      serData_in,   // serial data in
		output wire      serData_out,  // serial data out

		// Onboard peripherals -----------------------------------------------------------------------
		output wire[7:0] sseg_out,     // seven-segment display cathodes (one for each segment)
		output wire[3:0] anode_out,    // seven-segment display anodes (one for each digit)
		output wire[7:0] led_out,      // eight LEDs
		input  wire[7:0] sw_in         // eight switches
	);

	// Channel read/write interface -----------------------------------------------------------------
	wire[6:0] chanAddr;  // the selected channel (0-127)

	// Host >> FPGA pipe:
	wire[7:0] h2fData;   // data lines used when the host writes to a channel
	wire      h2fValid;  // '1' means "on the next clock rising edge, please accept the data on h2fData"
	wire      h2fReady;  // channel logic can drive this low to say "I'm not ready for more data yet"

	// Host << FPGA pipe:
	wire[7:0] f2hData;   // data lines used when the host reads from a channel
	wire      f2hValid;  // channel logic can drive this low to say "I don't have data ready for you"
	wire      f2hReady;  // '1' means "on the next clock rising edge, put your next byte of data on f2hData"
	// ----------------------------------------------------------------------------------------------

	// CommFPGA module
	comm_fpga_ss comm_fpga_ss(
		.clk_in(sysClk_in),
		.reset_in(1'b0),
		
		// USB interface
		.serClk_in(serClk_in),
		.serData_in(serData_in),
		.serData_out(serData_out),

		// DVR interface -> Connects to application module
		.chanAddr_out(chanAddr),
		.h2fData_out(h2fData),
		.h2fValid_out(h2fValid),
		.h2fReady_in(h2fReady),
		.f2hData_in(f2hData),
		.f2hValid_in(f2hValid),
		.f2hReady_out(f2hReady)
	);

	// Switches & LEDs application
	swled swled_app(
		.clk_in(sysClk_in),
		.reset_in(1'b0),
		
		// DVR interface -> Connects to comm_fpga module
		.chanAddr_in(chanAddr),
		.h2fData_in(h2fData),
		.h2fValid_in(h2fValid),
		.h2fReady_out(h2fReady),
		.f2hData_out(f2hData),
		.f2hValid_out(f2hValid),
		.f2hReady_in(f2hReady),
		
		// External interface
		.sseg_out(sseg_out),
		.anode_out(anode_out),
		.led_out(led_out),
		.sw_in(sw_in)
	);
endmodule
