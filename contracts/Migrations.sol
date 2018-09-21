pragma solidity ^0.4.2;

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  constructor() public {
    owner = msg.sender;
  }
  
  // number for instantiation
  function setCompleted(uint completed) public onlyOwner {
    last_completed_migration = completed;
  }
 
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  // allows to upgrade address or owner and fires event
  function transferOwnership(address new_address) public onlyOwner {
    Migrations upgraded = Migrations(new_address);
    emit OwnershipTransferred(owner, new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}

