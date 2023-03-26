const { expect } = require("chai");
const { ethers } = require("hardhat");

const tokens = (n) => {
  return ethers.utils.parseUnits(n.toString(), "ether");
};

describe("FlashLoan", () => {
  let token, flashLoan, flashloanReceiver;
  let deployer;
  beforeEach(async () => {
    // Setup accounts
    accounts = await ethers.getSigners();
    deployer = accounts[0];
    // Load Accounts
    const FlashLoan = await ethers.getContractFactory("FlashLoan");
    const FlashLoanReceiver = await ethers.getContractFactory(
      "FlashLoanReceiver"
    );
    const Token = await ethers.getContractFactory("Token");

    token = await Token.deploy("Neutron", "NTR", "1000000");
    flashLoan = await FlashLoan.deploy(token.address);

    let transaction = await token
      .connect(deployer)
      .approve(flashLoan.address, tokens(1000000));
    await transaction.wait();

    transaction = await flashLoan
      .connect(deployer)
      .depositTokens(tokens(1000000));
    await transaction.wait();

    flashloanReceiver = await FlashLoanReceiver.deploy(flashLoan.address);
  });

  describe("Depolyment", () => {
    it("send tokens to the flash loan pool contract", async () => {
      expect(await token.balanceOf(flashLoan.address)).to.equal(
        tokens(1000000)
      );
    });
  });

  describe("Borrowing Funds", () => {
    it("borrows funds from the pool", async () => {
      let amount = tokens(100);
      let transaction = await flashloanReceiver
        .connect(deployer)
        .executeFlashLoan(amount);
      let result = await transaction.wait();

      await expect(transaction)
        .to.emit(flashloanReceiver, "LoanReceived")
        .withArgs(token.address, amount);
      console.log("Funds returned to the Lender");
    });
  });
});
