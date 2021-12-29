// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./ERC20.sol";

contract SimpleBondingCurve is ERC20 {

    uint256 public startingPrice; // wei
    uint256 public blockSize; // wei
    uint8 public blockPriceIncrement;

    constructor() ERC20("MyDAO", "TEST", 18) {
        startingPrice = 10; // hardcoded values for ease of test deployment
        blockSize = 10;
        blockPriceIncrement = 10;
    }

    function buy(uint256 amount_) external payable {
        uint estPrice = this.estimatePrice(amount_);
        require(msg.value >= estPrice, "INSUFFICIENT_FUNDS");
        (bool sent, bytes memory data) = payable(address(this)).call{value: estPrice}("");
        require(sent, "Failed to send Ether");
        _mint(msg.sender, amount_);
    }

    // separate external functions for testing purposes only
    function getCurrentBlock() external view returns(uint) {
        return (totalSupply / blockSize);
    }

    function getRemainingInBlock() external view returns(uint) {
        uint used = totalSupply % blockSize;
        uint remaining = blockSize - used;
        return remaining;
    }

    function getCurrentPrice() external view returns(uint) {
        uint currentPrice = startingPrice;
        uint currentBlock = this.getCurrentBlock();
        for(uint i=0; i < currentBlock + 1; i++) {
            currentPrice += (blockPriceIncrement * i);
        }
        return currentPrice;
    }

    function estimatePrice(uint256 amount_) external view returns(uint) {
        uint remainingInBlock = this.getRemainingInBlock();
        uint currentPrice = this.getCurrentPrice();
        uint estTotal;
        if(amount_ <= remainingInBlock) {
            estTotal = amount_ * currentPrice;
        } else {
            estTotal += remainingInBlock * currentPrice;
            currentPrice += blockPriceIncrement;
            uint remainingAmount = amount_ - remainingInBlock;
            uint remainder = remainingAmount % blockSize;
            uint blocksRemaining = remainingAmount / blockSize;
            for(uint i=0; i < blocksRemaining; i++) {
                estTotal += currentPrice * blockSize;
                currentPrice += (blockPriceIncrement * (i+1));
            }
            if(remainder > 0) {
                estTotal += remainder * currentPrice;
            }
        }
        return estTotal;
    }
    
    receive() external payable {}

    fallback() external payable {}

}
