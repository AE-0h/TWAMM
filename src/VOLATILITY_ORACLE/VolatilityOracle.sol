/*

 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██    ██████  ███████ ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██      ██    ██
██      ██    ██ ██    ██ █████   ██████  ██    ██ ██    ██ █████      ██   ██ █████   ██    ██
██      ██    ██ ██    ██ ██  ██  ██   ██ ██    ██ ██    ██ ██  ██     ██   ██ ██       ██  ██
 ██████  ██████   ██████  ██   ██ ██████   ██████   ██████  ██   ██ ██ ██████  ███████   ████

Find any smart contract, and build your project faster: https://www.cookbook.dev
Twitter: https://twitter.com/cookbook_dev
Discord: https://discord.gg/WzsfPcfHrk

Find this contract on Cookbook: https://www.cookbook.dev/contracts/undefined?utm=code
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IPoolManager} from "lib/v4-periphery/lib/v4-core/contracts/interfaces/IPoolManager.sol";
import {IDynamicFeeManager} from "lib/v4-periphery/lib/v4-core/contracts/interfaces/IDynamicFeeManager.sol";
import {Hooks} from "lib/v4-periphery/lib/v4-core/contracts/libraries/Hooks.sol";
import {FeeLibrary} from "lib/v4-periphery/lib/v4-core/contracts/libraries/FeeLibrary.sol";
import {BaseHook} from "lib/v4-periphery/contracts/BaseHook.sol";
import {PoolKey} from "lib/v4-periphery/lib/v4-core/contracts/types/PoolKey.sol";

contract VolatilityOracle is BaseHook, IDynamicFeeManager {
    using FeeLibrary for uint24;

    error MustUseDynamicFee();

    uint32 deployTimestamp;

    function getFee(address, PoolKey calldata, IPoolManager.SwapParams calldata, bytes calldata)
        external
        view
        returns (uint24)
    {
        uint24 startingFee = 3000;
        uint32 lapsed = _blockTimestamp() - deployTimestamp;
        return startingFee + (uint24(lapsed) * 100) / 60; // 100 bps a minute
    }

    /// @dev For mocking
    function _blockTimestamp() internal view virtual returns (uint32) {
        return uint32(block.timestamp);
    }

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {
        deployTimestamp = _blockTimestamp();
    }

    function getHooksCalls() public pure override returns (Hooks.Calls memory) {
        return Hooks.Calls({
            beforeInitialize: true,
            afterInitialize: false,
            beforeModifyPosition: false,
            afterModifyPosition: false,
            beforeSwap: false,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false
        });
    }

    function beforeInitialize(address, PoolKey calldata key, uint160, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        if (!key.fee.isDynamicFee()) revert MustUseDynamicFee();
        return VolatilityOracle.beforeInitialize.selector;
    }
}
