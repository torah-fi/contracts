// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IGauge {
    function notifyRewardAmount(address token, uint256 amount) external;

    function getReward(address account) external;

    function claimFees() external returns (uint256 claimed0, uint256 claimed1);

    function left(address token) external view returns (uint256);
}
