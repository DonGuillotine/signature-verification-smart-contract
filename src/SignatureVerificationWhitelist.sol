// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SignatureVerificationWhitelist is Ownable {
    using ECDSA for bytes32;

    IERC20 public immutable token;
    uint256 public immutable tokenAmount;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public hasClaimed;

    event TokensClaimed(address indexed claimant, uint256 amount);
    event WhitelistUpdated(address indexed account, bool isWhitelisted);

    constructor(address _token, uint256 _tokenAmount) Ownable(msg.sender) {
        token = IERC20(_token);
        tokenAmount = _tokenAmount;
    }

    function claimTokens(bytes32 messageHash, bytes memory signature) external {
        address signer = messageHash.recover(signature);
        require(whitelist[signer], "Address not whitelisted");
        require(!hasClaimed[signer], "Tokens already claimed");

        hasClaimed[signer] = true;
        require(token.transfer(signer, tokenAmount), "Token transfer failed");

        emit TokensClaimed(signer, tokenAmount);
    }

    function updateWhitelist(address account, bool isWhitelisted) external onlyOwner {
        whitelist[account] = isWhitelisted;
        emit WhitelistUpdated(account, isWhitelisted);
    }

    function withdrawTokens(uint256 amount) external onlyOwner {
        require(token.transfer(owner(), amount), "Token withdrawal failed");
    }
}