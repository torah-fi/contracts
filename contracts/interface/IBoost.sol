// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IBoost {
    function distribute(address _gauge) external;

    function weights(address _pool) external view returns (uint256);

    function votes(uint256 _tokeId, address _pool) external view returns (uint256);

    function usedWeights(uint256 _tokeId) external view returns (uint256);
}
