// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStablecoin is IERC20 {
    function globalCollateralValue() external view returns (uint256);

    function globalCollateralRatio() external view returns (uint256);

    function poolBurnFrom(address b_address, uint256 b_amount) external;

    function poolMint(address m_address, uint256 m_amount) external;

    //  function COLLATERAL_RATIO_PAUSER() external view returns (bytes32);
    //  function DEFAULT_ADMIN_ADDRESS() external view returns (address);
    //  function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
    //  function addPool(address pool_address ) external;
    //  function allowance(address owner, address spender ) external view returns (uint256);
    //  function approve(address spender, uint256 amount ) external returns (bool);
    //  function balanceOf(address account ) external view returns (uint256);
    //  function burn(uint256 amount ) external;
    //  function burnFrom(address account, uint256 amount ) external;
    //  function collateral_ratio_paused() external view returns (bool);
    //  function controller_address() external view returns (address);
    //  function creator_address() external view returns (address);
    //  function decimals() external view returns (uint8);
    //  function decreaseAllowance(address spender, uint256 subtractedValue ) external returns (bool);
    //  function eth_usd_consumer_address() external view returns (address);
    //  function eth_usd_price() external view returns (uint256);
    //  function frax_eth_oracle_address() external view returns (address);
    //  function frax_info() external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);
    //  function frax_pools(address ) external view returns (bool);
    //  function frax_pools_array(uint256 ) external view returns (address);
    //  function frax_price() external view returns (uint256);
    //  function frax_step() external view returns (uint256);
    //  function fxs_address() external view returns (address);
    //  function fxs_eth_oracle_address() external view returns (address);
    //  function fxs_price() external view returns (uint256);
    //  function genesis_supply() external view returns (uint256);
    //  function getRoleAdmin(bytes32 role ) external view returns (bytes32);
    //  function getRoleMember(bytes32 role, uint256 index ) external view returns (address);
    //  function getRoleMemberCount(bytes32 role ) external view returns (uint256);

    //  function grantRole(bytes32 role, address account ) external;
    //  function hasRole(bytes32 role, address account ) external view returns (bool);
    //  function increaseAllowance(address spender, uint256 addedValue ) external returns (bool);
    //  function last_call_time() external view returns (uint256);
    //  function mintingFee() external view returns (uint256);
    //  function name() external view returns (string memory);
    //  function owner_address() external view returns (address);

    //  function price_band() external view returns (uint256);
    //  function price_target() external view returns (uint256);
    //  function redemptionFee() external view returns (uint256);
    //  function refreshCollateralRatio() external;
    //  function refresh_cooldown() external view returns (uint256);
    //  function removePool(address pool_address ) external;
    //  function renounceRole(bytes32 role, address account ) external;
    //  function revokeRole(bytes32 role, address account ) external;
    //  function setController(address _controller_address ) external;
    //  function setETHUSDOracle(address _eth_usd_consumer_address ) external;
    //  function setStableEthOracle(address _frax_oracle_addr, address _weth_address ) external;
    //  function setStockAddress(address _fxs_address ) external;
    //  function setStockEthOracle(address _fxs_oracle_addr, address _weth_address ) external;
    //  function setStableStep(uint256 _new_step ) external;
    //  function setMintingFee(uint256 min_fee ) external;
    //  function setOwner(address _owner_address ) external;
    //  function setPriceBand(uint256 _price_band ) external;
    //  function setPriceTarget(uint256 _new_price_target ) external;
    //  function setRedemptionFee(uint256 red_fee ) external;
    //  function setRefreshCooldown(uint256 _new_cooldown ) external;
    //  function setTimelock(address new_timelock ) external;
    //  function symbol() external view returns (string memory);
    //  function timelock_address() external view returns (address);
    //  function toggleCollateralRatio() external;
    //  function totalSupply() external view returns (uint256);
    //  function transfer(address recipient, uint256 amount ) external returns (bool);
    //  function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
    //  function weth_address() external view returns (address);
}
