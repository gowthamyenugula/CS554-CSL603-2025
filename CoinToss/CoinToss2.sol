// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract CoinTossOptimized {
    address public immutable referee;
    address public indianCaptain;
    address public englandCaptain;
    uint256 public constant REQUIRED_AMOUNT = 0.002 ether;

    mapping(address => uint256) public payments;

    bytes32 public indianHash;
    bytes32 public englandHash;
    uint8 public indianChoice;
    uint8 public englandChoice;
    bool public indianRevealed;
    bool public englandRevealed;

    uint256 public commitTime;
    uint256 public revealDeadline;

    modifier onlyCaptains() {
        require(msg.sender == indianCaptain || msg.sender == englandCaptain, "Only captains can call this function");
        _;
    }

    constructor() {
        referee = msg.sender;
    }

    function setCaptains(address _indian, address _england) external {
        require(msg.sender == referee, "Only referee can set captains");
        require(indianCaptain == address(0) && englandCaptain == address(0), "Captains already set");
        indianCaptain = _indian;
        englandCaptain = _england;
    }

    receive() external payable onlyCaptains {
        require(msg.value == REQUIRED_AMOUNT, "Must send exactly 0.002 ETH");
        require(payments[msg.sender] == 0, "Already paid");
        payments[msg.sender] = msg.value;
    }

    function bothPaid() public view returns (bool) {
        return (payments[indianCaptain] == REQUIRED_AMOUNT && payments[englandCaptain] == REQUIRED_AMOUNT);
    }

    function commit(uint8 _choice, string memory _secret) external onlyCaptains {
        require(bothPaid(), "Both captains must pay first");
        require(_choice == 0 || _choice == 1, "Choice must be 0 or 1");

        bytes32 hash = keccak256(abi.encodePacked(_choice, _secret));

        if (msg.sender == indianCaptain) {
            require(indianHash == 0, "Indian captain already committed");
            indianHash = hash;
        } else {
            require(englandHash == 0, "England captain already committed");
            englandHash = hash;
        }
        _checkStartDeadline();
    }

    function reveal(uint8 _choice, string memory _secret) external onlyCaptains {
        require(block.timestamp <= revealDeadline, "Reveal period ended");
        require(_choice == 0 || _choice == 1, "Choice must be 0 or 1");

        bytes32 hashValue = keccak256(abi.encodePacked(_choice, _secret));

        if (msg.sender == indianCaptain) {
            require(!indianRevealed, "Indian captain already revealed");
            require(hashValue == indianHash, "Indian hash mismatch");
            indianChoice = _choice;
            indianRevealed = true;
        } else {
            require(!englandRevealed, "England captain already revealed");
            require(hashValue == englandHash, "England hash mismatch");
            englandChoice = _choice;
            englandRevealed = true;
        }
    }

    function _checkStartDeadline() internal {
        if (indianHash != 0 && englandHash != 0 && commitTime == 0) {
            commitTime = block.timestamp;
            revealDeadline = block.timestamp + 3 minutes;
        }
    }

    function settle() external {
        require(msg.sender == referee, "Only referee can settle");
        require(revealDeadline != 0 && block.timestamp >= revealDeadline, "Deadline not reached yet");

        uint256 pot = address(this).balance;

        if (indianRevealed && englandRevealed) {
            if (indianChoice ^ englandChoice == 1) {
                // If choices are different, one wins. This logic is arbitrary as explained before.
                // Assuming Indian wins if XOR is 1, and England wins if XOR is 0.
                if (indianChoice == 1) { // 1 ^ 0 = 1, Indian wins
                    payable(indianCaptain).transfer(pot);
                } else { // 0 ^ 1 = 1, England wins
                    payable(englandCaptain).transfer(pot);
                }
            } else {
                // Choices are the same, refund deposits
                payable(indianCaptain).transfer(REQUIRED_AMOUNT);
                payable(englandCaptain).transfer(REQUIRED_AMOUNT);
            }
        } else if (indianRevealed) {
            payable(indianCaptain).transfer(pot);
        } else if (englandRevealed) {
            payable(englandCaptain).transfer(pot);
        } else {
            payable(referee).transfer(pot);
        }
    }
}