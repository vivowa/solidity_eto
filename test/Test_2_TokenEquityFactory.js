const EquityTokenFactory = artifacts.require("./EquityTokenFactory.sol");
const EquityToken = artifacts.require("./EquityToken.sol");

contract('TestEquityTokenFactory.js', function(accounts) {
    
    let test;

    const _name = "TestCompany";
    const _ticker = "TCO";
    const _amount = 10000;
    const _nominalvalue = 10;

    beforeEach(async function() {
      test = await EquityTokenFactory.createEquityToken(_name, _ticker, _amount, _nominalvalue);
    });

    it("should issue equity token", async function() {
      (await test._name()).should.be.equal(_name);    
    });

    // it("should safe information in array")

    it("should put equity token in the first account", function() {
        return EquityToken.deployed().then(function(instance) {
          return instance.getBalance.call(accounts[0]);
        }).then(function(balance) {
          assert.equal(balance.valueOf(), 10000, "10000 wasn't in the first account");
        });
      });
});