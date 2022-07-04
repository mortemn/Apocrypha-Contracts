// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {Authority} from "solmate/auth/Auth.sol";
import {License} from "./License.sol";
import {MasterNFT} from "./MasterNFT.sol";
import {AccessToken} from "./AccessToken.sol";

contract WholeAuthorityModule is Authority {
  MasterNFT public masterNFT;
  License public license;
  AccessToken public accessToken;
  
  address public owner;
  bool public tokenAddressSet;
  bool public licenseAddressSet;
  

  constructor(address _owner, MasterNFT _masterNFT) {
    owner = _owner;
    masterNFT = _masterNFT;
    // license = _license;
    
  }
  event LicenseAddressUpdated(License license);
  event TokenAddressUpdated(AccessToken accessToken);
  
  function setLicense(License _license) public {
    require(msg.sender == owner, "NOT_OWNER");
    require(licenseAddressSet == false);
    license = _license;
    licenseAddressSet = true;
    emit LicenseAddressUpdated(license);
  }

  function setAccessToken(AccessToken _accessToken) public {
    require(msg.sender == owner, "NOT_OWNER");
    require(tokenAddressSet == false);
    accessToken = _accessToken;
    tokenAddressSet = true;
    emit TokenAddressUpdated(accessToken);
  }

  function getMasterNFT() public view returns (MasterNFT masterNFT) {
    return masterNFT;
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

    
    if (target == address(accessToken)) {
        return (
                (
                  masterNFT.hasMasterNFT(user) && ( functionSig == bytes4(abi.encodeWithSignature("setMaxSupply(uint256)")) || 
                                                  functionSig == bytes4(abi.encodeWithSignature("setExpiryTime(uint256)")) ||
                                                  functionSig == bytes4(abi.encodeWithSignature("setPrice(uint256)")))
                ) 
                || (user == address(license) && functionSig == bytes4(abi.encodeWithSignature("mint(uint256, address)"))) 
                || (user == address(license) && functionSig == bytes4(abi.encodeWithSignature("buy(uint256, address)")))
        );
    } else {
        return ((user == masterNFT.ownerOf(1)) && (target == address(license)));
    }

     
  }
}