var EquityToken = artifacts.require("./EquityTokenFactory.sol");
var EquityToken = artifacts.require("./EquityToken.sol");

contract('TestEquityToken', function(accounts) {
  it("should put 10000 ET in the first account", function() {
    return EquityToken.deployed().then(function(instance) {
      return instance.getBalance.call(accounts[0]);
    }).then(function(balance) {
      assert.equal(balance.valueOf(), 10000, "10000 wasn't in the first account");
    });
  });

  it("should call a function that depends on a linked library", function() {
    var equity;
    var equityTokenBalance;
    var equityTokenEthBalance;

    return EquityToken.deployed().then(function(instance) {
      equity = instance;
      return equity.getBalance.call(accounts[0]);
    }).then(function(outTokenBalance) {
      equityTokenBalance = outTokenBalance.toNumber();
      return equity.getBalanceInEth.call(accounts[0]);
    }).then(function(outTokenBalanceEth) {
      equityTokenEthBalance = outTokenBalanceEth.toNumber();
    }).then(function() {
      assert.equal(equityTokenEthBalance, 2 * equityTokenBalance, "Library function returned unexpected function, linkage may be broken");
    });
  });
  it("should send token correctly", function() {
    var equity;

    // Get initial balances of first and second account.
    var account_one = accounts[0];
    var account_two = accounts[1];

    var account_one_starting_balance;
    var account_two_starting_balance;
    var account_one_ending_balance;
    var account_two_ending_balance;

    var amount = 10;

    return EquityToken.deployed().then(function(instance) {
      equity = instance;
      return equity.getBalance.call(account_one);
    }).then(function(balance) {
      account_one_starting_balance = balance.toNumber();
      return equity.getBalance.call(account_two);
    }).then(function(balance) {
      account_two_starting_balance = balance.toNumber();
      return equity.sendToken(account_two, amount, {from: account_one});
    }).then(function() {
      return equity.getBalance.call(account_one);
    }).then(function(balance) {
      account_one_ending_balance = balance.toNumber();
      return equity.getBalance.call(account_two);
    }).then(function(balance) {
      account_two_ending_balance = balance.toNumber();

      assert.equal(account_one_ending_balance, account_one_starting_balance - amount, "Amount wasn't correctly taken from the sender");
      assert.equal(account_two_ending_balance, account_two_starting_balance + amount, "Amount wasn't correctly sent to the receiver");
    });
  });
});
