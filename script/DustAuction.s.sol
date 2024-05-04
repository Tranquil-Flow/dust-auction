// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import "./DustAuction.sol";

contract DeployDustAuction is Script {
    DustAuction public dustAuction;

    function setUp() public {
        // Initialize any state here
    }

    function run() public {
        // Deploy the DustAuction contract
        dustAuction = new DustAuction();

        // Log the address of the deployed contract
        console.log("Deployed DustAuction at:", address(dustAuction));
    }
}