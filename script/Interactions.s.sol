// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {HelperConfig, Constants} from "../script/HelperConfig.s.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract Interactions is Script, Constants {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        (uint256 subscriptionId, ) = createSubscription(vrfCoordinator);
        return (subscriptionId, vrfCoordinator);
    }

    function createSubscription(
        address vrfCoordinator
    ) public returns (uint256, address) {
        vm.startBroadcast();
        uint256 subscriptionId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        return (subscriptionId, vrfCoordinator);
    }

    function run() external {
        // vm.startBroadcast();
        // // Raffle raffle = new Raffle();
        // vm.stopBroadcast();
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, Constants {
    uint256 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subscriptionId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function run() external {
        vm.startBroadcast();
        address mostRecentDeployedSmartContract = DevOpsTools
            .get_most_recent_deployment("Raffle", block.chainid);
        vm.stopBroadcast();
        addConsumerUsingConfig(mostRecentDeployedSmartContract);
    }

    function addConsumerUsingConfig(
        address mostRecentDeployedSmartContract
    ) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        addConsumer(
            mostRecentDeployedSmartContract,
            vrfCoordinator,
            subscriptionId
        );
    }

    function addConsumer(
        address mostRecentDeployedSmartContract,
        address vrfCoordinator,
        uint256 subscriptionId
    ) public {
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(
            subscriptionId,
            mostRecentDeployedSmartContract
        );
        vm.stopBroadcast();
    }
}
