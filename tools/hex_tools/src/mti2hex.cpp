// Copyright (C) 2017 Philipp Holzinger
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#include <iostream>
#include <cstdint>
#include <string>
#include <fstream>
#include <vector>
#include <stack>

void tokenize(std::string line, std::vector<std::string> &vec, char separator){
	unsigned int last = 0;
	unsigned int length = 0;
	for(unsigned int i=0; i<line.length(); ++i){
		if(line[i]==separator){
			std::string item = line.substr(last,length);
			vec.push_back(item);
			last = i+1;
			length = 0;
		}else{
			++length;
		}
	}
	if(line.length() > 1){
		if(line[line.length()-1]!=separator){
			std::string item = line.substr(last,length);
			vec.push_back(item);
		}
	}
}

int main(int argc, char *argv[]){
	
	if(argc != 2 && argc != 3){
		std::cout << "wrong usage: argument must be file with configuration" << std::endl;
		return EXIT_FAILURE;
	}
	
	// open in and out files
	std::ifstream mti_file(argv[1]);
	if(!mti_file.is_open()){
		std::cerr << "ERROR: could not open file " << argv[1] << std::endl;
		return EXIT_FAILURE;
	}
	std::string outfilename(argv[1]);
	outfilename.replace(outfilename.length()-3,3,"hex");
	std::ofstream outfile(outfilename);
	std::string mti_line = "";

	// read mti file header
	std::getline(mti_file,mti_line);
	std::getline(mti_file,mti_line);
	
	// get data width and initialize filler
	std::getline(mti_file,mti_line);
	std::vector<std::string> mti_header;
	tokenize(mti_line,mti_header,' ');
	if(mti_header.size() < 2 || mti_file.eof()){
		std::cerr << "ERROR: first line after header without data not supported" << std::endl;
		return EXIT_FAILURE;
	}
	
	unsigned int mtidata_width = mti_header[1].length();
	unsigned int hexdata_width = mtidata_width;
	if(argc==3){
		hexdata_width = static_cast<unsigned int>(std::stoi(argv[2]))/4;
		if(hexdata_width % mtidata_width != 0){
			std::cerr << "ERROR: hex data width must be multiple of mti data width" << std::endl;
			return EXIT_FAILURE;
		}
	}
	unsigned int ratio = hexdata_width / mtidata_width;
	
	std::string filler = "";
	for(unsigned int i=0; i<mtidata_width; ++i){
		filler.append("0");
	}
	
	// read data and dump it in new format
	std::stack<std::string> stack;
	unsigned int index = 0;
	while(!mti_file.eof()){
		std::vector<std::string> mti_strings;
		tokenize(mti_line,mti_strings,' ');
		int mti_index = std::stoi(mti_strings[0].substr(0,mti_strings[0].length()-1));

		// fill with zeros if some values are not in the file
		while(index < mti_index){
			stack.push(filler);
			++index;
			if(index&1 == 0){
				while(!stack.empty()){
					outfile << stack.top();
					stack.pop();
				}
			}
			if(index % ratio == 0){
				while(!stack.empty()){
					outfile << stack.top();
					stack.pop();
				}
				outfile << std::endl;
			}
		}

		// write data if present
		for(unsigned int entry=1; entry<mti_strings.size(); ++entry){
			stack.push(mti_strings[entry]);
			++index;
			if(index&1 == 0){
				while(!stack.empty()){
					outfile << stack.top();
					stack.pop();
				}
			}
			if(index % ratio == 0){
				while(!stack.empty()){
					outfile << stack.top();
					stack.pop();
				}
				outfile << std::endl;
			}
		}

		// get next line
		std::getline(mti_file,mti_line);
	}
	// write rest
	while(!stack.empty()){
		outfile << stack.top();
		stack.pop();
	}
}

