// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

// MAY need to be updated
interface IAMOMinter {
    function stableMintBalances(address) external view returns (int256);

    function burnStockFromAMO(uint256) external;

    function collatDollarBalance() external view returns (uint256);

    function collatDollarBalanceStored() external view returns (uint256);

    function burnStableFromAMO(uint256 frax_amount) external;

    function receiveCollatFromAMO(uint256 usdc_amount) external;
}
