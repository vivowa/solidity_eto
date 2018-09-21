pragma solidity ^0.4.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/EquityToken.sol";

contract TestEquityToken {

  function testInitialBalanceUsingDeployedContract() public {
    EquityToken token = EquityToken(DeployedAddresses.EquityToken());

    uint expected = 10000;

    Assert.equal(token.getBalance(tx.origin), expected, "Owner should have 10000 EquityToken initially");
  }

  function testInitialBalanceWithNewEquityToken() public {
    EquityToken token = new EquityToken();

    uint expected = 10000;

    Assert.equal(token.getBalance(tx.origin), expected, "Owner should have 10000 EquityToken initially");
  }

}
