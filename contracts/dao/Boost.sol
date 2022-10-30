// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interface/IGauge.sol";
import "../interface/IGaugeFactory.sol";

import "./AbstractBoost.sol";

contract Boost is ReentrancyGuard, AbstractBoost {
    using SafeMath for uint256;

    event GaugeCreated(address indexed gauge, address creator, address indexed pool);

    event NotifyReward(address indexed sender, address indexed reward, uint256 amount);
    event DistributeReward(address indexed sender, address indexed gauge, uint256 amount);

    // Info of each pool.
    struct PoolInfo {
        address lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
    }

    address public immutable gaugeFactory;
    uint256 public totalAllocPoint = 0;
    PoolInfo[] public poolInfo;
    // pid corresponding address
    mapping(address => uint256) public lpOfPid;

    uint256 public mintDuration = 7 * 28800; // rewards are released over 7 days

    mapping(address => address) public gauges; // pool => gauge
    mapping(address => address) public poolForGauge; // gauge => pool
    mapping(address => bool) public isGauge;

    constructor(
        address _operatorMsg,
        address __ve,
        address _gauges,
        IToken _swapToken,
        uint256 _tokenPerBlock,
        uint256 _startBlock,
        uint256 _period
    ) AbstractBoost(_operatorMsg, __ve, _swapToken, _tokenPerBlock, _startBlock, _period) {
        gaugeFactory = _gauges;
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    function createGauge(
        address _pool,
        uint256 _allocPoint,
        bool _withUpdate
    ) onlyOperator external returns (address) {
        require(gauges[_pool] == address(0x0), "exists");

        require(address(_pool) != address(0), "_lpToken is the zero address");
        require(IERC20(_pool).totalSupply() >= 0, "is erc20");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({lpToken : _pool, allocPoint : _allocPoint, lastRewardBlock : lastRewardBlock}));
        lpOfPid[address(_pool)] = poolLength() - 1;

        address _gauge = IGaugeFactory(gaugeFactory).createGauge(_pool, veToken, address(swapToken));
        IERC20(address(swapToken)).approve(_gauge, type(uint256).max);
        gauges[_pool] = _gauge;
        poolForGauge[_gauge] = _pool;
        isGauge[_gauge] = true;
        _updateForGauge(_gauge);
        emit GaugeCreated(_gauge, msg.sender, _pool);
        return _gauge;
    }

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public {
        require(controllers[msg.sender] || msg.sender == operator(), "no auth");

        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        if (_withUpdate) {
            massUpdatePools();
        }
    }

    function setMitDuration(uint256 _duration) public onlyOperator {
        mintDuration = _duration;
    }

    function massUpdatePools() public override {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public reduceBlockReward {
        require(totalAllocPoint > 0, "total=0");
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = IERC20(pool.lpToken).balanceOf(gauges[pool.lpToken]);
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        if (tokenPerBlock <= 0) {
            return;
        }
        uint256 tokenReward = tokenPerBlock.mul(pool.allocPoint).div(totalAllocPoint);
        if (IERC20(swapToken).balanceOf(gauges[pool.lpToken]) < tokenReward.mul(mintDuration)) {
            bool minRet = swapToken.mint(address(this), tokenReward.mul(mintDuration));
            if (minRet) {
                TransferHelper.safeTransfer(address(swapToken), gauges[pool.lpToken], tokenReward.mul(mintDuration));
                IGauge(gauges[pool.lpToken]).notifyRewardAmount(
                    address(swapToken),
                    tokenReward
                );

            }
            pool.lastRewardBlock = block.number;
        }
    }

    function updateAll() external {
        for (uint256 i = 0; i < poolLength(); i++) {
            PoolInfo memory pool = poolInfo[i];
            _updateForGauge(gauges[pool.lpToken]);
        }
    }

    function _updateForGauge(address _gauge) internal {
        address _pool = poolForGauge[_gauge];
        updatePool(lpOfPid[_pool]);
    }

    function claimRewards(address[] memory _gauges) external {
        for (uint256 i = 0; i < _gauges.length; i++) {
            IGauge(_gauges[i]).getReward(msg.sender);
        }
    }

    function distribute(address _gauge) public {
        _updateForGauge(_gauge);
    }

    function _updatePoolInfo(address _pool) internal override {
        _updateForGauge(gauges[_pool]);
    }

    function _isGaugeForPool(address _pool) internal view override returns (bool) {
        return isGauge[gauges[_pool]];
    }
}
