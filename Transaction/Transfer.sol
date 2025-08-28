// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract EthPayment {
    address public owner;

    // Constructor sets deployer as owner
    constructor() {
        owner = msg.sender;
    }

    // Modifier to restrict access to owner only
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    // Function to pay ETH to a recipient
    function payEth(address payable recipient, uint256 amount) external onlyOwner {
        // Check contract has enough balance
        require(address(this).balance >= amount, "Insufficient balance");

        // Transfer ETH using call
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");
    }

    // Function to allow contract to receive ETH
    receive() external payable {}
}