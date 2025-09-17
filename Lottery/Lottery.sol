// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Lottery {
    address public retailer;
    address public alice;
    address public bob;
    address public oscar;

    uint256 public constant TICKET_PRICE = 0.01 ether;
    uint256 public startTime;
    bool public winnerSelected;
    address public winner;

    mapping(address => uint256) public playerNumber;  // Stores 5-digit numbers
    address[] public players;
    uint256[] public numbers;  // Stores all generated numbers

    event PlayerRegistered(address player, uint256 number);
    event WinnerDeclared(address winner, uint256 amount);

    modifier onlyRetailer() {
        require(msg.sender == retailer, "Only retailer can call this");
        _;
    }

    constructor() {
        retailer = msg.sender; // Retailer = service provider
    }

    // Players deposit money via receive()
    receive() external payable {
        require(msg.value == TICKET_PRICE, "Send exactly 0.01 ETH");
        require(players.length < 3, "All players already registered");
        require(playerNumber[msg.sender] == 0, "Already registered");

        // Start timer after first payment
        if (startTime == 0) {
            startTime = block.timestamp;
        }

        // Assign 5-digit random number
        uint256 number = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, block.prevrandao))
        ) % 100000;

        playerNumber[msg.sender] = number;
        players.push(msg.sender);
        numbers.push(number);

        emit PlayerRegistered(msg.sender, number);
    }

    // Retailer sets IDs after all players register
    function setPlayers(address _alice, address _bob, address _oscar) external onlyRetailer {
        require(players.length == 3, "All players must pay first");
        alice = _alice;
        bob = _bob;
        oscar = _oscar;
    }

    // Retailer selects the winner after 2 min
    function selectWinner() external onlyRetailer {
        require(players.length == 3, "All players must register first");
        require(block.timestamp >= startTime + 2 minutes, "Wait 2 minutes after first payment");
        require(!winnerSelected, "Winner already selected");

        // Randomly pick winner from 3 players
        uint256 randIndex = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao))
        ) % numbers.length;

        winner = players[randIndex];
        winnerSelected = true;

        // Transfer all Ether to winner
        uint256 prize = address(this).balance;
        payable(winner).transfer(prize);

        emit WinnerDeclared(winner, prize);
    }

    // View all generated numbers
    function getAllNumbers() external view returns (uint256[] memory) {
        return numbers;
    }

    // Check contract balance
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
