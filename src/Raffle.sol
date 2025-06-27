// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title A Raffle contract
 * @author varun chauhan
 * @notice this is for creating sample Raffle contract
 * @dev Raffle contract
 */

contract Raffle {
    /** errors */
    error Raffle__NotEnoughFunds();

    uint256 private immutable i_entranceFee;
    address payable[] private s_players;

    /** events */
    event PlayerEntered(address indexed player);

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughFunds();
        }
        s_players.push(payable(msg.sender));
        emit PlayerEntered(msg.sender);
    }

    function pickWinner() public {}

    /** getters */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
