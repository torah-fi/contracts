// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../tools/CheckPermission.sol";

abstract contract AbstractPausable is CheckPermission, Pausable {

    constructor(address _operatorMsg) CheckPermission(_operatorMsg) {}

    function togglePause() public onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }
}
