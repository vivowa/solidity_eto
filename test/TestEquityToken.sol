pragma solidity ^0.4.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/EquityTokenFactory.sol";
import "../contracts/EquityToken.sol";

contract TestEquityToken {

/*
  function testInitialBalanceUsingDeployedContract() public {
    EquityToken token = EquityTokenFactory(DeployedAddresses.EquityTokenFactory());

    uint expected = 10000;

    Assert.equal(token.getBalance(msg.sender), expected, "Owner should have 10000 EquityToken initially");
  }

  // for security reason msg.sender, but without tx.origin owner does not receive 10k in constructor of Coin
  function testInitialBalanceWithNewEquityToken() public {
    EquityToken token = new EquityTokenFactory();

    uint expected = 10000;

    Assert.equal(token.getBalance(msg.sender), expected, "Owner should have 10000 EquityToken initially");
  }
  */

}