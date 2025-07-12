// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

abstract contract Constants {
    /** VRF Mock Constants */

    uint96 public constant BASE_FEE = 0.25 * 1e18;
    uint96 public constant GAS_PRICE_LINK = 1e9;
    int256 public constant INITIAL_REQUEST_CONFIRMATIONS = 4e16;

    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is Script, Constants {
    error HelperConfig__InvalidChainId(uint256 chainId);
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        bytes32 keyHash;
        address link;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfig;

    constructor() {
        networkConfig[SEPOLIA_CHAIN_ID] = getSepoliEthCongfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (networkConfig[chainId].vrfCoordinator != address(0)) {
            return networkConfig[chainId];
        }

        if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateLocalConfig(block.chainid);
        } else {
            revert HelperConfig__InvalidChainId(chainId);
        }
    }

    function getOrCreateLocalConfig(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (networkConfig[chainId].vrfCoordinator != address(0)) {
            return networkConfig[chainId];
        }
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinator = new VRFCoordinatorV2_5Mock(
            BASE_FEE,
            GAS_PRICE_LINK,
            INITIAL_REQUEST_CONFIRMATIONS
        );
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30,
                vrfCoordinator: address(vrfCoordinator),
                subscriptionId: 0,
                callbackGasLimit: 5000,
                keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                link: address(linkToken)
            });
    }

    function getSepoliEthCongfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30,
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                subscriptionId: 115725534712828529745080958691772271492614837277766883773564631599985910000344,
                callbackGasLimit: 5000,
                keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
            });
    }
}
