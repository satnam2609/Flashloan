// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;
import "hardhat/console.sol";
import "./Token.sol";
import "./FlashLoan.sol";

contract FlashLoanReceiver {
    FlashLoan private pool;
    address private owner;

    event LoanReceived(address token, uint256 amount);

    constructor(address _poolAddress) {
        pool = FlashLoan(_poolAddress);
        owner = msg.sender;
    }

    function receiveTokens(address _tokenAddress, uint256 _amount) external {
        require(msg.sender == address(pool), "Sender must be pool");

        emit LoanReceived(_tokenAddress, _amount);

        require(
            Token(_tokenAddress).transfer(msg.sender, _amount),
            "Transfer of tokens failed"
        );
    }

    function executeFlashLoan(uint256 amount) external {
        require(
            msg.sender == owner,
            "Only owner can execute flashLoan  function"
        );
        pool.flashLoan(amount);
    }
}
