// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract CoinToss {
    address public referee;
    address public indianCaptain;
    address public englandCaptain;
    uint256 public requiredAmount = 0.002 ether; // Each captain must pay 0.002 ETH

    // Payments mapping
    mapping(address => uint256) public payments;

    // Commit–reveal variables
    bytes32 public indianHash;
    bytes32 public englandHash;

    uint8 public indianChoice;
    uint8 public englandChoice;
    bool public indianRevealed;
    bool public englandRevealed;

    // Toss winner
    address public tossWinner;

    // Deployment by coder
    constructor() {
        // Deployer does not become referee
        // Referee will set their own address later
    }

    // Step : Referee sets themselves
    function setReferee(address _referee) external {
        require(referee == address(0), "Referee already set");
        referee = _referee;
    }

    // Step 1: Referee sets the captains
    function setCaptains(address _indian, address _england) external {
        require(msg.sender == referee, "Only referee can set captains");
        require(indianCaptain == address(0) && englandCaptain == address(0), "Captains already set");
        indianCaptain = _indian;
        englandCaptain = _england;
    }

    receive() external payable {
        require(msg.sender == indianCaptain || msg.sender == englandCaptain, "Only captains can send Ether");
        require(msg.value == requiredAmount, "Must send exactly 0.002 ETH");
        payments[msg.sender] += msg.value;
    }

    // Check if both captains paid
    function bothPaid() public view returns (bool) {
        return (payments[indianCaptain] == requiredAmount && payments[englandCaptain] == requiredAmount);
    }

    // Step 3: Captains commit choice
    function commitIndian(uint8 _choice, string memory _secret) external {
        require(bothPaid(), "Both captains must pay first");
        require(msg.sender == indianCaptain, "Only Indian captain can commit");
        require(indianHash == 0, "Indian captain already committed");
        require(_choice == 0 || _choice == 1, "Choice must be 0 or 1");

        indianHash = keccak256(abi.encodePacked(_choice, _secret));
    }

    function commitEngland(uint8 _choice, string memory _secret) external {
        require(bothPaid(), "Both captains must pay first");
        require(msg.sender == englandCaptain, "Only England captain can commit");
        require(englandHash == 0, "England captain already committed");
        require(_choice == 0 || _choice == 1, "Choice must be 0 or 1");

        englandHash = keccak256(abi.encodePacked(_choice, _secret));
    }

    // Step 4: Captains reveal
    function reveal(uint8 _choice, string memory _secret) external {
        require(msg.sender == indianCaptain || msg.sender == englandCaptain, "Only captains can reveal");
        require(_choice == 0 || _choice == 1, "Choice must be 0 or 1");

        bytes32 hashValue = keccak256(abi.encodePacked(_choice, _secret));

        if (msg.sender == indianCaptain) {
            require(!indianRevealed, "Indian captain already revealed");
            require(hashValue == indianHash, "Hash mismatch");
            indianChoice = _choice;
            indianRevealed = true;
        } else {
            require(!englandRevealed, "England captain already revealed");
            require(hashValue == englandHash, "Hash mismatch");
            englandChoice = _choice;
            englandRevealed = true;
        }
    }

    // Step 5: Referee announces winner
    function announceWinner() external {
        require(msg.sender == referee, "Only referee can announce");
        require(indianRevealed && englandRevealed, "Both captains must reveal first");

        uint8 result = indianChoice ^ englandChoice; // XOR of choices
        tossWinner = (result == 1) ? indianCaptain : englandCaptain;
    }

    // Step 6: Get winner
    function getWinner() external view returns (address) {
        require(tossWinner != address(0), "Winner not decided yet");
        return tossWinner;
    }
}
