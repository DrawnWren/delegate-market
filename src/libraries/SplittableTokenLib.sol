// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.21;

library SplittableTokenLib {
    function getSplitToken(address delegateToken, StorageHelpers.TokenDuration duration) external view returns (address) {
            if (!isTokenDeployed[StorageHelpers.tokenId(delegateToken, duration)]) {
                address splitToken = RegistryHelpers.deploySplitToken(delegateToken, delegateRegistry, principalToken, marketMetadata);
                isTokenDeployed[delegateToken] = true;
                return splitToken;
            } else {
                return RegistryHelpers.getSplitToken(delegateToken, delegateRegistry);
            }
        }
}
