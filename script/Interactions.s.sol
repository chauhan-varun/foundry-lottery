// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {HelperConfig, Constants} from "../script/HelperConfig.s.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract Interactions is Script, Constants {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig
            .getConfigByChainId(block.chainid)
            .vrfCoordinator;
        address account = helperConfig
            .getConfigByChainId(block.chainid)
            .account;
        return createSubscription(vrfCoordinator, account);
    }

    function createSubscription(
        address vrfCoordinator,
        address account
    ) public returns (uint256, address) {
        console2.log("Creating subscription on chainId: ", block.chainid);
        vm.startBroadcast(account);
        uint256 subscriptionId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        console2.log("Your subscription Id is: ", subscriptionId);
        console2.log("Please update the subscriptionId in HelperConfig.s.sol");
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
        address account = helperConfig.getConfig().account;

        if (subscriptionId == 0) {
            Interactions createSub = new Interactions();
            (
                uint256 updatedSubscriptionId,
                address updatedVrfCoordinator
            ) = createSub.createSubscriptionUsingConfig();
            subscriptionId = updatedSubscriptionId;
            vrfCoordinator = updatedVrfCoordinator;
            console2.log(
                "New SubId Created! ",
                subscriptionId,
                "VRF Address: ",
                vrfCoordinator
            );
        }
        fundSubscription(vrfCoordinator, subscriptionId, linkToken, account);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint256 subscriptionId,
        address linkToken,
        address account
    ) public {
        console2.log("Funding subscription: ", subscriptionId);
        console2.log("Using vrfCoordinator: ", vrfCoordinator);
        console2.log("On ChainID: ", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast(account);
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subscriptionId,
                FUND_AMOUNT * 100
            );
            vm.stopBroadcast();
        } else {
            console2.log(LinkToken(linkToken).balanceOf(msg.sender));
            console2.log(msg.sender);
            console2.log(LinkToken(linkToken).balanceOf(address(this)));
            console2.log(address(this));
            vm.startBroadcast(account);
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
        address mostRecentDeployedSmartContract = DevOpsTools
            .get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentDeployedSmartContract);
    }

    function addConsumerUsingConfig(
        address mostRecentDeployedSmartContract
    ) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address account = helperConfig.getConfig().account;
        addConsumer(
            mostRecentDeployedSmartContract,
            vrfCoordinator,
            subscriptionId,
            account
        );
    }

    function addConsumer(
        address mostRecentDeployedSmartContract,
        address vrfCoordinator,
        uint256 subscriptionId,
        address account
    ) public {
        console2.log(
            "Adding consumer contract: ",
            mostRecentDeployedSmartContract
        );
        console2.log("Using vrfCoordinator: ", vrfCoordinator);
        console2.log("On ChainID: ", block.chainid);
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(
            subscriptionId,
            mostRecentDeployedSmartContract
        );
        vm.stopBroadcast();
    }
}
