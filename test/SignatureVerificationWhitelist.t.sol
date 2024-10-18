// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/SignatureVerificationWhitelist.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("MockToken", "MTK") {
        _mint(msg.sender, 1000000 * 10**decimals());
    }
}

contract SignatureVerificationWhitelistTest is Test {
    SignatureVerificationWhitelist public verifier;
    MockERC20 public token;
    uint256 public constant TOKEN_AMOUNT = 100 * 10**18;

    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);

    function setUp() public {
        vm.startPrank(owner);
        token = new MockERC20();
        verifier = new SignatureVerificationWhitelist(address(token), TOKEN_AMOUNT);
        token.transfer(address(verifier), 1000000 * 10**18);
        vm.stopPrank();
    }

    function testClaimTokens() public {
        bytes32 messageHash = keccak256(abi.encodePacked("Claim tokens"));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(owner);
        verifier.updateWhitelist(user1, true);

        vm.prank(user1);
        verifier.claimTokens(messageHash, signature);

        assertEq(token.balanceOf(user1), TOKEN_AMOUNT);
    }

    function testClaimTokensFail_NotWhitelisted() public {
        bytes32 messageHash = keccak256(abi.encodePacked("Claim tokens"));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(2, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Address not whitelisted");
        vm.prank(user2);
        verifier.claimTokens(messageHash, signature);
    }

    function testClaimTokensFail_AlreadyClaimed() public {
        bytes32 messageHash = keccak256(abi.encodePacked("Claim tokens"));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(owner);
        verifier.updateWhitelist(user1, true);

        vm.prank(user1);
        verifier.claimTokens(messageHash, signature);

        vm.expectRevert("Tokens already claimed");
        vm.prank(user1);
        verifier.claimTokens(messageHash, signature);
    }

    function testUpdateWhitelist() public {
        vm.prank(owner);
        verifier.updateWhitelist(user1, true);
        assertTrue(verifier.whitelist(user1));

        vm.prank(owner);
        verifier.updateWhitelist(user1, false);
        assertFalse(verifier.whitelist(user1));
    }

    function testWithdrawTokens() public {
        uint256 initialBalance = token.balanceOf(owner);
        uint256 withdrawAmount = 1000 * 10**18;

        vm.prank(owner);
        verifier.withdrawTokens(withdrawAmount);

        assertEq(token.balanceOf(owner), initialBalance + withdrawAmount);
    }
}