// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

/// @notice ERC2981 implementation.
/// Special thanks and help from https://github.com/dievardump/EIP2981-implementation.

abstract contract ERC2981 {

    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    mapping(uint256 => RoyaltyInfo) internal _royalties;


    /*//////////////////////////////////////////////////////////////
                              ERC2981 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Sets token royalties.
    /// @param TokenId the token id for which we register the royalties.
    /// @param Recipient recipient of the royalties.
    /// @param Value percentage (using 2 decimals - 10000 = 100, 0 = 0).
    function _setTokenRoyalty(
      uint256 tokenId,
      address recipient,
      uint256 value
    ) internal {
      require(value <= 10000, "TOO_HIGH");
      _royalties[tokenId] = RoyaltyInfo(recipient, uint24(value));
    }

    /// @dev Gets royalty info of token.
    /// @param tokenId Id of token.
    /// @param value Intended value of the token.
    function royaltyInfo(uint256 tokenId, uint256 value)
      external
      view
      returns (address receiver, uint256 royaltyAmount) 
    {
      RoyaltyInfo memory royalties = _royalties[tokenId];
      receiver = royalties.recipient;
      royaltyAmount = (value * royalties.amount) / 10000;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x2a55205a; // ERC165 Interface ID for ERC2981
    }
          
}
