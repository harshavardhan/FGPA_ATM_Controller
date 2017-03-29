Honour Code:
	Anirudh (150050070): I pledge on my honour that I have not used any unauthorised help for this project or any other.
	Akshith (150050074): I pledge on my honour that I have not used any unauthorised help for this project or any other.
	Yashasvi (150050080): I pledge on my honour that I have not used any unauthorised help for this project or any other.
	Harsha (150050073): I pledge on my honour that I have not used any unauthorised help for this project or any other.

Citations:
	Vhdl functionalities help:
		http://stackoverflow.com/questions/7290298/convert-integer-to-std-logic
		http://stackoverflow.com/questions/34037835/vhdl-subtract-std-logic-vector
		http://kunalbandekar.blogspot.in/2011/03/use-of-generic-in-vhdl.html
		http://kunalbandekar.blogspot.in/2011/03/use-of-generic-in-vhdl.html
	
	Makefile help used:
		https://ranjiniloveslinux.wordpress.com/2012/03/13/what-is-phony-in-makefile/
		http://makefiletutorial.com/

	Reading from a file line by line in c using get line :
		http://timmurphy.org/2010/10/31/reading-from-a-file-in-c-2/
		http://c-for-dummies.com/blog/?p=1112
		https://www.programiz.com/c-programming/c-file-input-output

	Using strtok fn to split a line by a delimiter :
		http://www.cplusplus.com/reference/cstring/strtok/
		http://stackoverflow.com/questions/9210528/split-string-with-delimiters-in-c

	Adapted the tiny encryption algorithm :
		https://en.wikipedia.org/wiki/Tiny_Encryption_Algorithm

	Learnt and Used the code in main.c and top.mk

Description for running Atm.out:
	1) We used the in built options -v and -i after understanding them
	2) -y option would start the atm service. We could have put it in the int main directly, but encapsulating with an option would give a greater control over the process
	3) -l option would give a log of all the events this would help in debugging if any
	4) command for running : sudo ./ATM.out -v 1d50:602b:0002 -i 1443:0007 -y

Note :
	5) In our Makefile we used top.mk. We did so after understanding it and tweaked it up bit to get ATM.out in the same directory as that of main.c. 
	6) The reading from channel and writing to channel during communication happens with a gap of 1 second. So please wait for about 8 seconds after you enter communication state to get the reading. ||ly for writing