// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interface/ICheckPermission.sol";
import "./Operatable.sol";

// seperate owner and operator, operator is for daily devops, only owner can update operator
contract CheckPermission is ICheckPermission {
    Operatable public operatable;

    event SetOperatorContract(address indexed oldOperator, address indexed newOperator);

    constructor(address _oper) {
        operatable = Operatable(_oper);
        emit SetOperatorContract(address(0), _oper);
    }

    modifier onlyOwner() {
        require(operatable.owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyOperator() {
        require(operatable.operator() == msg.sender, "not operator");
        _;
    }

    modifier onlyAEOWhiteList() {
        require(check(msg.sender), "aeo or whitelist");
        _;
    }

    function operator() public view override returns (address) {
        return operatable.operator();
    }

    function owner() public view override returns (address) {
        return operatable.owner();
    }

    function setOperContract(address _oper) public onlyOwner {
        require(_oper != address(0), "bad new operator");
        address oldOperator = address(operatable);
        operatable = Operatable(_oper);
        emit SetOperatorContract(oldOperator, _oper);
    }

    function check(address _target) public view override returns (bool) {
        return operatable.check(_target);
    }
}
