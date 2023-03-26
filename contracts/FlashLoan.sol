// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;
import "hardhat/console.sol";
import "./Token.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IReceiver {
    function receiveTokens(address tokenAddress, uint256 amount) external;
}

contract FlashLoan is ReentrancyGuard {
    using SafeMath for uint256;

    Token public token;
    uint256 public poolBalance;

    constructor(address _tokenAddress) {
        token = Token(_tokenAddress);
    }

    function depositTokens(uint256 amount) external nonReentrant {
        // Transfer token from sender. Sender must have first approved them.
        require(amount > 0, "Must deposit at least one token");
        token.transferFrom(msg.sender, address(this), amount);
        poolBalance = poolBalance.add(amount);
    }

    function flashLoan(uint256 _borrowAmount) external nonReentrant {
        // send tokens  to receiver
        require(_borrowAmount > 0, "Must borrow at least one token");

        uint256 balanceBefore = token.balanceOf(address(this));
        require(balanceBefore >= _borrowAmount, "Not enough tokens in pool");

        assert(poolBalance == balanceBefore);

        token.transfer(msg.sender, _borrowAmount);
        //use Loan, Get paid back
        IReceiver(msg.sender).receiveTokens(address(token), _borrowAmount);
        // Ensure loan paid back

        uint256 balanceAfter = token.balanceOf(address(this));
        require(
            balanceAfter >= balanceBefore,
            "Flash loan hasn't been paid back"
        );
    }
}
