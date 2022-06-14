// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {Bytes32AddressLib} from "solmate/utils/Bytes32AddressLib.sol";

import {License} from "./License.sol";
import {AuthorityModule} from "./AuthorityModule.sol";
import {AccessToken} from "./AccessToken.sol";


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

    AuthorityModule authorityModule;

    /*///////////////////////////////////////////////////////////////
                          VAULT DEPLOYMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new Bundle is deployed.
    /// @param license The newly deployed License contract.
    /// @param authorityModule The new authorityModule deployed (might not be necessary in the long run and can be deleted)
    // it might not be necessary because there's no Auth inside the AuthorityModule contract 
    event LicenseBundleDeployed(License license, AuthorityModule authorityModule);

    /*///////////////////////////////////////////////////////////////
                            LICENSE LOOKUP LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Computes a License's address from its accepted underlying token.
    /// @param salt Salt for deploying license.
    /// @return The address of a Vault which accepts the provided underlying token.
    /// @dev The license returned may not be deployed yet. Use isLicenseDeployed to check.
    function getLicenseFromSalt(uint256 salt) public view returns (License) {
        return
            License(
                payable(
                    keccak256(
                        abi.encodePacked(
                            // Prefix:
                            bytes1(0xFF),
                            // Creator:
                            address(this),
                            // Salt:
                            salt,
                            // Bytecode hash:
                            keccak256(
                                abi.encodePacked(
                                    // Deployment bytecode:
                                    type(License).creationCode,
                                    // Constructor arguments:
                                    abi.encode(salt)
                                )
                            )
                        )
                    ).fromLast20Bytes() // Convert the CREATE2 hash into an address.
                )
            );
    }

    function isLicenseDeployed(License license) external view returns (bool) {
      return address(license).code.length > 0;
    }


    function deployLicenseBundle (string memory name, string memory symbol, string memory baseURI, uint256 expiryTime, uint256 maxSupply, uint256 price, uint256 salt) external returns (License license, AuthorityModule) {

        // Checks what the address of license will be.
        License predictedLicense = getLicenseFromSalt(salt);

        // Deploy authority.
        authorityModule = new AuthorityModule(msg.sender, predictedLicense);

        license = new License{
          salt: bytes32(salt)
        } (name, symbol, baseURI, expiryTime, maxSupply, price, authorityModule); 

        emit LicenseBundleDeployed(license, authorityModule);

        return (license, authorityModule);
    }

    function deployAccessControl (string memory name, string memory symbol, string memory baseURI, uint256 expiryTime, uint256 maxSupply, uint256 price) external returns (AccessToken accessToken) {
      // Deploys new access token contracts.
      accessToken = new AccessToken(name, symbol, baseURI, expiryTime, maxSupply, price, authorityModule);
    }

    function isAccessTokenDeployed(AccessToken accessToken) external view returns (bool) {
      return address(accessToken).code.length > 0;
    }
}
