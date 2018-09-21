pragma solidity ^0.4.2;

contract Migrations {
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  constructor() public {
    owner = msg.sender;
  }
  
  address public owner;
  uint public last_completed_migration;

  // number for instantiation
  function setCompleted(uint completed) public onlyOwner {
    last_completed_migration = completed;
  }
 
  // allows to upgrade address or owner and fires event
  function transferOwnership(address new_address) public onlyOwner {
    Migrations upgraded = Migrations(new_address);
    emit OwnershipTransferred(owner, new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}

