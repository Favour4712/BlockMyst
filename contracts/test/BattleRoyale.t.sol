// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/competitive/BattleRoyale.sol";
import "../src/interfaces/IBattleRoyale.sol";
import "../src/core/PuzzleManager.sol";

contract BattleRoyaleTest is Test {
    BattleRoyale public battleRoyale;
    PuzzleManager public puzzleManager;

    address public owner;
    address public player1;
    address public player2;
    address public player3;

    event BattleCreated(
        uint256 indexed battleId,
        uint256 prizePool,
        uint256 maxRounds
    );
    event PlayerJoined(uint256 indexed battleId, address indexed player);
    event RoundCompleted(
        uint256 indexed battleId,
        uint256 round,
        uint256 playersEliminated
    );
    event PlayerEliminated(
        uint256 indexed battleId,
        address indexed player,
        uint256 round
    );
    event BattleCompleted(uint256 indexed battleId, address[] winners);

    function setUp() public {
        owner = address(this);
        player1 = makeAddr("player1");
        player2 = makeAddr("player2");
        player3 = makeAddr("player3");

        vm.deal(player1, 10 ether);
        vm.deal(player2, 10 ether);
        vm.deal(player3, 10 ether);

        puzzleManager = new PuzzleManager();
        battleRoyale = new BattleRoyale();

        battleRoyale.setPuzzleManager(address(puzzleManager));

        // Fund puzzle manager
        puzzleManager.fundRewardPool{value: 10 ether}();
    }

    function testCreateBattle() public {
        uint256 prizePool = 5 ether;
        uint256 maxRounds = 3;

        // Create puzzles
        uint256[] memory puzzleIds = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            puzzleIds[i] = puzzleManager.createPuzzle(
                string(abi.encodePacked("QmTest", i)),
                keccak256(abi.encodePacked("answer", i)),
                1 ether,
                2,
                block.timestamp,
                block.timestamp + 7 days,
                "DeFi"
            );
        }

        vm.expectEmit(true, false, false, true);
        emit BattleCreated(1, prizePool, maxRounds);

        uint256 battleId = battleRoyale.createBattle(
            prizePool,
            puzzleIds,
            maxRounds
        );

        assertEq(battleId, 1);

        IBattleRoyale.Battle memory battle = battleRoyale.getBattle(battleId);
        assertEq(battle.prizePool, prizePool);
        assertEq(battle.maxRounds, maxRounds);
        assertTrue(battle.active);
    }

    function testJoinBattle() public {
        // Create battle
        uint256[] memory puzzleIds = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            puzzleIds[i] = puzzleManager.createPuzzle(
                string(abi.encodePacked("QmTest", i)),
                keccak256(abi.encodePacked("answer", i)),
                1 ether,
                2,
                block.timestamp,
                block.timestamp + 7 days,
                "DeFi"
            );
        }

        uint256 battleId = battleRoyale.createBattle(5 ether, puzzleIds, 3);

        vm.prank(player1);
        vm.expectEmit(true, true, false, false);
        emit PlayerJoined(battleId, player1);

        battleRoyale.joinBattle{value: 0.1 ether}(battleId);

        assertTrue(battleRoyale.isPlayerInBattle(battleId, player1));
    }

    function testCannotJoinWithInsufficientFee() public {
        uint256[] memory puzzleIds = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            puzzleIds[i] = puzzleManager.createPuzzle(
                string(abi.encodePacked("QmTest", i)),
                keccak256(abi.encodePacked("answer", i)),
                1 ether,
                2,
                block.timestamp,
                block.timestamp + 7 days,
                "DeFi"
            );
        }

        uint256 battleId = battleRoyale.createBattle(5 ether, puzzleIds, 3);

        vm.prank(player1);
        vm.expectRevert("BattleRoyale: insufficient entry fee");
        battleRoyale.joinBattle{value: 0.05 ether}(battleId);
    }

    function testCannotJoinTwice() public {
        uint256[] memory puzzleIds = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            puzzleIds[i] = puzzleManager.createPuzzle(
                string(abi.encodePacked("QmTest", i)),
                keccak256(abi.encodePacked("answer", i)),
                1 ether,
                2,
                block.timestamp,
                block.timestamp + 7 days,
                "DeFi"
            );
        }

        uint256 battleId = battleRoyale.createBattle(5 ether, puzzleIds, 3);

        vm.startPrank(player1);
        battleRoyale.joinBattle{value: 0.1 ether}(battleId);

        vm.expectRevert("BattleRoyale: already joined");
        battleRoyale.joinBattle{value: 0.1 ether}(battleId);
        vm.stopPrank();
    }

    function testGetBattlePlayers() public {
        uint256[] memory puzzleIds = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            puzzleIds[i] = puzzleManager.createPuzzle(
                string(abi.encodePacked("QmTest", i)),
                keccak256(abi.encodePacked("answer", i)),
                1 ether,
                2,
                block.timestamp,
                block.timestamp + 7 days,
                "DeFi"
            );
        }

        uint256 battleId = battleRoyale.createBattle(5 ether, puzzleIds, 3);

        vm.prank(player1);
        battleRoyale.joinBattle{value: 0.1 ether}(battleId);

        vm.prank(player2);
        battleRoyale.joinBattle{value: 0.1 ether}(battleId);

        address[] memory players = battleRoyale.getBattlePlayers(battleId);
        assertEq(players.length, 2);
        assertEq(players[0], player1);
        assertEq(players[1], player2);
    }

    function testGetPlayerBattleStats() public {
        uint256[] memory puzzleIds = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            puzzleIds[i] = puzzleManager.createPuzzle(
                string(abi.encodePacked("QmTest", i)),
                keccak256(abi.encodePacked("answer", i)),
                1 ether,
                2,
                block.timestamp,
                block.timestamp + 7 days,
                "DeFi"
            );
        }

        uint256 battleId = battleRoyale.createBattle(5 ether, puzzleIds, 3);

        vm.prank(player1);
        battleRoyale.joinBattle{value: 0.1 ether}(battleId);

        IBattleRoyale.BattlePlayer memory stats = battleRoyale
            .getPlayerBattleStats(battleId, player1);
        assertEq(stats.playerAddress, player1);
        assertEq(stats.score, 0);
        assertFalse(stats.eliminated);
    }

    function testGetActiveBattle() public {
        uint256[] memory puzzleIds = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            puzzleIds[i] = puzzleManager.createPuzzle(
                string(abi.encodePacked("QmTest", i)),
                keccak256(abi.encodePacked("answer", i)),
                1 ether,
                2,
                block.timestamp,
                block.timestamp + 7 days,
                "DeFi"
            );
        }

        uint256 battleId = battleRoyale.createBattle(5 ether, puzzleIds, 3);

        IBattleRoyale.Battle memory activeBattle = battleRoyale
            .getActiveBattle();
        assertEq(activeBattle.id, battleId);
        assertTrue(activeBattle.active);
    }

    receive() external payable {}
}
