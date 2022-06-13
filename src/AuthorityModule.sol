// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {Authority} from "solmate/auth/Auth.sol";
import {License} from "./License.sol";

contract AuthorityModule is Authority {
  License license;

  constructor(License _license) {
    license = _license;
  }

  function canCall(
    address user,
    address target,
    bytes4 functionSig
  ) external view returns (bool) {
    License userLicense = license;
    return userLicense.hasValidLicense(user) || functionSig == bytes4(abi.encodeWithSignature("mint(uint256)"));
  }
}
