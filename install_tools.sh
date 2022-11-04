#!/usr/bin/env bash

#
#    Copyright (C) 2022  Jakub Hladik
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

# Check if we are running on a Mac
if [ ! "$(uname)" == "Darwin" ]; then
    echo "This script can only be run on a Mac."
    exit 1
fi

# Check if brew is installed
which -s brew
if [[ $? != 0 ]] ; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Updating Homebrew..."
    brew update
fi

# Install dependencies for building
brew install cmake python boost boost-python3 eigen bison flex gawk libffi graphviz pkg-config tcl-tk xdot perl ccache autoconf gperftools libftdi

# Create a folder for compilation of tools
mkdir -p tools
cd tools

# Download, extract, configure, compile and install icestorm
curl -L https://github.com/YosysHQ/icestorm/archive/refs/heads/master.tar.gz > icestorm.tar.gz
tar -xzf icestorm.tar.gz
cd icestorm-*
make -j`sysctl -n hw.ncpu`
sudo make install
cd ..

# Download, extract, configure, compile and install yosys
curl -L https://github.com/YosysHQ/yosys/archive/refs/tags/yosys-0.22.tar.gz > yosys.tar.gz
tar -xzf yosys.tar.gz
cd yosys-*
make config-clang
make -j`sysctl -n hw.ncpu`
sudo make install
cd ..

# Download, extract, configure, compile and install nextpnr
curl -L https://github.com/YosysHQ/nextpnr/archive/refs/tags/nextpnr-0.4.tar.gz > nextpnr.tar.gz
tar -xzf nextpnr.tar.gz
cd nextpnr-*
cmake . -DARCH=ice40
make -j`sysctl -n hw.ncpu`
sudo make install
cd ..

# Download, extract, configure, compile and install verilator
curl -L https://github.com/verilator/verilator/archive/refs/tags/v5.002.tar.gz > verilator.tar.gz
tar -xzf verilator.tar.gz
cd verilator-*
autoconf
unset VERILATOR_ROOT
./configure
make -j`sysctl -n hw.ncpu`
sudo make install
cd ..

# Install cocotb
python3 -m pip install --upgrade pip
pip3 install cocotb

# Install gtkwave
brew install gtkwave
