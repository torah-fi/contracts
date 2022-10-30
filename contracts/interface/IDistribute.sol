// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IDistribute {
    function lpOfPid(address) external view returns (uint256);

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function massUpdatePools() external;
}
