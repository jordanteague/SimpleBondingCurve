// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./ERC20.sol";

contract SimpleBondingCurve is ERC20 {
    uint256 public startingPrice; // wei

    uint256 public blockSize; // wei

    uint8 public blockPriceIncrement;

    constructor() ERC20('MyDAO', 'TEST', 18) {
        startingPrice = 10; // hardcoded values for ease of test deployment

        blockSize = 10;

        blockPriceIncrement = 10;
    }

    function buy(uint256 amount_) public payable {
        uint256 estPrice = estimatePrice(amount_);

        require(msg.value >= estPrice, 'INSUFFICIENT_FUNDS');

        _mint(msg.sender, amount_);
    }

    // separate external functions for testing purposes only
    function getCurrentBlock() public view returns (uint256) {
        return (totalSupply / blockSize);
    }

    function getRemainingInBlock() public view returns (uint256) {
        uint256 used = totalSupply % blockSize;

        uint256 remaining = blockSize - used;

        return remaining;
    }

    function getCurrentPrice() public view returns (uint256) {
        uint256 currentPrice = startingPrice;

        uint256 currentBlock = getCurrentBlock();

        for (uint256 i = 0; i < currentBlock++; i++) {
            currentPrice += blockPriceIncrement * i;
        }

        return currentPrice;
    }

    function estimatePrice(uint256 amount_) public view returns (uint256) {
        uint256 remainingInBlock = getRemainingInBlock();

        uint256 currentPrice = getCurrentPrice();

        uint256 estTotal;

        if (amount_ <= remainingInBlock) {
            estTotal = amount_ * currentPrice;
        } else {
            estTotal += remainingInBlock * currentPrice;

            currentPrice += blockPriceIncrement;

            uint256 remainingAmount = amount_ - remainingInBlock;

            uint256 remainder = remainingAmount % blockSize;

            uint256 blocksRemaining = remainingAmount / blockSize;

            for (uint256 i = 0; i < blocksRemaining; i++) {
                estTotal += currentPrice * blockSize;

                currentPrice += blockPriceIncrement * i++;
            }

            if (remainder != 0) {
                estTotal += remainder * currentPrice;
            }
        }

        return estTotal;
    }
}
