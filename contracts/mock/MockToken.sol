// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MockToken is ERC20, ERC20Burnable {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 total
    ) public ERC20(name, symbol) {
        _mint(msg.sender, total);
        decimals;
    }

    function underlyingAssetAddress() external view returns (address) {
        return address(this);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}
