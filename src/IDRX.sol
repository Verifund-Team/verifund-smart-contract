// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract IDRX is ERC20 {
    uint8 private _decimals = 2;

    constructor() ERC20("Indonesia Rupiah", "IDRX") {
        _mint(msg.sender, 1_000_000 * 10 ** _decimals);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }

    function mint10k() public {
        _mint(msg.sender, 10000 * 10 ** _decimals);
    }

    function mintTo(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
