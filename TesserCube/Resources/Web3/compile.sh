#!/bin/bash

set -ev

solc redpacket.sol --abi > redpacket.json
# remove first two line
tail -n +4 redpacket.json > redpacket.json.tmp && mv redpacket.json.tmp redpacket.json

solc redpacket.sol --bin > redpacket.bin
tail -n +4 redpacket.bin > redpacket.bin.tmp && mv redpacket.bin.tmp redpacket.bin