// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {Interactions} from "../script/Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external {
        // vm.startBroadcast();
        // // Raffle raffle = new Raffle();
        // vm.stopBroadcast();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            (config.subscriptionId, config.vrfCoordinator) = new Interactions()
                .createSubscription(config.vrfCoordinator);
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.subscriptionId,
            config.callbackGasLimit,
            config.keyHash
        );
        vm.stopBroadcast();

        return (raffle, helperConfig);
    }
}
