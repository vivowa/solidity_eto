const EquityTokenFactory = artifacts.require("./EquityTokenFactory.sol");

contract('TestTechnicalRequirements.js', async (accounts) => {
    
    // --- Technical Test ---
    // it("should deploy the correct hierachi")
    // it("should avoid under/overflow") 
    
    it("should call a function that depends on a linked library", async () => {
    let instance = await EquityTokenFactory.deployed();
    let outTokenBalance = await (instance.getBalance.call(accounts[0]));
    let equityTokenBalance = outTokenBalance.toNumber();
    let outTokenBalanceEth = await (instance.getBalance.call(accounts[0]));
    let equityTokenEthBalance = outTokenBalanceEth.toNumber();
      assert.equal(equityTokenEthBalance, 2 * equityTokenBalance, "Library function returned unexpected function, linkage may be broken");
    });
  
  // --- EquityTokenFactory Test ---
  
    it("should issue equity token", async () => {
      let instance = await EquityTokenFactory.deployed();
    
      const _name = "TestCompany";
      const _ticker = "TCO";
      const _amount = 10000;
      const _nominalvalue = 7;

      await instance.createEquityToken(_name, _ticker, _amount, _nominalvalue, {from: accounts[0]});
      
      let balance = await instance.getBalance.call(accounts[0]);
      assert.equal(balance.valueOf(), _amount, "specified amount wasn't in the first account");
    });

    // it("should safe information in array")

    it("should put equity token in the first account", async () => {
      let instance = await EquityTokenFactory.deployed();
      let balance = await instance.getBalance.call(accounts[0]);
      assert.equal(balance.valueOf(), 10000, "10000 wasn't in the first account");
    });
     

  // --- EquityToken Test ---
    it("should send token correctly", async () => {
      let instance = await EquityTokenFactory.deployed();
    
      const account_one = accounts[0];
      const account_two = accounts[1];

      let _amount = 10;

      let balance = await instance.getBalance.call(account_one);
      let account_one_starting_balance = balance.toNumber();

      balance = await instance.getBalance.call(account_two);
      let account_two_starting_balance = balance.toNumber();
      
      await instance.sendToken(account_two, _amount, {from: account_one});

      balance = await instance.getBalance.call(account_one);
      let account_one_ending_balance = balance.toNumber();

      balance = await instance.getBalance.call(account_two);
      let account_two_ending_balance = balance.toNumber();
    
        assert.equal(account_one_ending_balance, account_one_starting_balance - _amount, "Amount wasn't correctly taken from the sender");
        assert.equal(account_two_ending_balance, account_two_starting_balance + _amount, "Amount wasn't correctly sent to the receiver");
        
    });      
})