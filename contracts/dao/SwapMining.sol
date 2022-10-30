// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

//import './lib/OracleLibrary.sol';
import "./AbstractBoost.sol";
import "../interface/ISwapMining.sol";

contract SwapMining is AbstractBoost, ISwapMining {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    event SwapMining(address indexed account, address indexed pair, uint256 quantity);

    event ChangeRouter(address indexed oldRouter, address indexed newRouter);

    struct UserInfo {
        uint256 quantity; // How many LP tokens the user has provided
        uint256 blockNumber; // Last transaction block
    }

    struct PoolInfo {
        address pair; // Trading pairs that can be mined
        uint256 quantity; // Current amount of LPs
        uint256 allocPoint; // How many allocation points assigned to this pool
        uint256 allocSwapTokenAmount; // How many token
        uint256 lastRewardBlock; // Last transaction block
    }

    // Total allocation points
    uint256 public totalAllocPoint = 0;
    // router address
    address public router;
    // factory address
    address public factory;
    // pair corresponding pid
    mapping(address => uint256) public lpOfPid;

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    constructor(
        address _operatorMsg,
        address __ve,
        IToken _swapToken,
        address _factory,
        address _router,
        uint256 _swapPerBlock,
        uint256 _startBlock,
        uint256 _period
    ) AbstractBoost(_operatorMsg, __ve, _swapToken, _swapPerBlock, _startBlock, _period) {
        require(_factory != address(0), "!0");
        require(_router != address(0), "!0");
        factory = _factory;
        router = _router;
        emit ChangeRouter(address(0), router);
    }

    modifier onlyRouter() {
        require(msg.sender == router, "SwapMining: caller is not the router");
        _;
    }

    // Get rewards from users in the current pool
    function pending(uint256 _pid, address _user) public view returns (uint256, uint256) {
        require(_pid < poolInfo.length, "SwapMining: Not find this pool");
        uint256 userSub;
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        if (user.quantity > 0) {
            uint256 mul = block.number.sub(pool.lastRewardBlock);
            uint256 tokenReward = tokenPerBlock.mul(mul).mul(pool.allocPoint).div(totalAllocPoint);
            userSub = userSub.add((pool.allocSwapTokenAmount.add(tokenReward)).mul(user.quantity).div(pool.quantity));
        }
        //swap available to users, User transaction amount
        return (userSub, user.quantity);
    }

    // Get details of the pool
    function getPoolInfo(uint256 _pid)
    public
    view
    returns (
        address,
        uint256,
        uint256,
        uint256
    )
    {
        require(_pid <= poolInfo.length - 1, "SwapMining: Not find this pool");
        PoolInfo memory pool = poolInfo[_pid];
        uint256 tokenAmount = pool.allocSwapTokenAmount;
        uint256 mul = block.number.sub(pool.lastRewardBlock);
        uint256 tokenReward = tokenPerBlock.mul(mul).mul(pool.allocPoint).div(totalAllocPoint);
        tokenAmount = tokenAmount.add(tokenReward);
        //token0,token1,Pool remaining reward,Total /Current transaction volume of the pool
        return (pool.pair, tokenAmount, pool.quantity, pool.allocPoint);
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    function rewardInfo(address account) public view returns (uint256) {
        uint256 userSub;
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            UserInfo storage user = userInfo[pid][account];
            if (user.quantity > 0) {
                uint256 userReward = pool.allocSwapTokenAmount.mul(user.quantity).div(pool.quantity);
                userReward = getBoost(pid, account, userReward);
                userSub = userSub.add(userReward);
            }
        }
        return userSub;
    }


    function rewardInfoMax(address account) public view returns (uint256) {
        uint256 userSub;
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            UserInfo storage user = userInfo[pid][account];
            if (user.quantity > 0) {
                uint256 userReward = pool.allocSwapTokenAmount.mul(user.quantity).div(pool.quantity);
                userSub = userSub.add(userReward);
            }
        }
        return userSub;
    }

    function rewardPoolInfo(uint256 pid, address account) public view returns (uint256 userReward) {
        PoolInfo memory pool = poolInfo[pid];
        UserInfo memory user = userInfo[pid][account];
        if (user.quantity > 0) {
            userReward = pool.allocSwapTokenAmount.mul(user.quantity).div(pool.quantity);
            userReward = getBoost(pid, account, userReward);
        }
        return userReward;
    }

    function rewardPoolInfoMax(uint256 pid, address account) public view returns (uint256 userReward) {
        PoolInfo memory pool = poolInfo[pid];
        UserInfo memory user = userInfo[pid][account];
        if (user.quantity > 0) {
            userReward = pool.allocSwapTokenAmount.mul(user.quantity).div(pool.quantity);
        }
        return userReward;
    }

    function addPair(
        uint256 _allocPoint,
        address _pool,
        bool _withUpdate
    ) public onlyOperator {
        require(_pool != address(0), "_pair is the zero address");
        if (poolLength() > 0) {
            require((lpOfPid[_pool] == 0) && (address(poolInfo[0].pair) != _pool), "only one pair");
        }
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
        pair : _pool,
        quantity : 0,
        allocPoint : _allocPoint,
        allocSwapTokenAmount : 0,
        lastRewardBlock : lastRewardBlock
        })
        );
        lpOfPid[_pool] = poolLength() - 1;
        emit AddPool(_pool, _allocPoint);
    }

    // Update the allocPoint of the pool
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
        emit SetPool(poolInfo[_pid].pair, _allocPoint);
    }

    function setRouter(address newRouter) public onlyOperator {
        require(newRouter != address(0), "SwapMining: new router is the zero address");
        address oldRouter = router;
        router = newRouter;
        emit ChangeRouter(oldRouter, router);
    }

    // swapMining only router
    function swap(
        address account,
        address pair,
        uint256 quantity
    ) public override onlyRouter returns (bool) {
        require(account != address(0), "SwapMining: taker swap account is the zero address");
        require(pair != address(0), "SwapMining: taker swap pair is the zero address");

        if (poolLength() == 0) {
            return false;
        }
        uint256 _pid = lpOfPid[pair];
        PoolInfo storage pool = poolInfo[_pid];
        // If it does not exist or the allocPoint is 0 then return
        if (pool.pair != pair || pool.allocPoint <= 0) {
            return false;
        }

        updatePool(_pid);
        if (quantity == 0) {
            return false;
        }

        pool.quantity = pool.quantity.add(quantity);
        UserInfo storage user = userInfo[lpOfPid[pair]][account];
        user.quantity = user.quantity.add(quantity);
        user.blockNumber = block.number;
        emit SwapMining(account, pair, quantity);
        return true;
    }

    // Update all pools Called when updating allocPoint and setting new blocks
    function massUpdatePools() public override {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public reduceBlockReward returns (bool) {
        require(totalAllocPoint > 0, "total=0");
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return false;
        }
        if (tokenPerBlock <= 0) {
            return false;
        }
        // Calculate the rewards obtained by the pool based on the allocPoint
        uint256 mul = block.number.sub(pool.lastRewardBlock);
        uint256 tokenReward = tokenPerBlock.mul(mul).mul(pool.allocPoint).div(totalAllocPoint);
        // Increase the number of tokens in the current pool
        pool.allocSwapTokenAmount = pool.allocSwapTokenAmount.add(tokenReward);
        pool.lastRewardBlock = block.number;
        return true;
    }

    // The user withdraws all the transaction rewards of the pool
    function getRewardAll() public override {
        uint256 userSub;
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            UserInfo storage user = userInfo[pid][msg.sender];
            if (user.quantity > 0) {
                updatePool(pid);
                // The reward held by the user in this pool
                uint256 userReward = pool.allocSwapTokenAmount.mul(user.quantity).div(pool.quantity);
                pool.quantity = pool.quantity.sub(user.quantity);
                pool.allocSwapTokenAmount = pool.allocSwapTokenAmount.sub(userReward);
                user.quantity = 0;
                user.blockNumber = block.number;
                userReward = getBoost(pid, msg.sender, userReward);
                userSub = userSub.add(userReward);
            }
        }
        if (userSub <= 0) {
            return;
        }
        _safeTokenTransfer(msg.sender, userSub);
    }

    // The user withdraws all the transaction rewards of one pool
    function getReward(uint256 pid) public override {
        uint256 userSub;
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        if (user.quantity > 0) {
            updatePool(pid);
            // The reward held by the user in this pool
            uint256 userReward = pool.allocSwapTokenAmount.mul(user.quantity).div(pool.quantity);
            pool.quantity = pool.quantity.sub(user.quantity);
            pool.allocSwapTokenAmount = pool.allocSwapTokenAmount.sub(userReward);
            user.quantity = 0;
            user.blockNumber = block.number;
            userSub = userSub.add(userReward);
        }
        if (userSub <= 0) {
            return;
        }
        userSub = getBoost(pid, msg.sender, userSub);
        _safeTokenTransfer(msg.sender, userSub);
    }

    function getBoost(
        uint256 pid,
        address account,
        uint256 amount
    ) public view returns (uint256) {
        uint256 _derived = (amount * 30) / 100;
        uint256 _adjusted = 0;
        uint256 _tokenId = IVeToken(veToken).tokenOfOwnerByIndex(account, 0);
        //        PoolInfo memory pool = poolInfo[pid];
        UserInfo memory user = userInfo[pid][account];
        uint256 usedWeight = usedWeights[_tokenId];
        if (usedWeight > 0 && totalWeight > 0) {
            uint256 useVe = IVeToken(veToken).balanceOfNFT(_tokenId);
            _adjusted = (((user.quantity * useVe) / totalWeight) * 70) / 100;
        }
        return Math.min((_derived + _adjusted), amount);
    }

    function _updatePoolInfo(address _pool) internal override {
        updatePool(lpOfPid[_pool]);
    }

    function _isGaugeForPool(address _pool) internal view override returns (bool) {
        uint256 _pid = lpOfPid[_pool];
        PoolInfo memory pool = poolInfo[_pid];
        return pool.pair == _pool;
    }
}
