const EquityTokenFactory = artifacts.require("./EquityTokenFactory.sol");

contract('TestTechnicalRequirements.js', async (accounts) => {
    
    // --- Technical Test ---   
   describe("technical prerequirements", async () => {

    it("should call a function that depends on a linked library", async () => {
    let instance = await EquityTokenFactory.deployed();
    let outTokenBalance = await (instance.getBalance.call(accounts[0]));
    let equityTokenBalance = outTokenBalance.toNumber();
    let outTokenBalanceEth = await (instance.getBalance.call(accounts[0]));
    let equityTokenEthBalance = outTokenBalanceEth.toNumber();
      assert.equal(equityTokenEthBalance, 2 * equityTokenBalance, "Library function returned unexpected function, linkage may be broken");
    });

    // it("should deploy the correct hierachi")
    // it("should avoid under/overflow") 
  });
  
  // --- EquityTokenFactory Test ---
    describe("correct token issuance", async () => {
      const _name = "TestCompany";
      const _ticker = "TCO";
      const _amount = 10000;
      const _nominalvalue = 7;
      const _indexEquityTokenInArray = 0;

    it("should have a name", async () => {
      let instance = await EquityTokenFactory.deployed(); 

      await instance.createEquityToken(_name, _ticker, _amount, _nominalvalue, {from: accounts[0]});
      let information = await instance.getInfosEquityToken(_indexEquityTokenInArray, {from: accounts[0]});

      assert.equal(information[1], _name,"company name missing");
    });
   
    it("should have a ticker", async () => {
      let instance = await EquityTokenFactory.deployed(); 

      await instance.createEquityToken(_name, _ticker, _amount, _nominalvalue, {from: accounts[0]});
      let information = await instance.getInfosEquityToken(_indexEquityTokenInArray, {from: accounts[0]});

      assert.equal(information[2], _ticker,"ticker missing");
    });

    it("should put issuing amount in the first account", async () => {
      let instance = await EquityTokenFactory.deployed();
      let balance = await instance.getBalance.call(accounts[0]);
      assert.equal(balance.valueOf(), _amount, "specific amount wasn't in the first account");
    });
    // it("should safe information in array")
  });

  // --- EquityToken Test ---
  describe("corrent token transactions", async ()=> {
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
  });     
})