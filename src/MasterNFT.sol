// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Owned} from "solmate/auth/Owned.sol";

contract MasterNFT is ERC721, Owned {

  string public baseURI;
  uint256 public maxSupply;
  bool public minted;
  
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

  
  function mint(address to) public onlyOwner {
    require(minted == false, "Unique Master NFT already minted!");
    _safeMint(to, 1);
    setOwner(to);
    emit OwnerUpdated(owner, to);
    minted = true;
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
  // Function to receive Ether. msg.data must be empty
  receive() external payable {}
  // Fallback function is called when msg.data is not empty
  fallback() external payable {}
  
  function getBalance() public view returns (uint) {
       return address(this).balance;
  }

  /// @notice Checks if user has any valid licenses, returns true if they have.
    /// @param user Address of user that is checked.
  function hasMasterNFT(address user)
    public
    view
    returns (bool) {
    return (user == ownerOf(1));
    
  }

  // Function to withdraw all Ether from this contract.
  function withdraw() public onlyOwner {
      // get the amount of Ether stored in this contract
      uint amount = address(this).balance;
      // send all Ether to owner
      // Owner can receive Ether since the address of owner is payable
      (bool success, ) = owner.call{value: amount}("");
      require(success, "Failed to send Ether");
  }
}