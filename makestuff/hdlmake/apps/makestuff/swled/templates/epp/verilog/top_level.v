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
	top_level(
		input  wire      sysClk_in,      // clock input (asynchronous with EPP signals)

		// EPP interface -----------------------------------------------------------------------------
		inout  wire[7:0] eppData_io,     // bidirectional 8-bit data bus
		input  wire      eppAddrStb_in,  // active-low asynchronous address strobe
		input  wire      eppDataStb_in,  // active-low asynchronous data strobe
		input  wire      eppWrite_in,    // read='1'; write='0'
		output wire      eppWait_out,    // active-low asynchronous wait signal

		// Onboard peripherals -----------------------------------------------------------------------
		output wire[7:0] sseg_out,       // seven-segment display cathodes (one for each segment)
		output wire[3:0] anode_out,      // seven-segment display anodes (one for each digit)
		output wire[7:0] led_out,        // eight LEDs
		input  wire[7:0] sw_in           // eight switches
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

	wire      eppReset;

	// CommFPGA module
	comm_fpga_epp comm_fpga_epp(
		.clk_in(sysClk_in),
		.reset_in(1'b0),
		.reset_out(eppReset),

		// EPP interface
		.eppData_io(eppData_io),
		.eppAddrStb_in(eppAddrStb_in),
		.eppDataStb_in(eppDataStb_in),
		.eppWrite_in(eppWrite_in),
		.eppWait_out(eppWait_out),

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
		.reset_in(eppReset),
		
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
