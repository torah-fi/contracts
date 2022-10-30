// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interface/IDistribute.sol";

import "../tools/CheckPermission.sol";
import "../interface/IVeToken.sol";

abstract contract AbstractController is CheckPermission {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    event Voted(address indexed voter, uint256 tokenId, uint256 weight);
    event Abstained(uint256 tokenId, uint256 weight);

    struct PoolVote {
        address pool;
        uint256 lastUse;
    }

    address public immutable veToken; // the ve token that governs these contracts
    address public immutable base;
    address public immutable distribute;

    uint256 public duration;
    uint256 public totalWeight; // total voting weight
    uint256 public lastUpdate;

    mapping(address => uint256) public weights; // pool => weight
    mapping(uint256 => uint256) public usedWeights; // nft => total voting weight of user
    mapping(uint256 => PoolVote) public userPool; // nft => pool voting weight of user

    EnumerableSet.AddressSet private _poolInfo;

    constructor(
        address _operatorMsg,
        address _boost,
        address __ve,
        uint256 _duration
    ) CheckPermission(_operatorMsg) {
        veToken = __ve;
        base = IVeToken(__ve).token();
        distribute = _boost;
        duration = _duration;
    }

    function setDuration(uint256 _duration) external onlyOperator {
        duration = _duration;
    }

    function reset(uint256 _tokenId) external {
        require(IVeToken(veToken).isApprovedOrOwner(msg.sender, _tokenId), "no owner");
        require(usedWeights[_tokenId] > 0, "use weight > 0");
        PoolVote storage poolVote = userPool[_tokenId];
        require(poolVote.lastUse + duration < block.timestamp, "next duration use");
        _reset(_tokenId);
        IVeToken(veToken).abstain(_tokenId);
        poolVote.lastUse = block.timestamp;
        updatePool();
    }

    function _reset(uint256 _tokenId) internal {
        uint256 _totalWeight = usedWeights[_tokenId];
        weights[userPool[_tokenId].pool] -= _totalWeight;
        totalWeight -= _totalWeight;
        usedWeights[_tokenId] = 0;
        delete userPool[_tokenId];
        emit Abstained(_tokenId, _totalWeight);
    }

    function _vote(uint256 _tokenId, address _poolVote) internal {
        _reset(_tokenId);
        uint256 _weight = IVeToken(veToken).balanceOfNFT(_tokenId);
        weights[_poolVote] = weights[_poolVote].add(_weight);
        IVeToken(veToken).voting(_tokenId);
        totalWeight += _weight;
        usedWeights[_tokenId] = _weight;
        updatePool();
        emit Voted(msg.sender, _tokenId, _weight);
    }

    function poke(uint256 _tokenId) external {
        require(IVeToken(veToken).isApprovedOrOwner(msg.sender, _tokenId), "no owner");
        require(usedWeights[_tokenId] > 0, "use weight > 0");
        PoolVote storage poolVote = userPool[_tokenId];
        _reset(_tokenId);
        IVeToken(veToken).abstain(_tokenId);
        _vote(_tokenId, poolVote.pool);
    }

    function vote(uint256 tokenId, address _poolVote) external {
        require(IVeToken(veToken).isApprovedOrOwner(msg.sender, tokenId), "no owner");
        require(IVeToken(veToken).balanceOfNFT(tokenId) > 0, "ve token >0");
        PoolVote storage poolVote = userPool[tokenId];
        require(poolVote.lastUse + duration < block.timestamp, "next duration use");
        require(isPool(_poolVote), "must pool");
        _vote(tokenId, _poolVote);
        poolVote.pool = _poolVote;
        poolVote.lastUse = block.timestamp;
    }

    function updatePool() public {
        if (block.timestamp < lastUpdate.add(duration)) {
            return;
        }
        for (uint256 pid = 0; pid < getPoolLength(); ++pid) {
            address pool = EnumerableSet.at(_poolInfo, pid);
            uint256 _id = IDistribute(distribute).lpOfPid(pool);
            IDistribute(distribute).set(_id, weights[pool], false);
        }
        IDistribute(distribute).massUpdatePools();
        lastUpdate = block.timestamp;
    }

    function addPool(address _address) external onlyOperator {
        require(_address != address(0), "0 address");
        EnumerableSet.add(_poolInfo, _address);
    }

    function removePool(address _address) external onlyOperator {
        EnumerableSet.remove(_poolInfo, _address);
    }

    function getUserInfo(uint256 tokenId) public view returns (address, uint256) {
        PoolVote memory poolVote = userPool[tokenId];
        return (poolVote.pool, poolVote.lastUse);
    }

    function getPoolLength() public view returns (uint256) {
        return EnumerableSet.length(_poolInfo);
    }

    function isPool(address _pool) public view returns (bool) {
        return EnumerableSet.contains(_poolInfo, _pool);
    }

    function getPool(uint256 _index) public view returns (address) {
        require(_index <= getPoolLength() - 1, ": index out of bounds");
        return EnumerableSet.at(_poolInfo, _index);
    }
}
