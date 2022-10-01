
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

    // Ensure that access is denied for non-Contract Owner account
    let accessDenied = false;
    try {
      await config.flightSuretyData.setOperatingStatus(false);
    }
    catch (e) {
      accessDenied = true;
    }
    assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
    await config.flightSuretyData.setOperatingStatus(true);
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

    // Ensure that access is allowed for Contract Owner account
    let accessDenied = false;
    try {
      await config.flightSuretyData.setOperatingStatus(false);
    }
    catch (e) {
      accessDenied = true;
    }
    assert.equal(accessDenied, false, "Access not restricted to Contract Owner");

  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

    await config.flightSuretyData.setOperatingStatus(false);

    let reverted = false;
    try {
      await config.flightSurety.setTestingMode(true);
    }
    catch (e) {
      reverted = true;
    }
    assert.equal(reverted, true, "Access not blocked for requireIsOperational");

    // Set it back for other tests to work
    await config.flightSuretyData.setOperatingStatus(true);

  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {

    // ARRANGE

    let error;
    // ACT
    try {
      await config.flightSuretyData.registerAirline("ND1309", { from: config.firstAirline });
    }
    catch (e) {
      error = e;
    }
    let result = await config.flightSuretyData.isAirlineRegistered.call(config.firstAirline);

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  it("(airline) Can't participate in contract until it submits funding of 10 ether", async () => {
    let error;
    const fee = web3.utils.toWei('9', "ether");
    try {
      await config.flightSuretyData.fundAirline(config.owner, { from: config.owner, value: fee });
    } catch (e) {
      error = e;
    }
    let result = await config.flightSuretyData.getAirlineFunds.call(config.owner);
    assert.equal(result, false, "Can't participate in contract until it submits funding of 10 ether");
  });

  it("(airline) Only existing airline may register a new airline until there are at least four airlines registered", async () => {

    for (let i = 2; i < 5; i++) {
      await config.flightSuretyApp.registerAirline(accounts[i], { from: config.testAddresses[i] });
    }

    for (let i = 2; i < 5; i++) {
      let result = await config.flightSuretyData.isAirlineRegistered.call(config.testAddresses[i]);
      if (i = 4) {
        assert.equal(result, false, "4th airline should not registered and require registration consensus.");
      } else {
        assert.equal(result, true, "%d nd airline registered succesfully.", i);
      }
    }
  });

  it("(Passengers) Passengers may pay up to 1 ether for purchasing flight insurance.", async () => {
    const fee = web3.utils.toWei('0.5', "ether");
    const flightName = "2nd air";
    const secondAirline = config.testAddresses[0];
    const timeStamp = 1520032867;
    const passengerAddress = config.testAddresses[2];
    let error = false;
    try {
      await config.flightSuretyApp.buy(secondAirline, flightName, timeStamp, { from: passengerAddress, value: fee });
    }
    catch (e) {
      error = true;
    }
    assert.equal(error, false, "Passenger can't buy an insurance less than 1 ether.")
  });

  it("(insurance) can't buy insurance for airlines that are not funded", async () => {
    let reverted = false;
    const flightName = "2nd air";
    const secondAirline = config.testAddresses[0];
    const timeStamp = 1520032867;
    try {
      await config.flightSuretyApp.buyInsurance(secondAirline, flightName, timeStamp, { from: passenger1, value: 0, gasPrice: 0 });
    }
    catch (e) {
      reverted = true;
    }

    assert.equal(reverted, true, "No funds provided");

  });


});
