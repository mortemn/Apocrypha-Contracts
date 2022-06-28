// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {Authority} from "solmate/auth/Auth.sol";
import {MasterNFT} from "./MasterNFT.sol";

contract MasterNFTAuthorityModule is Authority {
  MasterNFT public masterNFT;
  address public license;
  address public owner;
  bool public licenseAddressSet;

  constructor(address _owner, MasterNFT _masterNFT) {
    owner = _owner;
    masterNFT = _masterNFT;
  }

  event LicenseAddressUpdated(address newAddress);

  function getMasterNFT() public view returns (MasterNFT masterNFT) {
    return masterNFT;
  }

  function setLicenseAddress(address newAddress) public {
    require(msg.sender == owner, "NOT_OWNER");
    require(licenseAddressSet == false);
    license = newAddress;
    licenseAddressSet = true;
    emit LicenseAddressUpdated(license);
  }

  function userHasMasterNFT(address user) public returns (bool) { 
    return (user == masterNFT.ownerOf(1));
  }
  

  function canCall(
    address user,
    address target,
    bytes4 functionSig
  ) external view returns (bool) {
    MasterNFT masternft = masterNFT;
    
    return ((user == masternft.ownerOf(1)) && (target == license));

  }
}