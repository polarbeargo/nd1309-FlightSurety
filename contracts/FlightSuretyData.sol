pragma solidity >=0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner; // Account used to deploy contract
    bool private operational = true; // Blocks all state changes throughout the contract if false
    address[] airlines;
    uint256 airlineCounter = 0;
    mapping(address => uint256) private authorizedContracts;
    mapping(address => bool) private registeredAirlines;
    mapping(address => uint256) private fundedAirlines;

    struct Insurance {
        address passenger;
        uint256 amount;
        bool isCredited;
    }

    enum InsuranceState {
        Bought,
        Expired
    }

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/
    event InsuranceBought(
        address airlineAddress,
        string flightName,
        uint256 timestamp,
        address passenger,
        uint256 amount,
        uint256 refund
    );

    /**
     * @dev Constructor
     *      The deploying account becomes contractOwner
     */
    constructor(address firstAirline) public {
        contractOwner = msg.sender;
        registeredAirlines[firstAirline] = true;
        airlines.push(firstAirline);
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
     * @dev Modifier that requires the "operational" boolean variable to be "true"
     *      This is used on all state changing functions to pause the contract in
     *      the event there is an issue that needs to be fixed
     */
    modifier requireIsOperational() {
        require(operational, "Contract is currently not operational");
        _; // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
     * @dev Modifier that requires the "ContractOwner" account to be the function caller
     */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier isCallerAuthorized() {
        require(
            authorizedContracts[msg.sender] == 1,
            "Caller is not contract owner"
        );
        _;
    }

    modifier isCallerAirlineRegistered(address caller) {
        require(registeredAirlines[caller] == true, "Caller not registered");
        _;
    }

    modifier isAirlineNotRegistered(address airline) {
        require(
            registeredAirlines[airline] == false,
            "Airline already registered"
        );
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
     * @dev Get operating status of contract
     *
     * @return A bool that is the current operating status
     */
    function isOperational() public view returns (bool) {
        return operational;
    }

    /**
     * @dev Sets contract operations on/off
     *
     * When operational mode is disabled, all write transactions except for this one will fail
     */
    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }

    function isAirlineRegistered(address airline) external view returns (bool) {
        require(airline != address(0), "'airline' must be a valid address.");
        return registeredAirlines[airline];
    }

    function getAirlineFunds(address airline) public view returns (bool) {
        return registeredAirlines[airline];
    }

    /**

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
     * @dev Add an airline to the registration queue
     *      Can only be called from FlightSuretyApp contract
     *
     */

    function authorizeCaller(address contractAddress)
        external
        requireContractOwner
    {
        authorizedContracts[contractAddress] = 1;
    }

    function registerAirline(address airline)
        external
        requireIsOperational
        isCallerAuthorized
        isAirlineNotRegistered(airline)
        returns (bool success)
    {
        require(airline != address(0));
        airlines.push(airline);
        registeredAirlines[airline] = true;
        airlineCounter = airlineCounter.add(1);
        return registeredAirlines[airline];
    }

    function counter() external view returns (uint256) {
        return airlineCounter;
    }

    /**
     * @dev Buy insurance for a flight
     *
     */
    function buy(
        address airlineAddress,
        string flightName,
        uint256 timestamp,
        address passenger,
        uint256 amount,
        uint256 refund
    ) external requireIsOperational isCallerAuthorized {
        bytes32 flightKey = getFlightKey(airlineAddress, flightName, timestamp);
        emit InsuranceBought(
            airlineAddress,
            flightName,
            timestamp,
            passenger,
            amount,
            refund
        );
    }

    /**
     *  @dev Credits payouts to insurees
     */
    function creditInsurees(bytes32 flightKey, uint8 rate)
        public
        view
        returns (uint256 value)
    {}

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
     */
    function pay(
        address airline,
        string flight,
        uint256 ts,
        address passenger,
        uint256 payout
    ) external requireIsOperational isCallerAuthorized {
        bytes32 flightkey = getFlightKey(airline, flight, ts);
    }

    /**
     * @dev Initial funding for the insurance. Unless there are too many delayed flights
     *      resulting in insurance payouts, the contract should be self-sustaining
     *
     */
    function fund() public payable {}

    function getFlightKey(
        address airline,
        string memory flight,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
     * @dev Fallback function for funding smart contract.
     *
     */
    function() external payable {
        fund();
    }

    function authorizedContract(address dataContract)
        external
        requireContractOwner
    {
        authorizedContracts[dataContract] == 1;
    }

    function deauthorizedContract(address dataContract)
        external
        requireContractOwner
    {
        delete authorizedContracts[dataContract];
    }

    function fundAirline(address airline, uint256 amount)
        external
        requireIsOperational
        isCallerAuthorized
        isCallerAirlineRegistered(airline)
    {
        fundedAirlines[airline] += amount;
    }
}
