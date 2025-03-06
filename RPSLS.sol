// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "./CommitReveals.sol";
import "./TimeUnit.sol";

contract RPSLS is CommitReveal, TimeUnit {
    uint public numPlayer = 0;
    uint public reward = 0;
    mapping(address => uint) public player_choice;
    address[] public players;
    uint public revealDeadline;
    bool public gameActive = false;

    address[4] private allowedPlayers = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    ];

    modifier onlyAllowedPlayers() {
        bool isAllowed = false;
        for (uint i = 0; i < allowedPlayers.length; i++) {
            if (msg.sender == allowedPlayers[i]) {
                isAllowed = true;
                break;
            }
        }
        require(isAllowed, "You are not allowed to play.");
        _;
    }

    function addPlayer() public payable onlyAllowedPlayers {
        require(numPlayer < 2, "Game already has 2 players.");
        require(msg.value == 1 ether, "Entry fee is 1 ether.");
        if (numPlayer > 0) {
            require(msg.sender != players[0], "Same player cannot join twice.");
        }

        reward += msg.value;
        players.push(msg.sender);
        numPlayer++;

        if (numPlayer == 1) {
            setStartTime(); // Start the timer if only one player joins
        }

        if (numPlayer == 2) {
            revealDeadline = block.timestamp + 5 minutes;
            gameActive = true;
        }
    }

    function commitChoice(bytes32 commitHash) public onlyAllowedPlayers {
        require(numPlayer == 2, "Game is not full.");
        commit(commitHash);
    }

    function revealChoice(uint choice, string memory secret) public onlyAllowedPlayers {
        require(numPlayer == 2, "Game is not full.");
        require(block.timestamp <= revealDeadline, "Reveal period has ended.");
        require(commits[msg.sender].revealed == false, "Already revealed");
        require(getHash(keccak256(abi.encodePacked(choice, secret))) == commits[msg.sender].commit, "Commit does not match.");
        require(choice >= 0 && choice <= 4, "Invalid choice.");

        player_choice[msg.sender] = choice;
        commits[msg.sender].revealed = true;

        if (player_choice[players[0]] != 0 && player_choice[players[1]] != 0) {
            _checkWinnerAndPay();
        }
    }

    function _checkWinnerAndPay() private {
        uint p0Choice = player_choice[players[0]];
        uint p1Choice = player_choice[players[1]];
        address payable account0 = payable(players[0]);
        address payable account1 = payable(players[1]);

        if (_isWinner(p0Choice, p1Choice)) {
            account0.transfer(reward);
        } else if (_isWinner(p1Choice, p0Choice)) {
            account1.transfer(reward);
        } else {
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }

        _resetGame();
    }

    function _isWinner(uint choice1, uint choice2) private pure returns (bool) {
        return (choice1 == 0 && (choice2 == 2 || choice2 == 3)) || // Rock > Scissors, Lizard
               (choice1 == 1 && (choice2 == 0 || choice2 == 4)) || // Paper > Rock, Spock
               (choice1 == 2 && (choice2 == 1 || choice2 == 3)) || // Scissors > Paper, Lizard
               (choice1 == 3 && (choice2 == 1 || choice2 == 4)) || // Lizard > Paper, Spock
               (choice1 == 4 && (choice2 == 0 || choice2 == 2));   // Spock > Rock, Scissors
    }

    function claimWinDueToTimeout() public {
        require(gameActive, "Game is not active.");
        require(block.timestamp > revealDeadline, "Reveal period not ended.");

        address payable winner;
        if (player_choice[players[0]] != 0) {
            winner = payable(players[0]);
        } else if (player_choice[players[1]] != 0) {
            winner = payable(players[1]);
        } else {
            _resetGame();
            return;
        }

        winner.transfer(reward);
        _resetGame();
    }

    function withdrawIfNoSecondPlayer() public {
        require(numPlayer == 1, "Both players have joined.");
        require(elapsedMinutes() >= 5, "Wait time not exceeded.");
        require(msg.sender == players[0], "Only first player can withdraw.");

        address payable account = payable(players[0]);
        account.transfer(reward);

        _resetGame();
    }

    function _resetGame() private {
        numPlayer = 0;
        reward = 0;
        delete players;
        gameActive = false;
    }
}
