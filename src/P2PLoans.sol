//SPDX-License-Identifier: Apache 2.0
/**
@title Clixpesa P2PLoans Contract
@author Dekan Kachi - @kachdekan
@notice Allow users to borrow and lend funds to each other in a P2P fashion.
*/

pragma solidity ^0.8.19;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LoansInterest.sol";
import "hardhat/console.sol";

contract P2PLoans {
    using SafeMath for uint256;

    enum LoanState {
        isPending,
        isActive,
        isClosed,
        isDefaulted
    }

    /// @notice P2PLoan structs
    /// @dev LoanDetails struct for input parameters from the user
    struct LoanDetails {
        string loanId;
        IERC20 token;
        address payable initiator;
        uint256 principal;
        uint256 interest;
        uint256 minDuration;
        uint256 maxDuration;
        uint256 bCreditScore;
        bool isPrivate;
    }

    /// @dev LoanRequestDetails should be the same as LoanDetails
    struct LoanRequestDetails {
        LoanDetails LD;
    }

    /// @dev LoanOfferDetails should include loan limits
    struct LoanOfferDetails {
        LoanDetails LD;
        uint256 minLoanAmount;
        uint256 maxLoanAmount;
    }

    /// @dev LoanParticipants struct for borrower and lender
    struct LoanParticipants {
        address payable borrower;
        address payable lender;
    }

    /// @dev P2PLoanDetails struct for full P2PLoan details
    struct P2PLoanDetails {
        LoanDetails LD;
        LoanParticipants LP;
        LoanState LS;
        uint256 currentBalance;
        uint256 deadline;
        uint256 createdAt;
        uint256 updatedAt;
    }

    /// @notice P2PLoan strorage and tracking variables
    //List of all P2PLoans
    P2PLoanDetails[] allP2PLoans;
    mapping(string => uint256) p2pLoanIndex;
    mapping(address => P2PLoanDetails[]) myP2PLoans;
    mapping(address => mapping(string => uint256)) myP2PLoanIdx;

    //List of all Offers
    LoanOfferDetails[] allOffers;
    mapping(string => uint256) offerIndex;
    mapping(address => LoanOfferDetails[]) myOffers;
    mapping(address => mapping(string => uint256)) myOfferIdx;

    //List of all Requests
    LoanRequestDetails[] allRequests;
    mapping(string => uint256) requestIndex;
    mapping(address => LoanRequestDetails[]) myRequests;
    mapping(address => mapping(string => uint256)) myRequestIdx;

    //P2PLoan events
    event CreatedLoanRequest(address borrower, LoanRequestDetails LRD);
    event CreatedLoanOffer(address lender, LoanOfferDetails LOD);
    event FundedP2PLoan(address funder, string loanId, uint256 amount);
    event RepaidP2PLoan(address repayer, string loanId, uint256 amount);
    event CreatedP2PLoan(address initiator, P2PLoanDetails P2PLD);
    event UpdatedP2PLoan(string loanId, uint256 newBalance);

    constructor() {}

    /** 
    @notice Getting a Loan through a Request
    @dev Borrowers should be able to create a loan request and lenders can fund it
    @dev TODO: Add a function to allow borrowers to cancel a loan funding 
    @dev TODO: Add a function to remove a loan 7 days after it has been fully repaid
    @dev TODO: Add a function to allow lenders to cancel a loan funding
    @dev TODO: Calculate interest and add it to the loan amount
    */

    /// @notice Create a loan request
    /// @param LRD LoanDetails struct
    function createLoanRequest(LoanRequestDetails memory LRD) external {
        require(LRD.LD.initiator == msg.sender, "MBO");
        require(LRD.LD.principal > 0, "Principal<0");
        require(LRD.LD.interest > 0, "Interest<0");
        require(LRD.LD.minDuration > 0 && LRD.LD.maxDuration > 0, "Duration<0");
        require(LRD.LD.minDuration <= LRD.LD.maxDuration, "MinD > MaxD");

        allRequests.push(LRD);
        requestIndex[LRD.LD.loanId] = allRequests.length;

        myRequests[msg.sender].push(LRD);
        myRequestIdx[msg.sender][LRD.LD.loanId] = myRequests[msg.sender].length;

        emit CreatedLoanRequest(msg.sender, LRD);
    }

    /// @notice Fund a loan request
    /// @param _requestId Request ID
    /// @param _loanId Loan ID
    function fundLoanRequest(
        string memory _requestId,
        string memory _loanId
    ) external payable {
        // get the loan request
        require(requestIndex[_requestId] != 0, "!Request");
        LoanRequestDetails memory _thisRequest = allRequests[
            requestIndex[_requestId].sub(1)
        ];

        require(_thisRequest.LD.initiator != msg.sender, "!Self");
        require(
            _thisRequest.LD.token.balanceOf(msg.sender) >=
                _thisRequest.LD.principal,
            "<Balance"
        );
        /// @dev transfer funds to borrower
        require(
            _thisRequest.LD.token.transferFrom(
                msg.sender,
                _thisRequest.LD.initiator,
                _thisRequest.LD.principal
            ),
            "!Transfer"
        );

        /// @dev update user's loan lists
        _updateLoanListsFromRequest(
            _thisRequest.LD.initiator,
            msg.sender,
            _requestId,
            _loanId
        );

        emit CreatedP2PLoan(
            msg.sender,
            allP2PLoans[p2pLoanIndex[_loanId].sub(1)]
        );

        emit FundedP2PLoan(msg.sender, _loanId, _thisRequest.LD.principal);
    }

    /// @notice Repay a loan
    /// @param _loanId Loan ID
    function repayLoan(
        string memory _loanId,
        uint256 _amount
    ) external payable {
        // get the loan request
        require(p2pLoanIndex[_loanId] != 0, "!Loan");
        require(
            allP2PLoans[p2pLoanIndex[_loanId].sub(1)].LS == LoanState.isActive,
            "!Active"
        );
        require(
            allP2PLoans[p2pLoanIndex[_loanId].sub(1)].LP.borrower == msg.sender,
            "!Self"
        );
        require(
            allP2PLoans[p2pLoanIndex[_loanId].sub(1)].currentBalance > 0,
            "!Balance"
        );
        require(
            allP2PLoans[p2pLoanIndex[_loanId].sub(1)].currentBalance >= _amount,
            ">Amount"
        );
        /// @dev transfer funds to lender
        require(
            allP2PLoans[p2pLoanIndex[_loanId].sub(1)].LD.token.transferFrom(
                msg.sender,
                allP2PLoans[p2pLoanIndex[_loanId].sub(1)].LP.lender,
                _amount
            ),
            "!Transfer"
        );

        /// @dev update the loan details
        allP2PLoans[p2pLoanIndex[_loanId].sub(1)].currentBalance = allP2PLoans[
            p2pLoanIndex[_loanId].sub(1)
        ].currentBalance.sub(_amount);

        /// @dev update borrower's loan details
        myP2PLoans[msg.sender][myP2PLoanIdx[msg.sender][_loanId].sub(1)]
            .currentBalance = myP2PLoans[msg.sender][
            myP2PLoanIdx[msg.sender][_loanId].sub(1)
        ].currentBalance = allP2PLoans[p2pLoanIndex[_loanId].sub(1)]
            .currentBalance;

        /// @dev update lender's loan details
        myP2PLoans[allP2PLoans[p2pLoanIndex[_loanId].sub(1)].LP.lender][
            myP2PLoanIdx[allP2PLoans[p2pLoanIndex[_loanId].sub(1)].LP.lender][
                _loanId
            ].sub(1)
        ].currentBalance = myP2PLoans[
            allP2PLoans[p2pLoanIndex[_loanId].sub(1)].LP.lender
        ][
            myP2PLoanIdx[allP2PLoans[p2pLoanIndex[_loanId].sub(1)].LP.lender][
                _loanId
            ].sub(1)
        ].currentBalance = allP2PLoans[p2pLoanIndex[_loanId].sub(1)]
            .currentBalance;

        emit RepaidP2PLoan(msg.sender, _loanId, _amount);
    }

    /**  
    @notice Getting a Loan through an Offer
    @dev Lenders can create loan offers that borrowers can borrow from
    @dev Loan offers are like a pool of funds that multiple borrowers can borrow from
    */

    /// @notice Create a loan offer
    /// @param LOD LoanDetails struct
    function createLoanOffer(LoanOfferDetails memory LOD) external {
        require(LOD.LD.initiator == msg.sender, "MBO");
        require(LOD.LD.principal > 0, "Interest>0");
        require(LOD.LD.interest > 0, "Interest>0");
        require(LOD.LD.minDuration > 0 && LOD.LD.maxDuration > 0, "Duration>0");
        require(LOD.minLoanAmount > 0 && LOD.maxLoanAmount > 0, "LoanAmount>0");
        require(LOD.LD.minDuration <= LOD.LD.maxDuration, "!Duration");

        allOffers.push(LOD);
        myOffers[msg.sender].push(LOD);
        myOfferIdx[msg.sender][LOD.LD.loanId] = myOffers[msg.sender].length;
        offerIndex[LOD.LD.loanId] = allOffers.length;

        emit CreatedLoanOffer(msg.sender, LOD);
    }

    /// @notice Borrow from a loan offer
    /// @param _offerId Offer ID
    /// @param _loanId Loan ID
    /// @param _amount Amount to borrow
    /// @param _duration Duration of loan
    function borrowFromOffer(
        string memory _offerId,
        string memory _loanId,
        uint256 _amount,
        uint256 _duration
    ) external {
        require(offerIndex[_offerId] != 0, "!Offer");
        LoanOfferDetails memory _thisOffer = allOffers[
            offerIndex[_offerId].sub(1)
        ];
        require(_thisOffer.LD.initiator != msg.sender, "!Self");
        require(
            _amount >= allOffers[offerIndex[_offerId].sub(1)].minLoanAmount &&
                _amount <= allOffers[offerIndex[_offerId].sub(1)].maxLoanAmount,
            "!Amount"
        );
        require(
            _duration >=
                allOffers[offerIndex[_offerId].sub(1)].LD.minDuration &&
                _duration <=
                allOffers[offerIndex[_offerId].sub(1)].LD.maxDuration,
            "!Duration"
        );

        /// @dev prepare the loan details and change offerId with LoanId
        _updateLoanListsFromOffer(
            msg.sender,
            allOffers[offerIndex[_offerId].sub(1)].LD.initiator,
            _amount,
            _duration,
            _offerId,
            _loanId
        );

        emit CreatedP2PLoan(
            msg.sender,
            allP2PLoans[p2pLoanIndex[_loanId].sub(1)]
        );
    }

    /// @notice Lender should fund pending Loan
    /// @param _loanId Loan ID
    function fundPendingLoan(string memory _loanId) external {
        require(p2pLoanIndex[_loanId] != 0, "!Loan");
        require(
            allP2PLoans[p2pLoanIndex[_loanId].sub(1)].LP.lender == msg.sender,
            "!Lender"
        );
        require(
            allP2PLoans[p2pLoanIndex[_loanId].sub(1)].LS == LoanState.isPending,
            "!Pending"
        );

        /// @dev transfer funds to borrower
        require(
            allP2PLoans[p2pLoanIndex[_loanId].sub(1)].LD.token.transferFrom(
                msg.sender,
                allP2PLoans[p2pLoanIndex[_loanId].sub(1)].LP.borrower,
                allP2PLoans[p2pLoanIndex[_loanId].sub(1)].LD.principal
            ),
            "!Transfer"
        );

        /// @dev update the loan details
        allP2PLoans[p2pLoanIndex[_loanId].sub(1)].currentBalance = allP2PLoans[
            p2pLoanIndex[_loanId].sub(1)
        ].currentBalance.add(
                allP2PLoans[p2pLoanIndex[_loanId].sub(1)].LD.principal
            );
        allP2PLoans[p2pLoanIndex[_loanId].sub(1)].LS = LoanState.isActive;

        /// @dev update borrower's loan details
        myP2PLoans[allP2PLoans[p2pLoanIndex[_loanId].sub(1)].LP.borrower][
            myP2PLoanIdx[allP2PLoans[p2pLoanIndex[_loanId].sub(1)].LP.borrower][
                _loanId
            ].sub(1)
        ].currentBalance = allP2PLoans[p2pLoanIndex[_loanId].sub(1)]
            .LD
            .principal;
        myP2PLoans[allP2PLoans[p2pLoanIndex[_loanId].sub(1)].LP.borrower][
            myP2PLoanIdx[allP2PLoans[p2pLoanIndex[_loanId].sub(1)].LP.borrower][
                _loanId
            ].sub(1)
        ].LS = LoanState.isActive;

        /// @dev update lender's loan details
        myP2PLoans[msg.sender][myP2PLoanIdx[msg.sender][_loanId].sub(1)]
            .currentBalance = allP2PLoans[p2pLoanIndex[_loanId].sub(1)]
            .LD
            .principal;
        myP2PLoans[msg.sender][myP2PLoanIdx[msg.sender][_loanId].sub(1)]
            .LS = LoanState.isActive;

        emit FundedP2PLoan(
            msg.sender,
            _loanId,
            allP2PLoans[p2pLoanIndex[_loanId].sub(1)].LD.principal
        );
    }

    /// @notice Utility functions
    /// @dev Update user's lists from a request
    function _updateLoanListsFromRequest(
        address _borrower,
        address _lender,
        string memory _requestId,
        string memory _loanId
    ) internal {
        if (requestIndex[_requestId] != 0) {
            LoanDetails memory _thisRequestLD = allRequests[
                requestIndex[_requestId].sub(1)
            ].LD;
            _thisRequestLD.loanId = _loanId;
            //Push to allP2PLoans and update index
            allP2PLoans.push(
                P2PLoanDetails(
                    _thisRequestLD,
                    LoanParticipants(payable(_borrower), payable(_lender)),
                    LoanState.isActive,
                    allRequests[requestIndex[_requestId].sub(1)].LD.principal,
                    block.timestamp.add(
                        allRequests[requestIndex[_requestId].sub(1)]
                            .LD
                            .maxDuration
                    ),
                    block.timestamp,
                    block.timestamp
                )
            );
            p2pLoanIndex[_loanId] = allP2PLoans.length;

            //Push to lender's myP2PLoans and update index
            myP2PLoans[_lender].push(allP2PLoans[allP2PLoans.length.sub(1)]);
            myP2PLoanIdx[_lender][_loanId] = myP2PLoans[_lender].length;

            //Push to borrower's myP2PLoans and update index
            myP2PLoans[_borrower].push(allP2PLoans[allP2PLoans.length.sub(1)]);
            myP2PLoanIdx[_borrower][_loanId] = myP2PLoans[_borrower].length;

            /// @dev Update user's request lists
            /// @dev Remove request from allRequests and update index
            allRequests[requestIndex[_requestId].sub(1)] = allRequests[
                allRequests.length.sub(1)
            ];
            requestIndex[
                allRequests[requestIndex[_requestId].sub(1)].LD.loanId
            ] = requestIndex[_requestId];
            delete requestIndex[_requestId];
            allRequests.pop();

            /// @dev Remove request from user's myRequests and update index
            myRequests[_borrower][
                myRequestIdx[_borrower][_requestId].sub(1)
            ] = myRequests[_borrower][myRequests[_borrower].length.sub(1)];
            myRequestIdx[_borrower][
                myRequests[_borrower][myRequests[_borrower].length.sub(1)]
                    .LD
                    .loanId
            ] = myRequestIdx[_borrower][_requestId];
            delete myRequestIdx[_borrower][_requestId];
            myRequests[_borrower].pop();
        }
    }

    /// @dev Update user's lists from am offer
    function _updateLoanListsFromOffer(
        address _borrower,
        address _lender,
        uint256 _amount,
        uint256 _duration,
        string memory _offerId,
        string memory _loanId
    ) internal {
        if (offerIndex[_offerId] != 0) {
            LoanDetails memory _thisOfferLD = allOffers[
                offerIndex[_offerId].sub(1)
            ].LD;
            _thisOfferLD.loanId = _loanId;
            _thisOfferLD.principal = _amount;
            //Push to allP2PLoans and update index
            allP2PLoans.push(
                P2PLoanDetails(
                    _thisOfferLD,
                    LoanParticipants(payable(_borrower), payable(_lender)),
                    LoanState.isPending,
                    0,
                    block.timestamp.add(_duration),
                    block.timestamp,
                    block.timestamp
                )
            );
            p2pLoanIndex[_loanId] = allP2PLoans.length;

            //Push to lender's myP2PLoans and update index
            myP2PLoans[_lender].push(allP2PLoans[allP2PLoans.length.sub(1)]);
            myP2PLoanIdx[_lender][_loanId] = myP2PLoans[_lender].length;

            //Push to borrower's myP2PLoans and update index
            myP2PLoans[_borrower].push(allP2PLoans[allP2PLoans.length.sub(1)]);
            myP2PLoanIdx[_borrower][_loanId] = myP2PLoans[_borrower].length;

            /// @dev Update user's offer pool
            allOffers[offerIndex[_offerId].sub(1)].LD.principal = allOffers[
                offerIndex[_offerId].sub(1)
            ].LD.principal.sub(_amount);
            myOffers[_lender][myOfferIdx[_lender][_offerId].sub(1)]
                .LD
                .principal = myOffers[_lender][
                myOfferIdx[_lender][_offerId].sub(1)
            ].LD.principal.sub(_amount);

            /// @dev Update user's offer lists if pool is low
            /// @dev Remove offer from allOffers and update index if pool is low
            if (
                allOffers[offerIndex[_offerId].sub(1)].LD.principal <
                allOffers[offerIndex[_offerId].sub(1)].minLoanAmount
            ) {
                allOffers[offerIndex[_offerId].sub(1)] = allOffers[
                    allOffers.length.sub(1)
                ];
                offerIndex[
                    allOffers[offerIndex[_offerId].sub(1)].LD.loanId
                ] = offerIndex[_offerId];
                delete offerIndex[_offerId];
                allOffers.pop();

                /// @dev Remove offer from user's myOffers and update index
                myOffers[_lender][
                    myOfferIdx[_lender][_offerId].sub(1)
                ] = myOffers[_lender][myOffers[_lender].length.sub(1)];
                myOfferIdx[_lender][
                    myOffers[_lender][myOffers[_lender].length.sub(1)].LD.loanId
                ] = myOfferIdx[_lender][_offerId];
                delete myOfferIdx[_lender][_offerId];
                myOffers[_lender].pop();
            }
        }
    }

    /// @dev Update loan interest and duration
    function _updateLoanBalancefromInterest(string memory _loanId) internal {
        require(p2pLoanIndex[_loanId] != 0, "!Loan");
        require(
            allP2PLoans[p2pLoanIndex[_loanId].sub(1)].currentBalance > 0,
            "!Balance"
        );

        uint256 _newBalance = LoanInterest._getNewBalance(
            allP2PLoans[p2pLoanIndex[_loanId].sub(1)].currentBalance,
            allP2PLoans[p2pLoanIndex[_loanId].sub(1)].LD.interest,
            block.timestamp.sub(
                allP2PLoans[p2pLoanIndex[_loanId].sub(1)].updatedAt
            )
        );
        console.log("New Balance: %s", _newBalance);
        //update loan balance and timestamp
        allP2PLoans[p2pLoanIndex[_loanId].sub(1)].currentBalance = allP2PLoans[
            p2pLoanIndex[_loanId].sub(1)
        ].currentBalance = _newBalance;
        allP2PLoans[p2pLoanIndex[_loanId].sub(1)].updatedAt = block.timestamp;

        /*update borrower's loan
        myP2PLoans[allP2PLoans[p2pLoanIndex[_loanId].sub(1)].LP.borrower][
            myP2PLoanIdx[allP2PLoans[p2pLoanIndex[_loanId].sub(1)].LP.borrower][
                _loanId
            ].sub(1)
        ] = allP2PLoans[p2pLoanIndex[_loanId].sub(1)];

        //update lender's loan
        myP2PLoans[allP2PLoans[p2pLoanIndex[_loanId].sub(1)].LP.lender][
            myP2PLoanIdx[allP2PLoans[p2pLoanIndex[_loanId].sub(1)].LP.lender][
                _loanId
            ].sub(1)
        ] = allP2PLoans[p2pLoanIndex[_loanId].sub(1)];*/

        emit UpdatedP2PLoan(_loanId, _newBalance);
    }

    /// @notice Getter functions
    //get all available requests
    function getAvailableRequests()
        external
        view
        returns (LoanRequestDetails[] memory)
    {
        return allRequests;
    }

    //get reqeusts by owner
    function getRequestsByOwner(
        address _owner
    ) external view returns (LoanRequestDetails[] memory) {
        return myRequests[_owner];
    }

    //get request by id
    function getRequestById(
        string memory _loanId
    ) external view returns (LoanRequestDetails memory) {
        return allRequests[requestIndex[_loanId].sub(1)];
    }

    //get all available offers
    function getAvailableOffers()
        external
        view
        returns (LoanOfferDetails[] memory)
    {
        return allOffers;
    }

    //get offers by owner
    function getOffersByOwner(
        address _owner
    ) external view returns (LoanOfferDetails[] memory) {
        return myOffers[_owner];
    }

    //get offer by id
    function getOfferById(
        string memory _loanId
    ) external view returns (LoanOfferDetails memory) {
        return allOffers[offerIndex[_loanId].sub(1)];
    }

    //get all loans
    function getAllP2PLoans() external view returns (P2PLoanDetails[] memory) {
        return allP2PLoans;
    }

    //get loans by owner
    function getP2PLoansByOwner(
        address _owner
    ) external view returns (P2PLoanDetails[] memory) {
        return myP2PLoans[_owner];
    }

    //get loan by id
    function getP2PLoanById(
        string memory _loanId
    ) external view returns (P2PLoanDetails memory) {
        return allP2PLoans[p2pLoanIndex[_loanId].sub(1)];
    }

    //update loan balance from interest
    function updateLoanBalance(string memory _loanId) external {
        _updateLoanBalancefromInterest(_loanId);
    }
}
