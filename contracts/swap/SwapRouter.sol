// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../tools/CheckPermission.sol";
import "../tools/TransferHelper.sol";
import "../interface/IStablePool.sol";
import "../interface/curve/IZapDepositor5pool.sol";
import "../interface/curve/IZapDepositor4pool.sol";
import "../interface/ICryptoPool.sol";
import "../interface/ISwapMining.sol";

contract SwapRouter is CheckPermission {
    event ChangeSwapMining(address indexed oldSwapMining, address indexed newSwapMining);

    address public weth;

    address public swapMining;

    constructor(address _operatorMsg, address _weth) CheckPermission(_operatorMsg){
        weth = _weth;
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Router: EXPIRED");
        _;
    }

    // address(0) means no swap mining
    function setSwapMining(address addr) public onlyOperator {
        address oldSwapMining = swapMining;
        swapMining = addr;
        emit ChangeSwapMining(oldSwapMining, swapMining);
    }

    function _callStableSwapMining(
        address account,
        address pair,
        uint256 i,
        uint256 amount
    ) private {
        if (swapMining != address(0)) {
            int128 n = IStablePool(pair).n_coins();
            uint256 quantity;
            if (n == 2) {
                uint256[2] memory amounts;
                amounts[i] = amount;
                quantity = IStablePool(pair).calc_token_amount(amounts, false);
            } else if (n == 3) {
                uint256[3] memory amounts;
                amounts[i] = amount;
                quantity = IStablePool(pair).calc_token_amount(amounts, false);
            } else {
                uint256[4] memory amounts;
                amounts[i] = amount;
                quantity = IStablePool(pair).calc_token_amount(amounts, false);
            }
            ISwapMining(swapMining).swap(account, pair, quantity);
        }
    }

    function _callCryptoSwapMining(
        address account,
        address pair,
        uint256 i,
        uint256 amount
    ) private {
        if (swapMining != address(0)) {
            uint256 n = ICryptoPool(pair).n_coins();
            uint256 quantity;
            if (n == 2) {
                uint256[2] memory amounts;
                amounts[i] = amount;
                quantity = ICryptoPool(pair).calc_token_amount(amounts, false);
            } else {
                uint256[3] memory amounts;
                amounts[i] = amount;
                quantity = ICryptoPool(pair).calc_token_amount(amounts, false);
            }
            ISwapMining(swapMining).swap(account, pair, quantity);
        }
    }

    function _callCryptoTokenSwapMining(
        address account,
        address pair,
        uint256 i,
        uint256 amount
    ) private {
        if (swapMining != address(0)) {
            uint256 quantity;
            int128 n = IZapDepositor5pool(pair).n_coins();
            if (n == 2) {
                uint256[4] memory amounts;
                amounts[i] = amount;
                quantity = IZapDepositor4pool(pair).calc_token_amount(amounts, false);
                ISwapMining(swapMining).swap(account, pair, quantity);
            } else if (n == 3) {
                uint256[5] memory amounts;
                amounts[i] = amount;
                quantity = IZapDepositor5pool(pair).calc_token_amount(amounts, false);
                ISwapMining(swapMining).swap(account, pair, quantity);
            }
        }
    }


    function swapStable(
        address pool,
        uint256 from,
        uint256 to,
        uint256 fromAmount,
        uint256 minToAmount,
        address receiver,
        uint256 deadline
    ) external ensure(deadline) {
        int128 fromInt = int128(uint128(from));
        int128 toInt = int128(uint128(to));
        address fromToken = IStablePool(pool).coins(from);
        //        address toToken = IStablePool(pool).coins(to);
        if (IERC20(fromToken).allowance(address(this), pool) < fromAmount) {
            TransferHelper.safeApprove(fromToken, pool, type(uint256).max);
        }
        TransferHelper.safeTransferFrom(fromToken, msg.sender, address(this), fromAmount);
        IStablePool(pool).exchange(fromInt, toInt, fromAmount, minToAmount, receiver);
        _callStableSwapMining(receiver, pool, from, fromAmount);
    }

    function swapMeta(
        address pool,
        uint256 from,
        uint256 to,
        uint256 fromAmount,
        uint256 minToAmount,
        address receiver,
        uint256 deadline
    ) external ensure(deadline) {
        int128 fromInt = int128(uint128(from));
        int128 toInt = int128(uint128(to));
        address fromToken;
        uint256 callStable = 0;
        if (from == 0) {
            fromToken = IStablePool(pool).coins(from);
        } else {
            fromToken = IStablePool(pool).base_coins(from - 1);
            callStable = 1;
        }

        if (IERC20(fromToken).allowance(address(this), pool) < fromAmount) {
            TransferHelper.safeApprove(fromToken, pool, type(uint256).max);
        }

        TransferHelper.safeTransferFrom(fromToken, msg.sender, address(this), fromAmount);
        IStablePool(pool).exchange_underlying(fromInt, toInt, fromAmount, minToAmount, receiver);
        _callStableSwapMining(receiver, pool, callStable, fromAmount);
    }

    function swapToken(
        address pool,
        uint256 from,
        uint256 to,
        uint256 fromAmount,
        uint256 minToAmount,
        address receiver,
        uint256 deadline
    ) external ensure(deadline) {
        address fromToken = IStablePool(pool).coins(from);
        //        address toToken = IStablePool(pool).coins(to);
        if (IERC20(fromToken).allowance(address(this), pool) < fromAmount) {
            TransferHelper.safeApprove(fromToken, pool, type(uint256).max);
        }
        TransferHelper.safeTransferFrom(fromToken, msg.sender, address(this), fromAmount);
        ICryptoPool(pool).exchange(from, to, fromAmount, minToAmount, false, receiver);
        _callCryptoSwapMining(receiver, pool, from, fromAmount);
    }

    function swapToken3(
        address pool,
        uint256 from,
        uint256 to,
        uint256 fromAmount,
        uint256 minToAmount,
        address receiver,
        uint256 deadline
    ) external ensure(deadline) {
        address fromToken = ICryptoPool(pool).coins(from);
        if (IERC20(fromToken).allowance(address(this), pool) < fromAmount) {
            TransferHelper.safeApprove(fromToken, pool, type(uint256).max);
        }
        TransferHelper.safeTransferFrom(fromToken, msg.sender, address(this), fromAmount);
        ICryptoPool(pool).exchange(from, to, fromAmount, minToAmount, false);
        _callCryptoSwapMining(receiver, pool, from, fromAmount);
    }

    function swapCryptoToken(
        address pool,
        uint256 from,
        uint256 to,
        uint256 fromAmount,
        uint256 minToAmount,
        address receiver,
        uint256 deadline
    ) external ensure(deadline) {
        address fromToken = IZapDepositor5pool(pool).underlying_coins(from);
        if (IERC20(fromToken).allowance(address(this), pool) < fromAmount) {
            TransferHelper.safeApprove(fromToken, pool, type(uint256).max);
        }
        TransferHelper.safeTransferFrom(fromToken, msg.sender, address(this), fromAmount);
        IZapDepositor5pool(pool).exchange_underlying(from, to, fromAmount, minToAmount, receiver);
        _callCryptoTokenSwapMining(receiver, pool, from, fromAmount);
    }

    function swapEthForToken(
        address pool,
        uint256 from,
        uint256 to,
        uint256 fromAmount,
        uint256 minToAmount,
        address receiver,
        uint256 deadline
    ) external payable ensure(deadline) {
        uint256 bal = msg.value;
        address fromToken = IStablePool(pool).coins(from);
        if (fromToken != weth) {
            if (IERC20(fromToken).allowance(address(this), pool) < fromAmount) {
                TransferHelper.safeApprove(fromToken, pool, type(uint256).max);
            }

            TransferHelper.safeTransferFrom(fromToken, msg.sender, address(this), fromAmount);
        }

        if (fromToken == weth) {
            ICryptoPool(pool).exchange{value : bal}(from, to, fromAmount, minToAmount, true, receiver);
        } else {
            ICryptoPool(pool).exchange(from, to, fromAmount, minToAmount, true, receiver);
        }
        _callCryptoSwapMining(receiver, pool, from, fromAmount);
    }

    function swapETHStable(
        address pool,
        uint256 from,
        uint256 to,
        uint256 fromAmount,
        uint256 minToAmount,
        bool useEth,
        address receiver,
        uint256 deadline
    ) external payable ensure(deadline) {
        int128 fromInt = int128(uint128(from));
        int128 toInt = int128(uint128(to));
        address fromToken = IStablePool(pool).coins(from);
        if (!useEth) {
            if (IERC20(fromToken).allowance(address(this), pool) < fromAmount) {
                TransferHelper.safeApprove(fromToken, pool, type(uint256).max);
            }
            TransferHelper.safeTransferFrom(fromToken, msg.sender, address(this), fromAmount);
        }

        if (useEth) {
            IStablePool(pool).exchange{value : msg.value}(fromInt, toInt, fromAmount, minToAmount, true, receiver);
        } else {
            IStablePool(pool).exchange(fromInt, toInt, fromAmount, minToAmount, true, receiver);
        }

        _callStableSwapMining(receiver, pool, from, fromAmount);
    }

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOperator {
        TransferHelper.safeTransfer(_tokenAddress, owner(), _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    event Recovered(address _token, uint256 _amount);
}
