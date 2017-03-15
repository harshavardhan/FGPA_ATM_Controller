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
		// FX2LP interface ---------------------------------------------------------------------------
		input  wire      fx2Clk_in,       // 48MHz clock from FX2LP
		output wire[1:0] fx2Addr_out,     // select FIFO: "00" for EP2OUT, "10" for EP6IN
		inout  wire[7:0] fx2Data_io,      // 8-bit data to/from FX2LP

		// When EP2OUT selected:
		output wire      fx2Read_out,     // asserted (active-low) when reading from FX2LP
		output wire      fx2OE_out,       // asserted (active-low) to tell FX2LP to drive bus
		input  wire      fx2GotData_in,   // asserted (active-high) when FX2LP has data for us

		// When EP6IN selected:
		output wire      fx2Write_out,    // asserted (active-low) when writing to FX2LP
		input  wire      fx2GotRoom_in,   // asserted (active-high) when FX2LP has room for more data from us
		output wire      fx2PktEnd_out,   // asserted (active-low) when a host read needs to be committed early

		// Onboard peripherals -----------------------------------------------------------------------
		output wire[7:0] sseg_out,        // seven-segment display cathodes (one for each segment)
		output wire[3:0] anode_out,       // seven-segment display anodes (one for each digit)
		output wire[7:0] led_out,         // eight LEDs
		input  wire[7:0] sw_in            // eight switches
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

	// Needed so that the comm_fpga_fx2 module can drive both fx2Read_out and fx2OE_out
	wire      fx2Read;

	// Reset signal so host can delay startup
	wire      fx2Reset;
	
	// CommFPGA module
	assign fx2Read_out = fx2Read;
	assign fx2OE_out = fx2Read;
	assign fx2Addr_out[0] =  // So fx2Addr_out[1]='0' selects EP2OUT, fx2Addr_out[1]='1' selects EP6IN
		 (fx2Reset == 1'b0) ? 1'b0 : 1'bZ;
	comm_fpga_fx2 comm_fpga_fx2(
		.clk_in(fx2Clk_in),
		.reset_in(1'b0),
		.reset_out(fx2Reset),
			
		// FX2LP interface
		.fx2FifoSel_out(fx2Addr_out[1]),
		.fx2Data_io(fx2Data_io),
		.fx2Read_out(fx2Read),
		.fx2GotData_in(fx2GotData_in),
		.fx2Write_out(fx2Write_out),
		.fx2GotRoom_in(fx2GotRoom_in),
		.fx2PktEnd_out(fx2PktEnd_out),

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
	swled swled(
		.clk_in(fx2Clk_in),
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
