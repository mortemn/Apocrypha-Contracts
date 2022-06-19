// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {Authority} from "solmate/auth/Auth.sol";
import {MasterNFT} from "./MasterNFT.sol";

contract MasterNFTAuthorityModule is Authority {
  MasterNFT public masterNFT;
  address public license;
  address public owner;

  constructor(address _owner, MasterNFT _masterNFT ) {
    owner = _owner;
    masterNFT = _masterNFT;
  }

  event LicenseAddressUpdated(address newAddress);

  function getMasterNFT() public view returns (MasterNFT masterNFT) {
    return masterNFT;
  }

  function setLicenseAddress(address newAddress) public {
    require(msg.sender == owner, "NOT_OWNER");
    
    license = newAddress;
    emit LicenseAddressUpdated(license);
  }
  
  function canCall(
    address user,
    address target,
    bytes4 functionSig
  ) external view returns (bool) {
    MasterNFT masternft = masterNFT;
    
    return (user == masternft.ownerOf(0) && target == license);

  }
}
