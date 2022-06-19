// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Owned} from "solmate/auth/Owned.sol";

contract MasterNFT is ERC721, Owned {

  string public baseURI;
  uint256 public maxSupply = 1;
  
  uint256 public minted;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _baseURI
  ) ERC721 (
    _name,
    _symbol
  ) Owned (msg.sender) {
    baseURI = _baseURI;
  }

  function mint(address to) external {
    require(minted == 0, "you've already minted 1 masterNFT, and there could be only one.");
    _safeMint(to, minted);
    minted = 1;
  }

  function tokenURI(uint256 tokenId)
      public
      view
      override
      returns (string memory)
  {
      require(ownerOf(tokenId) != address(0), "TOKEN_DOES_NOT_EXIST");

      return
          bytes(baseURI).length > 0
              ? string(abi.encodePacked(baseURI, string(abi.encodePacked(tokenId)), ".json"))
              : "";
  }

}
