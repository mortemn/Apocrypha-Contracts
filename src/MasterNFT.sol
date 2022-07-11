// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {ERC2981} from "./ERC2981.sol";
import {Owned} from "solmate/auth/Owned.sol";

contract MasterNFT is ERC721, ERC2981, Owned {

  string public baseURI;
  uint256 public maxSupply;
  bool public minted;

  event Log(string func, address sender, uint256 value, bytes data);
  
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

  
  function mint(address to, address royaltyRecipient, uint256 royaltyValue) public onlyOwner {
    require(minted == false, "ALREADY_MINTED");

    minted = true;
    setOwner(to);

    if (royaltyValue > 0) {
      _setTokenRoyalty(1, royaltyRecipient, royaltyValue);
    }

    _safeMint(to, 1);

    emit OwnerUpdated(owner, to);
  }

  function transferFrom(address from, address to, uint256 id) public virtual override {
    require(from == _ownerOf[id], "WRONG_FROM");

    require(to != address(0), "INVALID_RECIPIENT");

    require(
        msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
        "NOT_AUTHORIZED"
    );

    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    unchecked {
        _balanceOf[from]--;
        _balanceOf[to]++;
    }

    _ownerOf[id] = to;

    delete getApproved[id];

    setOwner(to);

    emit Transfer(from, to, id);
    emit OwnerUpdated(owner, to);
  }

  // Function to withdraw all Ether from this contract.
  function withdraw(uint256 amount) public onlyOwner {
      require(amount <= address(this).balance, "AMOUNT_EXCEEDED");

      // send all Ether to owner
      // Owner can receive Ether since the address of owner is payable
      (bool success, ) = owner.call{value: amount}("");
      require(success, "SEND_FAILED");
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

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  fallback() external payable {
    emit Log("fallback", msg.sender, msg.value, msg.data);
  }
  receive() external payable {
    emit Log("receive", msg.sender, msg.value, ""); 
  }
}
