pragma solidity ^0.4.23;

contract LoanApplication {
    enum Status { Open, Accepted, Closed }
    struct Loan {
        uint amount;
        uint time_period;
        Bid accepted_bid;
        Bid[] offered_bids;
        uint number_of_bids;
        Status loan_status;
    }
    struct Bid {
        uint interest_rate;
        uint collateral_amount;
    }
    uint number_of_loans;
    mapping (uint => Loan) loans;

    constructor() public {
        number_of_loans = 0;
    }
}