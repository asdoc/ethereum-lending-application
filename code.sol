pragma solidity ^0.4.23;

contract LoanApplication {
    enum Status { Open, Accepted, Closed, Default }
    struct Loan {
        uint amount;
        uint time_period;
        Bid accepted_bid;
        mapping (uint => Bid) offered_bids;
        uint number_of_bids;
        Status loan_status;
        address borrower;
    }
    struct Bid {
        uint interest_rate;
        uint collateral_amount;
        address lender;
        uint loan_id;
        uint exipry;
    }
    uint number_of_loans;
    mapping (uint => Loan) loans;

    constructor() public {
        number_of_loans = 0;
    }

    function create_loan(
        uint loan_amount, uint loan_time_period) returns (uint loan_id) public {
        loan_id = number_of_loans++;
        Loan loan = loans[loan_id];
        loan.amount = loan_amount;
        loan.time_period = loan_time_period;
        loan.number_of_bids = 0;
        loan.loan_status = Status.Open;
        borrower = msg.sender;
    }

    function bid_for_loan(
        uint loan_id,
        uint bid_interest_rate,
        uint bid_collateral_amount,
        uint bid_exipry) returns (uint bid_id) public {
            Loan loan = loans[loan_id];
            Bid bid = loan.offered_bids[number_of_bids++];
            bid.interest_rate = bid_interest_rate;
            bid.collateral_amount = bid_collateral_amount;
            bid.exipry = bid_exipry;
    }

    function accept_loan(uint loan_id, uint bid_id) public {
        // TODO: Check if caller is the loan borrower
        Loan loan = loans[loan_id];
        Bid bid = loan.offered_bids[bid_id];
        // TODO: Check if bid has not expired
        bid.accepted_bid = bid;
        // TODO: Move collateral from borrower to lender
        // TODO: Move money from lender to borrower
    }

    function close_loan(uint loan_id) public {
        // TODO: Move loan + interest to lenders account and
        //       collateral to borrowers account
    }
    
    function close_bid(uint loan_id, uint bid_id) public {
        // TODO: Close unaccepted bid whose exipry has passed
        //       Free up money for the current account
    }
}
