// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../tools/TransferHelper.sol";
import "../interface/IToken.sol";
import "../tools/CheckPermission.sol";

abstract contract TokenReward is CheckPermission {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event SetPool(address indexed pool, uint256 point);
    event AddPool(address indexed pool, uint256 point);

    IToken public swapToken;

    uint256 public tokenPerBlock;
    uint256 public immutable startBlock;
    uint256 public periodEndBlock;
    // How many blocks (90 days) are halved 2592000
    uint256 public period;

    uint256 public mintMulti;

    uint256 public minTokenReward = 1.75e17;

    constructor(
        address _operatorMsg,
        IToken _swapToken,
        uint256 _tokenPerBlock,
        uint256 _startBlock,
        uint256 _period
    ) CheckPermission(_operatorMsg) {
        require(address(_swapToken) != address(0), "swapToken is 0");
        swapToken = _swapToken;
        tokenPerBlock = _tokenPerBlock;
        startBlock = _startBlock;
        period = _period;
        periodEndBlock = _startBlock.add(_period);
        mintMulti = 1000;
    }

    modifier reduceBlockReward() {
        if (block.number > startBlock && block.number >= periodEndBlock) {
            if (tokenPerBlock > minTokenReward) {
                tokenPerBlock = tokenPerBlock.mul(80).div(100);
            }
            if (tokenPerBlock < minTokenReward) {
                tokenPerBlock = minTokenReward;
            }
            periodEndBlock = block.number.add(period);
        }
        _;
    }

    function setHalvingPeriod(uint256 _block) public onlyOperator {
        period = _block;
    }

    function setMintMulti(uint256 _multi) public onlyOperator {
        mintMulti = _multi;
    }

    function setMinTokenReward(uint256 _reward) public onlyOperator {
        minTokenReward = _reward;
    }

    // Set the number of swap produced by each block
    function setTokenPerBlock(uint256 _newPerBlock, bool _withUpdate) public onlyOperator {
        tokenPerBlock = _newPerBlock;
        if (_withUpdate) {
            massUpdatePools();
        }
    }

    // Safe swap token transfer function, just in case if rounding error causes pool to not have enough swaps.
    function _safeTokenTransfer(address _to, uint256 _amount) internal {
        _mintRewardToken(_amount);
        uint256 bal = swapToken.balanceOf(address(this));
        if (_amount > bal) {
            _amount = bal;
        }
        TransferHelper.safeTransfer(address(swapToken), _to, _amount);
    }

    function _mintRewardToken(uint256 _amount) private {
        uint256 bal = swapToken.balanceOf(address(this));
        if (bal < _amount) {
            swapToken.mint(address(this), _amount.mul(mintMulti));
        }
    }

    function massUpdatePools() public virtual;
}
