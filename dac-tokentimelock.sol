// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract FoundersTimelock {
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 immutable private _token;

    // beneficiary of tokens after they are released
    address[4] private _founders;

    // timestamp when token release is enabled
    uint256[] private _releasesTime;

    // the index of the next release
    uint private _releaseIndex = 0;

    constructor (IERC20 token_, address[4] memory founders_, uint256[] memory releasesTime_) {
        _token = token_;
        _founders = founders_;
        _releasesTime = releasesTime_;
    }

    /**
     * @return the token being held.
     */
    function token() public view virtual returns (IERC20) {
        return _token;
    }


    /**
     * @return the time when the tokens are released.
     */
    function releasesTime() public view virtual returns (uint256[] memory) {
        return _releasesTime;
    }


    function currentReleaseTime() public view virtual returns (uint256) {
        return _releasesTime[_releaseIndex];
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public virtual {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= currentReleaseTime(), "TokenTimelock: current time is before release time");
        // ERC20 basic token contract being held
        IERC20 tokenContract = token();
        uint256 remainingAmount = tokenContract.balanceOf(address(this));
        require(remainingAmount > 0, "TokenTimelock: no tokens to release");


        // determine the amount to be transfered for the current release as the remaining locked amount divided by the number of remaining releases
        uint256 releaseAmount = remainingAmount / (_releasesTime.length - _releaseIndex);
        // the release amount is split equally between founders
        uint256 founderAmount = releaseAmount / _founders.length;
        for (uint i = 0; i < _founders.length; i++) {
            tokenContract.safeTransfer(_founders[i], founderAmount);
        }
        // increment the index in order to move to the next release
        _releaseIndex++;
    }
}
