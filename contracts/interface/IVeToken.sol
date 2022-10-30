// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IVeToken {
    function token() external view returns (address);

    function tokenOfOwnerByIndex(address _owner, uint256 _tokenIndex) external view returns (uint256);

    function balanceOfNFT(uint256) external view returns (uint256);

    function isApprovedOrOwner(address, uint256) external view returns (bool);

    function ownerOf(uint256) external view returns (address);

    function transferFrom(
        address,
        address,
        uint256
    ) external;

    function voting(uint256 tokenId) external;

    function abstain(uint256 tokenId) external;
}
