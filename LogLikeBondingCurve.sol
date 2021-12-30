// SPDX-License-Identifier: GPL-3.0-or-later

// meant to simulate a logarithmic curve with less computation
pragma solidity >=0.8.0;

import "./ERC20.sol";

contract LogLikeBondingCurve is ERC20 {
    uint256 public startingPrice; // wei

    uint256 public blockSize; // wei

    uint256 public blockPriceIncrement;

    uint8 public velocity; // number 1-100

    constructor() ERC20('MyDAO', 'TEST', 18) {
        startingPrice = 10000; // hardcoded values for ease of test deployment

        blockSize = 10000;

        blockPriceIncrement = 10000;

        velocity = 90;
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

        uint256 increment = blockPriceIncrement;

        for (uint256 i = 0; i < currentBlock; i++) {
            increment = changeIncrement(increment);

            currentPrice += increment;
        }

        return currentPrice;
    }

    function changeIncrement(uint256 increment) public view returns(uint256) {
      return (increment * velocity) / 100;
    }

    function estimatePrice(uint256 amount_) public view returns (uint256) {
        uint256 remainingInBlock = getRemainingInBlock();

        uint256 currentPrice = getCurrentPrice();

        uint256 estTotal;

        if (amount_ <= remainingInBlock) {
            estTotal = amount_ * currentPrice;
        } else {
            estTotal += remainingInBlock * currentPrice;

            uint256 currentBlock = getCurrentBlock();

            uint256 increment = blockPriceIncrement;
            for (uint256 i = 0; i < currentBlock; i++) {
                increment = changeIncrement(increment);
            }

            currentPrice += increment;

            uint256 remainingAmount = amount_ - remainingInBlock;

            uint256 remainder = remainingAmount % blockSize;

            uint256 blocksRemaining = remainingAmount / blockSize;

            for (uint256 i = 0; i < blocksRemaining; i++) {
                estTotal += currentPrice * blockSize;

                increment = changeIncrement(increment);

                currentPrice += increment;
            }

            if (remainder != 0) {
                estTotal += remainder * currentPrice;
            }
        }

        return estTotal;
    }
}
