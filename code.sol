pragma solidity ^0.4.23;

contract LoanApplication {
    enum Status { Open, Accepted, Closed, Default }
    struct Loan {
        uint amount;
        uint time_period;
        Bid accepted_bid;
        Bid[] offered_bids;
        uint number_of_bids;
        Status loan_status;
        address borrower;
    }
    struct Bid {
        uint interest_rate;
        uint collateral_amount;
        address lender;
    }
    uint number_of_loans;
    mapping (uint => Loan) loans;

    constructor() public {
        number_of_loans = 0;
    }

    function create_loan(
        uint loan_amount, uint loan_time_period) public {
        // TODO: Create a new Loan and add it to loans mapping.
    }

    function bid_for_loan(
        uint loan_id,
        uint bid_interest_rate,
        uint bid_collateral_amount) public {
        // TODO: Create a Bid for loan_id
    }

    function accept_loan(uint loan_id, uint bid_id) public {
        // TODO: Accept loan and move collateral from
        //       borrower to lender
    }

    function close_loan(uint loan_id) public {
        // TODO: Move loan + interest to lenders account and
        //       collateral to borrowers account
    }
}