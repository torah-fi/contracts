// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

interface IStablecoinPool {
    function mintingFee() external returns (uint256);

    function redeemCollateralBalances(address addr) external returns (uint256);

    function redemptionFee() external returns (uint256);

    function buybackFee() external returns (uint256);

    function recollatFee() external returns (uint256);

    function collatDollarBalance() external returns (uint256);

    function availableExcessCollatDV() external returns (uint256);

    function getCollateralPrice() external returns (uint256);

    function setCollatETHOracle(address _collateral_weth_oracle_address, address _weth_address) external;

    function mint1t1Stable(uint256 collateralAmount, uint256 FRAX_out_min) external;

    function mintAlgorithmicStable(uint256 fxs_amount_d18, uint256 FRAX_out_min) external;

    function mintFractionalStable(
        uint256 collateralAmount,
        uint256 fxs_amount,
        uint256 FRAX_out_min
    ) external;

    function redeem1t1Stable(uint256 FRAX_amount, uint256 COLLATERAL_out_min) external;

    function redeemFractionalStable(
        uint256 FRAX_amount,
        uint256 FXS_out_min,
        uint256 COLLATERAL_out_min
    ) external;

    function redeemAlgorithmicStable(uint256 FRAX_amount, uint256 FXS_out_min) external;

    function collectRedemption() external;

    function recollateralizeStable(uint256 collateralAmount, uint256 FXS_out_min) external;

    function buyBackStock(uint256 FXS_amount, uint256 COLLATERAL_out_min) external;

    function toggleMinting() external;

    function toggleRedeeming() external;

    function toggleRecollateralize() external;

    function toggleBuyBack() external;

    function toggleCollateralPrice(uint256 _new_price) external;

    function setPoolParameters(
        uint256 new_ceiling,
        uint256 new_bonus_rate,
        uint256 new_redemption_delay,
        uint256 new_mint_fee,
        uint256 new_redeem_fee,
        uint256 new_buybackFee,
        uint256 new_recollatFee
    ) external;

    function setTimelock(address new_timelock) external;

    function setOwner(address _owner_address) external;

    function amoMinterBorrow(uint256 collateralAmount) external;
}
