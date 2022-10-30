// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Gauge.sol";
import "../tools/CheckPermission.sol";

contract GaugeFactory is CheckPermission {
    address public last;

    constructor(address _operatorMsg) CheckPermission(_operatorMsg) {}

    function createGauge(
        address _pool,
        address _ve,
        address _reward
    ) external returns (address) {
        last = address(new Gauge(address(operatable), _pool, _ve, msg.sender, _reward));
        return last;
    }
}
