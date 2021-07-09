//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
}

contract RpsGame is SafeMath {
    ///  Constant definition
    uint8 public constant NONE = 0;
    uint8 public constant ROCK = 10;
    uint8 public constant PAPER = 20;
    uint8 public constant SCISSORS = 30;
    uint8 public constant DEALERWIN = 201;
    uint8 public constant PLAYERWIN = 102;
    uint8 public constant DRAW = 101;

    event CreateGame(uint256 gameid, address dealer, uint256 amount);
    event JoinGame(uint256 gameid, address player, uint256 amount);
    event Reveal(uint256 gameid, address player, uint8 choice);
    event CloseGame(
        uint256 gameid,
        address dealer,
        address player,
        uint8 result
    );

    ///  struct of a game
    struct Game {
        uint256 expireTime;
        address dealer;
        uint256 dealerValue;
        bytes32 dealerHash;
        uint8 dealerChoice;
        address player;
        uint8 playerChoice;
        uint256 playerValue;
        uint8 result;
        bool closed;
    }

    // struct of a game
    mapping(uint256 => mapping(uint256 => uint8)) public payoff;
    mapping(uint256 => Game) public games;
    mapping(address => uint256[]) public gameidsOf;

    //Current game maximun id(initial from 0)
    uint256 public maxgame = 0;
    uint256 public expireTimeLimit = 30 minutes;

    // Initialization contract
    function GameResult() internal {
        payoff[ROCK][ROCK] = DRAW;
        payoff[ROCK][PAPER] = PLAYERWIN;
        payoff[ROCK][SCISSORS] = DEALERWIN;
        payoff[PAPER][ROCK] = DEALERWIN;
        payoff[PAPER][PAPER] = DRAW;
        payoff[PAPER][SCISSORS] = PLAYERWIN;
        payoff[SCISSORS][ROCK] = PLAYERWIN;
        payoff[SCISSORS][PAPER] = DEALERWIN;
        payoff[SCISSORS][SCISSORS] = DRAW;
        payoff[NONE][NONE] = DRAW;
        payoff[ROCK][NONE] = DEALERWIN;
        payoff[PAPER][NONE] = DEALERWIN;
        payoff[SCISSORS][NONE] = DEALERWIN;
        payoff[NONE][ROCK] = PLAYERWIN;
        payoff[NONE][PAPER] = PLAYERWIN;
        payoff[NONE][SCISSORS] = PLAYERWIN;
    }

    //create a game
    function createGame(bytes32 dealerHash, address payable player)
        public
        payable
        returns (uint256)
    {
        require(dealerHash != 0x0);
        maxgame += 1;
        //create a storage variable game and assign to mapping games
        Game storage game = games[maxgame];
        game.dealer = msg.sender;
        game.player = player;
        game.dealerHash = dealerHash;
        game.dealerChoice = NONE;
        game.dealerValue = msg.value;
        game.expireTime = expireTimeLimit + block.timestamp;
        emit CreateGame(maxgame, game.dealer, game.dealerValue);
        return maxgame;
    }

    //join a game
    function joinGame(uint256 gameid, uint8 choice)
        public
        payable
        returns (uint256)
    {
        Game storage game = games[gameid];
        require(
            msg.value == game.dealerValue &&
                game.dealer != address(0) &&
                game.dealer != msg.sender &&
                game.playerChoice == NONE
        );
        require(!game.closed);
        require(block.timestamp < game.expireTime);
        require(checkChoice(choice));
        game.player = msg.sender;
        game.playerChoice = choice;
        game.playerValue = msg.value;
        game.expireTime = expireTimeLimit + block.timestamp;

        emit JoinGame(gameid, game.player, game.playerValue);

        return gameid;
    }

    //game creator reveal his choice that match previous dealerhash
    function reveal(
        uint256 gameid,
        uint8 choice,
        bytes32 randomSecret
    ) public returns (bool) {
        Game storage game = games[gameid];
        bytes32 proof = getProof(msg.sender, choice, randomSecret);

        require(!game.closed);
        require(block.timestamp < game.expireTime);
        require(game.dealerHash != 0x0);
        require(checkChoice(choice));
        require(checkChoice(game.playerChoice));
        require((game.dealer == msg.sender && proof == game.dealerHash));

        game.dealerChoice = choice;
        emit Reveal(gameid, msg.sender, choice);
        close(gameid);
        return true;
    }

    //close the gmae and settle rewards
    function close(uint256 gameid) public returns (bool) {
        Game storage game = games[gameid];
        require(!game.closed);
        require(
            block.timestamp > game.expireTime ||
                (game.dealerChoice != NONE && game.playerChoice != NONE)
        );

        uint8 result = payoff[game.dealerChoice][game.playerChoice];

        if (result == DEALERWIN) {
            require(
                payable(game.dealer).send(
                    safeAdd(game.dealerValue, game.playerValue)
                )
            );
        } else if (result == PLAYERWIN) {
            require(
                payable(game.player).send(
                    safeAdd(game.dealerValue, game.playerValue)
                )
            );
        } else if (result == DRAW) {
            require(
                payable(game.dealer).send(game.dealerValue) &&
                    payable(game.player).send(game.playerValue)
            );
        }
        game.closed = true;
        game.result = result;

        emit CloseGame(gameid, game.dealer, game.player, result);

        return game.closed;
    }

    function getProof(
        address sender,
        uint8 choice,
        bytes32 randomSecret
    ) public view returns (bytes32) {
        console.log("get hashing");
        return keccak256(abi.encodePacked(sender, choice, randomSecret));
    }

    function checkChoice(uint8 choice) public view returns (bool) {
        console.log("get choice");

        return choice == ROCK || choice == PAPER || choice == SCISSORS;
    }
}
