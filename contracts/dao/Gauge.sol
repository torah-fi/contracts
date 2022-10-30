// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../interface/IVeToken.sol";
import "../interface/IBoost.sol";
import "../tools/TransferHelper.sol";
import "../tools/CheckPermission.sol";

// Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
contract Gauge is ReentrancyGuard, CheckPermission {
    using SafeMath for uint256;


    event Deposit(address indexed from, uint256 amount);
    event Withdraw(address indexed from, uint256 amount);
    event EmergencyWithdraw(address indexed from, uint256 amount);
    event NotifyReward(address indexed from, address indexed reward, uint256 rewardRate);
    event ClaimRewards(address indexed from, address indexed reward, uint256 amount);

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt.
    }

    address public immutable stake; // the LP token that needs to be staked for rewards
    address public immutable veToken; // the ve token used for gauges
    address public immutable boost;
    address public immutable rewardToken;


    uint256 public tokenPerBlock;
    uint256 public accTokenPerShare; // Accumulated swap token per share, times 1e12.
    uint256 public lastRewardBlock; // Last block number that swap token distribution occurs

    uint256 public totalSupply;

    mapping(address => UserInfo) public userInfo;

    constructor(
        address _operatorMsg,
        address _stake,
        address __ve,
        address _boost,
        address _rewardToken
    ) CheckPermission(_operatorMsg) {
        stake = _stake;
        veToken = __ve;
        boost = _boost;
        rewardToken = _rewardToken;
        lastRewardBlock = block.number;
    }

    modifier onlyBoost() {
        require(msg.sender == boost, "only boost");
        _;
    }

    function _safeTransferFromToken(address token, uint256 _amount) private {
        uint256 bal = IERC20(token).balanceOf(address(this));
        if (bal < _amount) {
            TransferHelper.safeTransferFrom(token, boost, address(this), _amount);
        }
    }

    function _safeTokenTransfer(
        address token,
        address account,
        uint256 _amount
    ) internal {
        _safeTransferFromToken(token, _amount);
        uint256 bal = IERC20(token).balanceOf(address(this));
        if (_amount > bal) {
            _amount = bal;
        }
        _amount = derivedBalance(account, _amount);
        TransferHelper.safeTransfer(token, account, _amount);
    }

    function getReward(address account) external nonReentrant {
        require(msg.sender == account || msg.sender == boost);
        UserInfo storage user = userInfo[account];
        uint256 pendingAmount = pendingMax(account);
        if (pendingAmount > 0) {
            _safeTokenTransfer(rewardToken, account, pendingAmount);
            emit ClaimRewards(msg.sender, rewardToken, pendingAmount);
        }
        updatePool();
        user.rewardDebt = user.amount.mul(accTokenPerShare).div(1e12);
        IBoost(boost).distribute(address(this));

    }

    function derivedBalance(address account, uint256 _balance) public view returns (uint256) {
        uint256 _tokenId = IVeToken(veToken).tokenOfOwnerByIndex(account, 0);
        uint256 _derived = (_balance * 30) / 100;
        uint256 _adjusted = 0;
        uint256 _supply = IBoost(boost).weights(stake);
        uint256 usedWeight = IBoost(boost).usedWeights(_tokenId);
        if (_supply > 0 && usedWeight > 0) {
            uint256 useVe = IVeToken(veToken).balanceOfNFT(_tokenId);
            _adjusted = IBoost(boost).votes(_tokenId, stake).mul(useVe).div(usedWeight);
            _adjusted = (((_balance * _adjusted) / _supply) * 70) / 100;
        }
        return Math.min((_derived + _adjusted), _balance);
    }

    function depositAll() external {
        deposit(IERC20(stake).balanceOf(msg.sender));
    }

    function deposit(uint256 amount) public nonReentrant {
        require(amount > 0, "amount is 0");
        UserInfo storage user = userInfo[msg.sender];
        if (user.amount > 0) {
            uint256 pendingAmount = pendingMax(msg.sender);
            if (pendingAmount > 0) {
                _safeTokenTransfer(rewardToken, msg.sender, pendingAmount);
            }
        }
        if (amount > 0) {
            TransferHelper.safeTransferFrom(stake, msg.sender, address(this), amount);
            totalSupply += amount;
            user.amount = user.amount.add(amount);
        }
        updatePool();
        user.rewardDebt = user.amount.mul(accTokenPerShare).div(1e12);
        emit Deposit(msg.sender, amount);
    }

    function withdrawAll() external {
        withdraw(userInfo[msg.sender].amount);
    }

    function withdraw(uint256 amount) public {
        withdrawToken(amount);
    }

    function withdrawToken(uint256 _amount) public nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdrawSwap: not good");
        uint256 pendingAmount = pendingMax(msg.sender);
        if (pendingAmount > 0) {
            _safeTokenTransfer(rewardToken, msg.sender, pendingAmount);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            totalSupply = totalSupply.sub(_amount);
            TransferHelper.safeTransfer(stake, msg.sender, _amount);
        }
        updatePool();
        user.rewardDebt = user.amount.mul(accTokenPerShare).div(1e12);
        emit Withdraw(msg.sender, _amount);
    }

    function emergencyWithdraw() public nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount > 0, "amount >0");
        uint _amount = user.amount;
        user.amount = 0;
        totalSupply = totalSupply.sub(_amount);
        TransferHelper.safeTransfer(stake, msg.sender, _amount);
        user.rewardDebt = _amount.mul(accTokenPerShare).div(1e12);
        emit EmergencyWithdraw(msg.sender, _amount);
    }

    function updatePool() public {
        if (block.number <= lastRewardBlock) {
            return;
        }

        if (totalSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }
        if (tokenPerBlock <= 0) {
            return;
        }
        uint256 mul = block.number.sub(lastRewardBlock);
        uint256 tokenReward = tokenPerBlock.mul(mul);

        accTokenPerShare = accTokenPerShare.add(tokenReward.mul(1e12).div(totalSupply));
        lastRewardBlock = block.number;
    }

    // View function to see pending swap token on frontend.
    function pendingMax(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 _accTokenPerShare = accTokenPerShare;
        if (user.amount > 0) {
            if (block.number > lastRewardBlock) {
                uint256 mul = block.number.sub(lastRewardBlock);
                uint256 tokenReward = tokenPerBlock.mul(mul);
                _accTokenPerShare = _accTokenPerShare.add(tokenReward.mul(1e12).div(totalSupply));
                return user.amount.mul(_accTokenPerShare).div(1e12).sub(user.rewardDebt);
            }
            if (block.number == lastRewardBlock) {
                return user.amount.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);
            }
        }
        return 0;
    }

    function pending(address _user) public view returns (uint256) {
        uint256 amount = pendingMax(_user);
        return derivedBalance(_user, amount);
    }

    function notifyRewardAmount(address token, uint256 _rewardRate) external onlyBoost {
        require(token != stake, "no stake");
        tokenPerBlock = _rewardRate;
        if (block.number <= lastRewardBlock) {
            return;
        }
        if (totalSupply > 0) {
            uint256 mul = block.number.sub(lastRewardBlock);
            accTokenPerShare = accTokenPerShare.add(tokenPerBlock.mul(mul).mul(1e12).div(totalSupply));
            lastRewardBlock = block.number;
        }
        emit NotifyReward(msg.sender, token, _rewardRate);
    }
}
