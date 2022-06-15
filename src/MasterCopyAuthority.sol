// SPDX-License-Identifier: AGPL-3.0-only


pragma solidity 0.8.11;

import {Authority} from "solmate/auth/Auth.sol";
import {License} from "./License.sol";

contract MasterCopyAuthority is Authority {

  address immutable masterCopyOwner;

  constructor(address _masterCopyOwner) {
    masterCopyOwner = _masterCopyOwner;
  }
  // constructor(bool _allowCalls) {
  //   allowCalls = _allowCalls;
  // }

  function canCall(
    address user,
    address target,
    bytes4 functionSig
  ) public view override returns (bool) {
    
    return (user == masterCopyOwner ? true : false);
    
  }
}




contract MockAuthority is Authority {
    bool immutable allowCalls;

    constructor(bool _allowCalls) {
        allowCalls = _allowCalls;
    }

    function canCall(
        address,
        address,
        bytes4
    ) public view override returns (bool) {
        return allowCalls;
    }
}
