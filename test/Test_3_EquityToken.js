const EquityToken = artifacts.require("./EquityToken.sol");
const TokenBusinessLayer = artifacts.require("./TokenBusinessLayer.sol");
const TokenLevelGovernance = artifacts.require("./TokenLevelGovernance.sol");
const TokenProcessingLayer = artifacts.require("./TokenProcessingLayer.sol");

contract('TestEquityToken.js', function(accounts) {
    
  it("should send token correctly", function() {
    let equity;

    // Get initial balances of first and second account.
    const account_one = accounts[0];
    const account_two = accounts[1];

    let account_one_starting_balance;
    let account_two_starting_balance;
    let account_one_ending_balance;
    let account_two_ending_balance;

    const amount = 1;

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
