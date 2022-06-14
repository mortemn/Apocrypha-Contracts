// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {Authority} from "solmate/auth/Auth.sol";
import {License} from "./License.sol";

contract AuthorityModule is Authority {
  License license;
  address accessToken;
  address owner;

  constructor(address _owner, License _license) {
    license = _license;
    owner = _owner;
  }

  event TokenAddressUpdated(address newAddress);
  
  function setAccessTokenAddress(address newAddress) public {
    require(msg.sender == owner, "NOT_OWNER");
    
    accessToken = newAddress;
    emit TokenAddressUpdated(accessToken);
  }

  function canCall(
    address user,
    address target,
    bytes4 functionSig
  ) external view returns (bool) {
    License userLicense = license;
    return (userLicense.hasValidLicense(user) || functionSig == bytes4(abi.encodeWithSignature("mint(uint256)"))) && target == accessToken;
  }
}
