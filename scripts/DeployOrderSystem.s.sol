// SPDX-Lisence-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "../lib/forge-std/src/Script.sol";
import {OrderSystem} from "../contracts/OrderSystem.sol";

contract DeployOrderSystem is Script {
    OrderSystem public orderSystem;

    function run() external returns (OrderSystem) {
        vm.startBroadcast();
        orderSystem = new OrderSystem();
        vm.stopBroadcast();

        return orderSystem;
    }
}
