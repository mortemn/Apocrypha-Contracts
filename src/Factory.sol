// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {Bytes32AddressLib} from "solmate/utils/Bytes32AddressLib.sol";

import {License} from "./License.sol";
import {AuthorityModule} from "./AuthorityModule.sol";
import {AccessToken} from "./AccessToken.sol";

import {MasterNFT} from "./MasterNFT.sol";
import {MasterNFTAuthorityModule} from "./MasterNFTAuthorityModule.sol";




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

    event AuthorityModuleDeployed(AuthorityModule authorityModule); 

    event LicenseDeployed(License license);

    event AccessTokenDeployed(AccessToken accessToken); 

    event MasterNFTDeployed(MasterNFT masterNFT);

    event MasterNFTAuthorityModuleDeployed(MasterNFTAuthorityModule masterNFTAuthorityModule);


    function deployLicense (string memory name, string memory symbol, string memory baseURI, uint256 expiryTime, uint256 maxSupply, uint256 price, Authority authority) external returns (License license) {
      license = new License(name, symbol, baseURI, expiryTime, maxSupply, price, authority, address(this)); 
      emit LicenseDeployed(license);
      return (license);
    }

    function deployAuthorityModule (License license) external returns (AuthorityModule authorityModule) {
      authorityModule = new AuthorityModule(address(this), license);
      emit AuthorityModuleDeployed(authorityModule);
      return (authorityModule);
    }

    function deployAccessToken (string memory name, string memory symbol, string memory baseURI, uint256 expiryTime, uint256 maxSupply, uint256 price, AuthorityModule authorityModule) external returns (AccessToken accessToken) {
      accessToken = new AccessToken(name, symbol, baseURI, expiryTime, maxSupply, price, authorityModule, address(this)); 
      emit AccessTokenDeployed(accessToken);
      return (accessToken);
    }

    function deployMasterNFT (string memory name, string memory symbol, string memory baseURI) external returns (MasterNFT masterNFT) {
      masterNFT = new MasterNFT(name, symbol, baseURI);
      emit MasterNFTDeployed(masterNFT);
      return (masterNFT);
    }

    function deployMasterNFTAuthorityModule (MasterNFT masterNFT) external returns (MasterNFTAuthorityModule masterNFTAuthorityModule) {
      masterNFTAuthorityModule = new MasterNFTAuthorityModule(address(this), masterNFT);
      emit MasterNFTAuthorityModuleDeployed(masterNFTAuthorityModule);
      return (masterNFTAuthorityModule);
    }



    function areContractsDeployed(License license, AuthorityModule authorityModule, AccessToken accessToken) external view returns (bool) {
      return (address(license).code.length > 0) && (address(authorityModule).code.length > 0) && (address(accessToken).code.length > 0);
    }
}
