// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.21;

import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";

import {IDelegateRegistry, DelegateTokenErrors as Errors, DelegateTokenStructs as Structs, DelegateTokenHelpers as Helpers} from "src/libraries/DelegateTokenLib.sol";
import {DelegateTokenStorageHelpers as StorageHelpers} from "src/libraries/DelegateTokenStorageHelpers.sol";

contract MasterSplittableToken is ReentrancyGuard, SplittableToken, IMasterSplittableToken{
    address public delegateToken;
    StorageHelpers.TokenDuration duration;
    // address => cohort => balance
    mapping(address => mapping(uint256 => uint256)) public balances;
    // owner => cohort => end of minted splits
    mapping(uint256 => mapping(uint256 => uint256)) public delegateTokenOwners;

    constructor(address _delegateToken) {
        delegateToken = _delegateToken;
        // the master token is always for a day
        duration = StorageHelpers.TokenDuration.DAY;
        for(uint256 d = StorageHelpers.TokenDuration.Week; i <= StorageHelpers.TokenDuration.MONTH; i++) {
            // deploy the token for duration
            bytes32 salt = keccak256(abi.encodePacked(delegateToken, duration));
            SplitToken _new = new ClientSplitToken{salt: salt}(address(this), delegateToken, duration);
        }
    }

    function mint(address owner, address to, uint256 tokenId, StorageHelpers.TokenDuration duration, uint256 amount) external onlyController {
        Structs.DelegateInfo memory delegateInfo = IDelegateToken(delegateToken).getDelegateInfo(tokenId);
        require(endTimestamp <= delegateInfo.expiry, Errors.DELTOKEN_EXPIRED);
        require(delegateInfo.owner == owner, Errors.DELTOKEN_NOT_OWNED);
        require(delegateTOkenOwners[owner][tokenId] > 0, Errors.DELTOKEN_ALREADY_SPLIT)
        // mint the appropriate duration
        address toMint = StorageHelpers.getSplitToken(delegateToken, duration);

        // transfer the delegateToken to the MasterSplit
        IDelegateToken(delegateToken).safeTransferFrom(msg.sender, address(this), tokenId);
        ISplitToken(toMint).mint(to, amount);

        // keep track of the owner for the delegateToken
        delegateTokenOwners[msg.sender][tokenId] = true;
    }

    function extend(uint256 tokenId, StorageHelpers.TokenDuration duration) external {
        require(delegateTokenOwners[msg.sender][tokenId], Errors.DELTOKEN_NOT_OWNED);
        // extend the expiry of the delegateToken
        IDelegateToken(delegateToken).extend(tokenId, duration);
    }

    /// @dev you might have an already split delegate token that you would like
    //to produce more splits from in the future (e.g. you split a delegate
    //token, you've now extended the underlying, and you want to split again)
    function split(address owner, uint256 tokenId, StorageHelpers.TokenDuration duration, uint256 amount) external onlyController {
        require(delegateTokenOwners[msg.sender][tokenId], Errors.DELTOKEN_NOT_OWNED);
        // we only support extending the split
        uint256 seconds = SECONDS[duration];
        uint256 start = delegateTokenOwners[owner][tokenId];
        uint256 end = start % seconds + amount*seconds;
        Structs.DelegateInfo memory delegateInfo = IDelegateToken(delegateToken).getDelegateInfo(tokenId);
        require(end <= delegateInfo.expiry, Errors.DELTOKEN_EXPIRED);
        // split the delegateToken
        address toMint = StorageHelpers.getSplitToken(delegateToken, duration);
        ISplitToken(toMint).mint(owner, amount);
    }
}
