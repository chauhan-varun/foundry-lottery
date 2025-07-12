// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    uint256 subscriptionId;
    uint32 callbackGasLimit;
    bytes32 keyHash;

    address public PLAYER = makeAddr("player");
    uint256 public constant PLAYER_INIITAL_BALANCE = 10 ether;

    /** events */
    event RequestedRaffleWinner(uint256 indexed requestId);
    event PlayerEntered(address indexed player);
    event PickedWinner(address indexed winner);

    function setUp() public {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
        keyHash = config.keyHash;
        vm.deal(PLAYER, PLAYER_INIITAL_BALANCE);
    }

    function testRaffleInitializesIsOpen() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.Open);
    }

    /*//////////////////////////////////////////////////////////////
                              ENTER RAFFLE
    //////////////////////////////////////////////////////////////*/

    modifier enteredRaffle() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        _;
    }

    function testRaffleRevertWhenYouDontPay() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__NotEnoughFunds.selector);
        raffle.enterRaffle();
    }

    function testRafflePlayerRecords() public enteredRaffle {
        assert(raffle.getRafflePlayer(0) == PLAYER);
    }

    function testEnteringRaffleEventEmits() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(PLAYER));
        emit PlayerEntered(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testRevertPlayerWhenRaffleIsClosed() public enteredRaffle {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.expectRevert();
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }
}
