// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {Bytes32AddressLib} from "solmate/utils/Bytes32AddressLib.sol";

import {License} from "./License.sol";
import {AccessToken} from "./AccessToken.sol";
import {MasterNFT} from "./MasterNFT.sol";
import {WholeAuthorityModule} from "./WholeAuthorityModule.sol";


/// @title Combined Factory
/// @author 
/// @notice Factory which enables deploying a Vault for any ERC20 token.
contract Factory is Auth {
    using Bytes32AddressLib for address;
    using Bytes32AddressLib for bytes32;


    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a Factory.
    /// @param _owner The owner of the factory.
    /// @param _authority The Authority of the factory.
    constructor(address _owner, Authority _authority) Auth(_owner, _authority) {}

    /*///////////////////////////////////////////////////////////////
                            CONTRACT DEPLOYMENT 
    //////////////////////////////////////////////////////////////*/

    event LicenseDeployed(License license);

    event AccessTokenDeployed(AccessToken accessToken); 

    event WholeAuthorityModuleDeployed(WholeAuthorityModule wholeauthorityModule); 
    

    function deployWholeAuthorityModule(MasterNFT masterNFT) external returns (WholeAuthorityModule wholeAuthorityModule) {
      wholeAuthorityModule = new WholeAuthorityModule(address(this), masterNFT);
      emit WholeAuthorityModuleDeployed(wholeAuthorityModule);
      return (wholeAuthorityModule);
    }

    function setWholeAuthorityModuleAccessToken (WholeAuthorityModule wholeAuthorityModule, AccessToken accessToken) external {
      wholeAuthorityModule.setAccessToken(accessToken);
    }

    function setWholeAuthorityModuleLicense (WholeAuthorityModule wholeAuthorityModule, License license) external {
      wholeAuthorityModule.setLicense(license);
    }

    function deployLicense(
      string memory name,
      string memory symbol,
      string memory baseURI, 
      uint256 expiryTime, 
      uint256 maxSupply, 
      uint256 price, 
      Authority authority,
      MasterNFT masterNFT
      ) external returns (License license) {
      license = new License(name, symbol, baseURI, expiryTime, maxSupply, price, address(this), authority, masterNFT); 
      emit LicenseDeployed(license);
      return (license);
    }


    function deployAccessToken (string memory name, string memory symbol, string memory baseURI, uint256 expiryTime, uint256 maxSupply, uint256 price, Authority authority, License license, MasterNFT masterNFT) public returns (AccessToken accessToken) {
      accessToken = new AccessToken(name, symbol, baseURI, expiryTime, maxSupply, price, address(this), authority, license, masterNFT); 
      emit AccessTokenDeployed(accessToken);
      return (accessToken);
    }


    function areContractsDeployed(MasterNFT masterNFT, License license, AccessToken accessToken, WholeAuthorityModule wholeAuthorityModule) external view returns (bool) {
      return (address(masterNFT).code.length >0 ) && (address(license).code.length > 0) && (address(accessToken).code.length > 0) && (address(wholeAuthorityModule).code.length > 0);
    }
}