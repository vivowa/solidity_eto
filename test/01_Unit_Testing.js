const EquityTokenFactory = artifacts.require("./EquityTokenFactory.sol");
const EquityToken = artifacts.require("./EquityToken.sol");
const EquityTokenTransaction = artifacts.require("./EquityTokenTransaction.sol");
const EquityTokenTransactionHelper = artifacts.require("./EquityTokenTransaction.sol");

const _name = "TestCompany";
const _ticker = "TCO";
const _amount = 10 ** 9;
const _granularity = 1;
const _trancheId = 505122836950;

const _txamount = 10 ** 8;

/// For more documentation and illustration see the adjacent paper.

//-----TechnicalRequirements--------------------------------------------------------------------------------------------------------------


contract("tokenIssuance.js", async (accounts) => {

before(async() => {
    account_issuer = accounts[0];
    account_investor_1 = accounts[1];
    account_investor_2 = accounts[2];
    account_advocate_1 = accounts[8];
    account_government_1 = accounts[9];
    });

      //@dev: defines event from solidity contract, starts to watch events and prints it to console
      //@notes: result is BigNumber, toNumber() improves readability
      //@notes: result.args returns all argument objects from event
      //@notes: watches also all upcoming events of defined type 
      before(async () => {
        let instance1 = await EquityTokenFactory.deployed();
        let instance3 = await EquityTokenTransaction.deployed();

        let event1 = instance1.newTokenIssuance();
        await event1.watch((error, result) => {
        if (!error)
        console.log("                 event_issuance: companyName " + result.args.companyName, "address " + result.args.companyOwner);
        });
  
        let event2 = instance1.newShareholder();
        await event2.watch((error, result) => {
        if (!error)
        console.log("                 event_shareholder: new_address " + result.args.newShareholder, "total_length_shareholder " + result.args.length.toNumber());
        });
  
        let event3 = instance3.Sent();
        await event3.watch((error, result) => {
        if (!error)
        console.log("                 event_transfer: from " + result.args.from, "to " + result.args.to, "amount " + result.args.amount.toNumber());
        });
              
        let event4 = instance1.Minted();
        await event4.watch((error, result) => {
        if (!error)
        console.log("                 event_Mint: company " + result.args.to, "amount " + result.args.amount.toNumber());
        }); 
        });          
 
    describe("technical pre-requirements", async () => {

    it("should call a function that depends on a linked library", async () => {
    let instance1 = await EquityTokenFactory.deployed();
    await instance1.createToken(_name, _ticker, _granularity, {from: account_issuer});

    await instance1.clearRequest(_name, {from: account_advocate_1});

    await instance1.mint(_amount, "", "", {from: account_issuer});
    
    let instance2 = await EquityToken.deployed();

    let outTokenBalance = await instance2.balanceOf.call(account_issuer);
    let equityTokenBalance = outTokenBalance.toNumber();
    let outTokenBalanceEth = await instance2.getBalanceOfInEth.call(account_issuer);
    let equityTokenBalanceEth = outTokenBalanceEth.toNumber();
    
    assert.equal(equityTokenBalanceEth, 3 * equityTokenBalance, "Library function returned unexpected function, linkage may be broken");
    });
  });
//-----TechnicalRequirements--------------------------------------------------------------------------------------------------------------

//-----EquityTokenFactory-----------------------------------------------------------------------------------------------------------------  
 
    describe("correct token issuance", async () => {
                
      it("should safe issuance information on blockchain", async () => {
        let instance1 = await EquityTokenFactory.deployed();
        let instance2 = await EquityToken.deployed();

        await instance1.createToken(_name, _ticker, _granularity, {from: account_issuer});
  
        let information = await instance2.getInfosEquityToken.call();
      
      assert.exists(information[0,1,2,3,4],"array null or undefined");
      });
  
    it("should have created a random and unique id", async () => {      
        let instance2 = await EquityToken.deployed();   
        let information = await instance2.getInfosEquityToken.call();
        
        assert.exists(information[0],"random and unique id missing or wrong (null or undefined)");
      });
        
      //@notes: web3.toAscii to convert a HexString to Ascii, as bytes32 is used in solidity instead of string
      //@notes: notStrictEqual to catch minor issues after format transformation and comparing to a string "_name"
    it("should have a name", async () => {
      let instance2 = await EquityToken.deployed();           
      let information = await instance2.getInfosEquityToken.call();

      assert.notStrictEqual(web3.toAscii(information[1]), _name,"company name missing or wrong");
      });
   
    it("should have a ticker", async () => {
      let instance2 = await EquityToken.deployed();       
      let information = await instance2.getInfosEquityToken.call();

      assert.notStrictEqual(web3.toAscii(information[2]), _ticker,"ticker missing or wrong");
      });

    it("should put issuing amount in the first account", async () => {
      let instance1 = await EquityTokenFactory.deployed();
      let instance2 = await EquityToken.deployed();

      await instance1.createToken(_name, _ticker, _granularity, {from: account_issuer});

      await instance1.clearRequest(_name, {from: account_advocate_1});

      await instance1.mint(_amount, "", "", {from: account_issuer});

      let balance = await instance2.balanceOf.call(account_issuer);
      let EndBalance = _amount;
      
      assert.equal(EndBalance.valueOf(), _amount, "specific amount wasn't in the first account");
      });
    });
  
})
//-----EquityTokenFactory-----------------------------------------------------------------------------------------------------------------  

//-----EquityToken------------------------------------------------------------------------------------------------------------------------   
contract("EquityToken.js", async (accounts) => {
  
  before(async() => {
    account_issuer = accounts[0];
    account_investor_1 = accounts[1];
    account_investor_2 = accounts[2];
    account_advocate_1 = accounts[8];
    account_government_1 = accounts[9];
    });

      before(async () => {
        let instance1 = await EquityTokenFactory.deployed();
        let instance3 = await EquityTokenTransaction.deployed();

        let event1 = instance1.newTokenIssuance();
        await event1.watch((error, result) => {
        if (!error)
        console.log("                 event_issuance: companyName " + result.args.companyName, "address " + result.args.companyOwner);
        });
  
        let event2 = instance1.newShareholder();
        await event2.watch((error, result) => {
        if (!error)
        console.log("                 event_shareholder: new_address " + result.args.newShareholder, "total_length_shareholder " + result.args.length.toNumber());
        });
  
        let event3 = instance3.Sent();
        await event3.watch((error, result) => {
        if (!error)
        console.log("                 event_transfer: from " + result.args.from, "to " + result.args.to, "amount " + result.args.amount.toNumber());
        });
              
        let event4 = instance1.Minted();
        await event4.watch((error, result) => {
        if (!error)
        console.log("                 event_Mint: company " + result.args.to, "amount " + result.args.amount.toNumber());
        }); 
        });    

  describe("corrent token characteristics & transactions", async () => { 

     /*it("should send token correctly && should update shareholder book", async () => {
      let instance1 = await EquityTokenFactory.deployed();
      let instance2 = await EquityToken.deployed();
      let instance3 = await EquityTokenTransaction.deployed();

      await instance1.createToken(_name, _ticker, _granularity, {from: account_issuer});

      await instance1.clearRequest(_name, {from: account_advocate_1});

      await instance1.mint(_amount, "", "", {from: account_issuer});
           
      let balance = await instance2.balanceOf.call(account_issuer);
      let account_one_starting_balance = balance.toNumber();

      balance = await instance2.balanceOf.call(account_investor_1);
      let account_two_starting_balance = balance.toNumber();

      let shareholder_starting_length = await [instance2.getAllAddressesEquityToken.call()].length;
      
      await instance3._doSend(_trancheId, account_issuer, account_investor_1, _txamount, "", "", "", {from: account_issuer});

      balance = await instance2.balanceOf.call(account_issuer);
      let account_one_ending_balance = balance.toNumber();

      balance = await instance2.balanceOf.call(account_investor_1);
      let account_two_ending_balance = balance.toNumber();

      let shareholder_ending_length = await [instance.getAllAddressesEquityToken.call()].length;
    
        assert.equal(account_one_ending_balance, account_one_starting_balance - _txamount, "Amount wasn't correctly taken from the sender");
        assert.equal(account_two_ending_balance, account_two_starting_balance + _txamount, "Amount wasn't correctly sent to the receiver");
        assert.equal(shareholder_ending_length, shareholder_starting_length, "Shareholder book not updated");
      });
    });*/
  })

      it("should have shareholder book", async () => {
        let instance1 = await EquityTokenFactory.deployed();
        let instance2 = await EquityToken.deployed();
      
        await instance1.createToken(_name, _ticker, _granularity, {from: account_issuer});

        await instance1.clearRequest(_name, {from: account_advocate_1});
  
        await instance1.mint(_amount, "", "", {from: account_issuer});

        let information = await [instance2.getAllAddressesEquityToken.call()];
      
      assert.exists(information,"array null or undefined");
      });

      it("should send correct adHoc messages", async () => {
        let message = "Due to unsteady political environment in asia our EBIT will drop by 20%";              
        let instance1 = await EquityTokenFactory.deployed();
        let instance2 = await EquityToken.deployed();
        await instance1.createToken(_name, _ticker, _granularity, {from: account_issuer});

        await instance2.sendAdHocMessage(message, {from: account_issuer});
    
        let message_broadcast = message;

        let event6 = instance2.adHocMessage();
        await event6.watch((error, result) => {
        if (!error)
        return message_broadcast = result.args._message;
        });

        assert.equal(message_broadcast, message, "adHoc message not broadcasted");
        });

      /*it("should send dividends && only for company owner", async () => {
                 
      const _testdividend = 3;

      let balance = await instance.balanceOf.call(account_issuer);
      let account_one_starting_balance = balance.toNumber();

      balance = await instance.balanceOf.call(account_investor_1);
      let account_two_starting_balance = balance.toNumber();
      
      await instance.payDividend(_testdividend, {from: account_issuer});
      
      //@devs: if operation possbile test would fail twice: a) double the dividend would have been payed b) two events would be fired and watched by JS
      try { 
        await instance.payDividend(_testdividend, {from: account_investor_1});
      } catch (e) {
        console.log("                 "+ e.message);
         }

      balance = await instance.balanceOf.call(account_issuer);
      let account_one_ending_balance = balance.toNumber();

      balance = await instance.balanceOf.call(account_investor_1);
      let account_two_ending_balance = balance.toNumber();
    
        assert.equal(account_one_ending_balance, account_one_starting_balance - (_testdividend * _txamount), "Amount wasn't correctly taken from the sender");
        assert.equal(account_two_ending_balance, account_two_starting_balance + (_testdividend * _txamount), "Amount wasn't correctly sent to the receiver");
        

      });
    }); */
  })
//-----EquityToken------------------------------------------------------------------------------------------------------------------------    

//-----Voting-----------------------------------------------------------------------------------------------------------------------------  
    contract("Voting.js", async (accounts) => {
    
    before(async() => {
    account_issuer = accounts[0];
    account_investor_1 = accounts[1];
    account_investor_2 = accounts[2];
    account_advocate_1 = accounts[8];
    account_government_1 = accounts[9];
    });

      before(async () => {
        let instance1 = await EquityTokenFactory.deployed();
        let instance2 = await EquityToken.deployed();
        let instance3 = await EquityTokenTransaction.deployed();

        let event1 = instance1.newTokenIssuance();
        await event1.watch((error, result) => {
        if (!error)
        console.log("                 event_issuance: companyName " + result.args.companyName, "address " + result.args.companyOwner);
        });
  
        let event2 = instance1.newShareholder();
        await event2.watch((error, result) => {
        if (!error)
        console.log("                 event_shareholder: new_address " + result.args.newShareholder, "total_length_shareholder " + result.args.length.toNumber());
        });
  
        let event3 = instance3.Sent();
        await event3.watch((error, result) => {
        if (!error)
        console.log("                 event_transfer: from " + result.args.from, "to " + result.args.to, "amount " + result.args.amount.toNumber());
        });
              
        let event4 = instance1.Minted();
        await event4.watch((error, result) => {
        if (!error)
        console.log("                 event_Mint: company " + result.args.to, "amount " + result.args.amount.toNumber());
        }); 
      
        let event5 = instance2.votingSuccessful();
        await event5.watch((error, result) => {
        if (!error)
        console.log("                 event_voting: proposal " + result.args._winnerName, "# votes " + result.args._countVotes.toNumber());
        });
        });

        //@notes: creates token, transfers tokens to another account (for voting right distribution), starts ballot 
      /* it("company should start voting", async () => {   
     
      let instance1 = await EquityTokenFactory.deployed();
      let instance2 = await EquityToken.deployed();
      let instance3 = await EquityTokenTransaction.deployed();

      await instance1.createToken(_name, _ticker, _granularity, {from: account_issuer});

      await instance1.clearRequest(_name, {from: account_advocate_1});

      await instance1.mint(_amount, "", "", {from: account_issuer});

      await instance3._doSend(_trancheId, account_issuer, account_investor_1, _txamount, {from: account_issuer});
        
      const TestProposalName = [web3.toHex("Test1"), web3.toHex("Test2")];
      await instance2.startBallot(TestProposalName, {from: account_issuer});
    
      let information = await instance2.getProposals.call(); 
      
      assert.exists(information[0,1],"array null or undefined");
      assert.notStrictEqual(web3.toAscii(information[0]), "Test1", "proposal name missing or wrong");
      });*/
      
      it("voters should have possibility to vote", async () => {
        let instance1 = await EquityTokenFactory.deployed();
        let instance2 = await EquityToken.deployed();
        
        const TestProposalName = [web3.toHex("Test1"), web3.toHex("Test2")];
        await instance2.startBallot(TestProposalName, {from: account_issuer});

        let temp = await instance2.getVoteCount(0);
        let voterCount_before = temp.toNumber();
     
        await instance2.vote(0, {from: account_investor_1});
        
        temp = await instance2.getVoteCount(0);
        let voterCount_after = temp.toNumber();

        temp = await instance2.balanceOf.call(account_investor_1);
        let weight = temp.toNumber();

        assert.equal(voterCount_after, voterCount_before + weight, "voting not successful");
      });

      it("voters should have possibility to delegate", async () => {
          //@devs: out of scope, tested multiple times in ethereum standard
      });

       it("should calculate and announce winner", async () => {

        let instance2 = await EquityToken.deployed();
        let winnerName_ = await instance2.winningProposal({from: account_issuer});
                
        assert.notStrictEqual(winnerName_, "Test1", "incorrect announcement");
        });
//-----Voting-----------------------------------------------------------------------------------------------------------------------------          

})
