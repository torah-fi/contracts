// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./TokenReward.sol";
import "../tools/TransferHelper.sol";
import "../interface/IVeToken.sol";

abstract contract AbstractBoost is TokenReward {
    using SafeMath for uint256;

    event Voted(address indexed voter, uint256 tokenId, int256 weight);
    event Abstained(uint256 tokenId, int256 weight);
    event ControllerAdded(address _address);
    event ControllerRemoved(address _address);

    mapping(address => bool) public controllers;

    uint256 public totalWeight; // total voting weight

    address public immutable veToken; // the ve token that governs these contracts
    address internal immutable _base;

    mapping(address => int256) public weights; // pool => weight
    mapping(uint256 => mapping(address => int256)) public votes; // nft => pool => votes
    mapping(uint256 => address[]) public poolVote; // nft => pools
    mapping(uint256 => uint256) public usedWeights; // nft => total voting weight of user

    constructor(
        address _operatorMsg,
        address __ve,
        IToken _swapToken,
        uint256 _tokenPerBlock,
        uint256 _startBlock,
        uint256 _period
    ) TokenReward(_operatorMsg, _swapToken, _tokenPerBlock, _startBlock, _period) {
        veToken = __ve;
        _base = IVeToken(__ve).token();
    }

    function getPoolVote(uint256 tokenId) public view returns (address[] memory) {
        return poolVote[tokenId];
    }

    function reset(uint256 _tokenId) external {
        require(IVeToken(veToken).isApprovedOrOwner(msg.sender, _tokenId), "no owner");
        require(usedWeights[_tokenId] > 0, "use weight > 0");
        _reset(_tokenId);
        IVeToken(veToken).abstain(_tokenId);
    }

    function _reset(uint256 _tokenId) internal {
        address[] storage _poolVote = poolVote[_tokenId];
        uint256 _poolVoteCnt = _poolVote.length;
        int256 _totalWeight = 0;

        for (uint256 i = 0; i < _poolVoteCnt; i++) {
            address _pool = _poolVote[i];
            int256 _votes = votes[_tokenId][_pool];

            if (_votes != 0) {
                _updatePoolInfo(_pool);
                weights[_pool] -= _votes;
                votes[_tokenId][_pool] -= _votes;
                if (_votes > 0) {
                    _totalWeight += _votes;
                } else {
                    _totalWeight -= _votes;
                }
                emit Abstained(_tokenId, _votes);
            }
        }
        totalWeight -= uint256(_totalWeight);
        usedWeights[_tokenId] = 0;
        delete poolVote[_tokenId];
    }

    function _vote(
        uint256 _tokenId,
        address[] memory _poolVote,
        int256[] memory _weights
    ) internal {
        _reset(_tokenId);
        uint256 _poolCnt = _poolVote.length;
        int256 _weight = int256(IVeToken(veToken).balanceOfNFT(_tokenId));
        int256 _totalVoteWeight = 0;
        int256 _totalWeight = 0;
        int256 _usedWeight = 0;

        for (uint256 i = 0; i < _poolCnt; i++) {
            _totalVoteWeight += _weights[i] > 0 ? _weights[i] : - _weights[i];
        }
        require(_totalVoteWeight > 0, "total weight is 0");

        for (uint256 i = 0; i < _poolCnt; i++) {
            address _pool = _poolVote[i];

            if (_isGaugeForPool(_pool)) {
                int256 _poolWeight = (_weights[i] * _weight) / _totalVoteWeight;
                require(votes[_tokenId][_pool] == 0, "token pool is 0");
                require(_poolWeight != 0, "weight is 0");
                _updatePoolInfo(_pool);

                poolVote[_tokenId].push(_pool);

                weights[_pool] += _poolWeight;
                votes[_tokenId][_pool] += _poolWeight;
                if (_poolWeight > 0) {} else {
                    _poolWeight = - _poolWeight;
                }
                _usedWeight += _poolWeight;
                _totalWeight += _poolWeight;
                emit Voted(msg.sender, _tokenId, _poolWeight);
            }
        }
        if (_usedWeight > 0) IVeToken(veToken).voting(_tokenId);
        totalWeight += uint256(_totalWeight);
        usedWeights[_tokenId] = uint256(_usedWeight);
    }

    function poke(uint256 _tokenId) external {
        require(IVeToken(veToken).isApprovedOrOwner(msg.sender, _tokenId), "no owner");
        require(usedWeights[_tokenId] > 0, "use weight > 0");
        address[] memory _poolVote = poolVote[_tokenId];
        uint256 _poolCnt = _poolVote.length;
        int256[] memory _weights = new int256[](_poolCnt);

        for (uint256 i = 0; i < _poolCnt; i++) {
            _weights[i] = votes[_tokenId][_poolVote[i]];
        }
        _reset(_tokenId);
        IVeToken(veToken).abstain(_tokenId);
        _vote(_tokenId, _poolVote, _weights);
    }

    function vote(
        uint256 tokenId,
        address[] calldata _poolVote,
        int256[] calldata _weights
    ) external {
        require(IVeToken(veToken).isApprovedOrOwner(msg.sender, tokenId), "no owner");
        require(_poolVote.length == _weights.length);
        _vote(tokenId, _poolVote, _weights);
    }

    function addController(address _address) external onlyOperator {
        require(_address != address(0), "0 address");
        require(controllers[_address] == false, "Address already exists");
        controllers[_address] = true;
        emit ControllerAdded(_address);
    }

    function removeController(address _address) external onlyOperator {
        require(controllers[_address] == true, "Address no exist");
        delete controllers[_address];
        emit ControllerRemoved(_address);
    }

    function _updatePoolInfo(address _pool) internal virtual;

    function _isGaugeForPool(address _pool) internal view virtual returns (bool);
}
