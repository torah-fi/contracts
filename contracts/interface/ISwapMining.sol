// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface ISwapMining {
    function swap(
        address account,
        address pair,
        uint256 quantity
    ) external returns (bool);

    function getRewardAll() external;

    function getReward(uint256 pid) external;
}
