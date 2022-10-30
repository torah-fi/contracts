// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

interface IOracle {
    function getPrice() external view returns (uint256);
}

contract TestOracle is IOracle {
    address admin;
    uint256 price = 10**18;

    constructor() {
        admin = msg.sender;
    }

    function getPrice() external view override returns (uint256) {
        return price;
    }

    function setPrice(uint256 _price) external {
        require(admin == msg.sender, "Only admin");
        price = _price;
    }
}
