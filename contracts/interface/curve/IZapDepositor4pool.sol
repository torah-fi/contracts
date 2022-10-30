// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

interface IZapDepositor4pool {
    function calc_token_amount(uint256[4] calldata amounts, bool _is_deposit) external returns (uint256);

    function n_coins() external view returns (int128);

    function underlying_coins(uint256 i) external view returns (address);

    function exchange_underlying(
        uint256 _i,
        uint256 _j,
        uint256 _dx,
        uint256 _min_dy,
        address receiver
    ) external;
}
