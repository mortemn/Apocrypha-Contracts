// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {Authority} from "solmate/auth/Auth.sol";
import {License} from "./License.sol";
import {MasterNFT} from "./MasterNFT.sol";

contract AuthorityModule is Authority {
  License public license;
  address public accessToken;
  address public owner;
  bool public tokenAddressSet;
  MasterNFT public masterNFT;

  constructor(address _owner, MasterNFT _masterNFT, License _license) {
    masterNFT = _masterNFT;
    license = _license;
    owner = _owner;
  }

  event TokenAddressUpdated(address newAddress);
  
  function setAccessTokenAddress(address newAddress) public {
    require(msg.sender == owner, "NOT_OWNER");
    require(tokenAddressSet == false);
    accessToken = newAddress;
    tokenAddressSet = true;
    emit TokenAddressUpdated(accessToken);
  }

  function getLicense() public view returns (License) {
    return license;
  }

  function userHasLicense(address _user) public view returns (bool) {
    License userLicense = license;
    bool hasValidLicense = userLicense.hasValidLicense(_user);
    return (hasValidLicense);
  }
  
  function canCall(
    address user,
    address target,
    bytes4 functionSig
  ) external view returns (bool) {
    // License userLicense = license;
    // return (userLicense.hasValidLicense(user) && functionSig == bytes4(abi.encodeWithSignature("mint(uint256)"))) && target == accessToken;    
    
      return (
        (target == accessToken) && (
                                      (
                                        masterNFT.hasMasterNFT(user) && ( functionSig == bytes4(abi.encodeWithSignature("setMaxSupply(uint256)")) || 
                                                                        functionSig == bytes4(abi.encodeWithSignature("setExpiryTime(uint256)")) ||
                                                                        functionSig == bytes4(abi.encodeWithSignature("setPrice(uint256)")))
                                      ) || (license.hasValidLicense(user) && functionSig == bytes4(abi.encodeWithSignature("mint(uint256)")))
                                    )
              );
  }
}