// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.21;

import {IDelegateToken, IERC721Metadata, IERC721Receiver, IERC1155Receiver} from "./interfaces/IDelegateToken.sol";
import {MarketMetadata} from "src/MarketMetadata.sol";
import {PrincipalToken} from "src/PrincipalToken.sol";

import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";

import {IDelegateRegistry, DelegateTokenErrors as Errors, DelegateTokenStructs as Structs, DelegateTokenHelpers as Helpers} from "src/libraries/DelegateTokenLib.sol";
import {DelegateTokenStorageHelpers as StorageHelpers} from "src/libraries/DelegateTokenStorageHelpers.sol";
import {DelegateTokenRegistryHelpers as RegistryHelpers, RegistryHashes} from "src/libraries/DelegateTokenRegistryHelpers.sol";
import {DelegateTokenTransferHelpers as TransferHelpers, SafeERC20, IERC721, IERC20, IERC1155} from "src/libraries/DelegateTokenTransferHelpers.sol";

contract SplittableController is ReentrancyGuard, ISplittableController {
    using SafeERC20 for IERC20;

    /// @dev Mapping of delegate tokens and expiry lengths for which
    //SplitTokens are deployed
    mapping(address => bool) public isTokenDeployed;

    constructor(address _delegateRegistry, address _principalToken, address _marketMetadata) {
        delegateRegistry = _delegateRegistry;
        principalToken = _principalToken;
        marketMetadata = _marketMetadata;   
    }

    function split(address delegateToken, uint256 delegateTokenId, StorageHelpers.TokenDuration duration, uint256 amount) external override nonReentrant {
        // existence checks are performed in the view
        address masterSplit = getSplitToken(delegateToken, StorageHelpers.TokenDuration.DAY);
        Structs.DelegateInfo memory delegateInfo = IDelegateToken(delegateToken).getDelegateInfo(tokenId);
        // check that the delegateToken owned by msg.sender has enough expiry
        uint256 endTimestamp = ISplittableToken(splitToken).getEndTimestamp(delegateToken, duration, amount);
        require(endTimestamp <= delegateInfo.expiry, Errors.DELTOKEN_EXPIRED);
        // transfer the delegateToken to the splitController

        // account for the splitTokens + remainder
        

        // mint the splitToken to msg.sender
        IMasterSplittableToken(masterSplit).mint(msg.sender, );
    }

    function getSplitToken(address delegateToken, StorageHelpers.TokenDuration duration) public view returns(address) {
        require(isTokenDeployed[delegateToken], Errors.DELTOKEN_NOT_DEPLOYED);
        return RegistryHelpers.getSplitToken(delegateToken, duration);
    }

    function deployToken(address delegateToken) external onlyOperator {
        require(!isTokenDeployed[delegateToken], Errors.DELTOKEN_ALREADY_DEPLOYED);
        // we deploy a master token contract for the day duration which will
        // manage the balance for each of the durations
        bytes32 salt = keccak256(abi.encodePacked(delegateToken, StorageHelpers.duration.DAY));
        SplitToken _new = new MasterSplitToken{salt: salt}(delegateToken, StorageHelpers.duration.DAY);
        for(int duration = StorageHelpers.duration.MONTH; duration <= StorageHelpers.duration.MONTH; duration++) {
            // deploy the token for duration
            bytes32 salt = keccak256(abi.encodePacked(delegateToken, duration));
            SplitToken _new = new SplitToken{salt: salt}(delegateToken, duration);
        }
    }
}
