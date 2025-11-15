// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/PuzzleManager.sol";

contract FundPoolScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address puzzleManagerAddress = vm.envAddress("PUZZLE_MANAGER_ADDRESS");
        uint256 fundAmount = vm.envUint("FUND_AMOUNT"); // Amount in wei

        vm.startBroadcast(deployerPrivateKey);

        PuzzleManager puzzleManager = PuzzleManager(
            payable(puzzleManagerAddress)
        );

        // Fund the reward pool
        puzzleManager.fundRewardPool{value: fundAmount}();

        uint256 newBalance = puzzleManager.getRewardPoolBalance();
        console.log("Funded reward pool with:", fundAmount);
        console.log("New reward pool balance:", newBalance);

        vm.stopBroadcast();
    }
}

