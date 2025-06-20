// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DAO} from "../src/DAO.sol";

contract DeployDAO is Script {

    function run() external returns (DAO) {
        vm.startBroadcast();

        DAO dao = new DAO();

        vm.stopBroadcast();

        return dao;
    }
}
