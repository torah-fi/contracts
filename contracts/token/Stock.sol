// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../tools/AbstractPausable.sol";

contract Stock is ERC20Burnable, AbstractPausable {
    using SafeMath for uint256;

    uint256 public constant GENESIS_SUPPLY = 35e7 * 1e18;
    uint256 public constant MAX_SUPPLY = 1e9 * 1e18;

    address[] public poolAddress;
    mapping(address => bool) public isPools;

    modifier onlyPools() {
        require(isPools[msg.sender] == true, "Only pools can call this function");
        _;
    }

    constructor(
        address _operatorMsg,
        string memory _name,
        string memory _symbol
    ) public ERC20(_name, _symbol) AbstractPausable(_operatorMsg) {
        _mint(msg.sender, GENESIS_SUPPLY);
    }

    function poolAddressCount() public view returns (uint256) {
        return (poolAddress.length);
    }

    function addPool(address _pool) public onlyOperator {
        require(_pool != address(0), "0 address");
        require(isPools[_pool] == false, "Address already exists");
        isPools[_pool] = true;
        poolAddress.push(_pool);

        emit PoolAdded(_pool);
    }

    // Remove a pool
    function removePool(address _pool) public onlyOperator {
        require(_pool != address(0), "0 address");
        require(isPools[_pool] == true, "Address nonexistant");

        // Delete from the mapping
        delete isPools[_pool];

        // 'Delete' from the array by setting the address to 0x0
        for (uint256 i = 0; i < poolAddress.length; i++) {
            if (poolAddress[i] == _pool) {
                poolAddress[i] = address(0);
                // This will leave a null in the array and keep the indices the same
                break;
            }
        }
        emit PoolRemoved(_pool);
    }

    function mint(address to, uint256 amount) public onlyPools returns (bool) {
        if (amount.add(totalSupply()) > MAX_SUPPLY) {
            return false;
        }
        _mint(to, amount);
        return true;
    }

    function poolMint(address to, uint256 amount) external onlyPools {
        if (amount.add(totalSupply()) > MAX_SUPPLY) {
            return;
        }
        super._mint(to, amount);
        emit StockMinted(address(this), to, amount);
    }

    function poolBurnFrom(address _address, uint256 _amount) external onlyPools {
        super.burnFrom(_address, _amount);
        emit StockBurned(_address, address(this), _amount);
    }

    event StockBurned(address indexed from, address indexed to, uint256 amount);
    event StockMinted(address indexed from, address indexed to, uint256 amount);
    event PoolAdded(address pool);

    event PoolRemoved(address pool);
}
