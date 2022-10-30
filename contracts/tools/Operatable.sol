// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

// seperate owner and operator, operator is for daily devops, only owner can update operator
contract Operatable is Ownable {
    event SetOperator(address indexed oldOperator, address indexed newOperator);

    address public operator;

    mapping(address => bool) public contractWhiteList;

    constructor() {
        operator = msg.sender;
        emit SetOperator(address(0), operator);
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "not operator");
        _;
    }

    function setOperator(address newOperator) public onlyOwner {
        require(newOperator != address(0), "bad new operator");
        address oldOperator = operator;
        operator = newOperator;
        emit SetOperator(oldOperator, newOperator);
    }

    // File: @openzeppelin/contracts/utils/Address.sol
    function isContract(address account) public view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function addContract(address _target) public onlyOperator {
        contractWhiteList[_target] = true;
    }

    function removeContract(address _target) public onlyOperator {
        contractWhiteList[_target] = false;
    }

    //Do not ban access to the user, need to be in the whitelist contract address to be able to access
    function check(address _target) public view returns (bool) {
        if (isContract(_target)) {
            return contractWhiteList[_target];
        }
        return true;
    }
}
