// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

interface IStablePool {
    function n_coins() external view returns (int128);

    function coins(uint256) external view returns (address);

    function get_virtual_price() external view returns (uint256);

    function base_coins(uint256) external view returns (address);

    function add_liquidity(
        // sBTC pool
        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        // bUSD pool
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function remove_liquidity_imbalance(uint256[4] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[4] calldata amounts) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount,
        address receiver
    ) external returns (uint256);

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount,
        bool use_eth,
        address receiver
    ) external payable returns (uint256);

    function exchange_underlying(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount,
        address receiver
    ) external returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts, bool isDeposit) external returns (uint256);

    function calc_token_amount(uint256[3] calldata amounts, bool isDeposit) external returns (uint256);

    function calc_token_amount(uint256[4] calldata amounts, bool isDeposit) external returns (uint256);
}
