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
    function getLicenseFromSalt(uint256 salt) public returns (License) {
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


    // / @notice Deploys a new Vault which supports a specific underlying token.
    // / @dev This will revert if a Vault that accepts the same underlying token has already been deployed.
    // / @param underlying The ERC20 token that the Vault should accept.
    // / @return vault The newly deployed Vault contract which accepts the provided underlying token.
    function deployLicenseBundle (string memory name, string memory symbol, string memory baseURI, uint256 expiryTime, uint256 maxSupply, uint256 price, uint256 salt) external returns (License license, AuthorityModule authorityModule) {

        // Checks what the address of license will be.
        License predictedLicense = getLicenseFromSalt(salt);

        // Deploy authority.
        authorityModule = new AuthorityModule(predictedLicense);

        license = new License{
          salt: bytes32(salt)
        } (name, symbol, baseURI, expiryTime, maxSupply, price, authorityModule); 

        emit LicenseBundleDeployed(license, authorityModule);

        return (license, authorityModule);
    }

    // / @notice Returns if a Vault at an address has already been deployed.
    // / @param vault The address of a Vault which may not have been deployed yet.
    // / @return A boolean indicating whether the Vault has been deployed already.
    // / @dev This function is useful to check the return values of getVaultFromUnderlying,
    /// as it does not check that the Vault addresses it computes have been deployed yet.
    function isBundleDeployed(License license, AuthorityModule authorityModule, AccessToken accessToken) external view returns (bool) {
        return address(license).code.length > 0 && address(authorityModule).code.length > 0 && address(accessToken).code.length > 0;
    }
}
