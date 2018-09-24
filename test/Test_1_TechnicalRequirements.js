const EquityTokenFactory = artifacts.require("./EquityTokenFactory.sol");
const EquityToken = artifacts.require("./EquityToken.sol");

contract('TestTechnicalRequirements.js', function(accounts) {
    // it("should deploy the correct hierachi")
    // it("should avoid under/overflow") 
    
    it("should call a function that depends on a linked library", function() {
    let test;
    let equityTokenBalance;
    let equityTokenEthBalance;

    return EquityToken.deployed().then(function(instance) {
      test = instance;
      return test.getBalance.call(accounts[0]);
    }).then(function(outTokenBalance) {
      equityTokenBalance = outTokenBalance.toNumber();
      return test.getBalanceInEth.call(accounts[0]);
    }).then(function(outTokenBalanceEth) {
      equityTokenEthBalance = outTokenBalanceEth.toNumber();
    }).then(function() {
      assert.equal(equityTokenEthBalance, 2 * equityTokenBalance, "Library function returned unexpected function, linkage may be broken");
    });
  });
});