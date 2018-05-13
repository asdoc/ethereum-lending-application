pragma solidity ^0.4.23;

contract LoanApplication {
    enum Status { Open, Accepted, Settled, Default }
    
    struct Loan {
        uint amount;
        uint time_period;
        uint accepted_bid_id;
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
        uint settlement_amount;
    }

    mapping (uint => Loan) loans;

    uint number_of_loans;

    constructor() public {
        number_of_loans = 0;
    }

    function create_loan(
        uint loan_amount, uint loan_time_period) public returns (uint loan_id) {
        loan_id = number_of_loans++;
        Loan storage loan = loans[loan_id];
        loan.amount = loan_amount;
        loan.time_period = loan_time_period;
        loan.number_of_bids = 0;
        loan.loan_status = Status.Open;
        loan.borrower = msg.sender;
    }

    function bid_for_loan(
        uint loan_id,
        uint bid_interest_rate,
        uint bid_collateral_amount,
        uint bid_exipry) public payable returns (uint bid_id) {
        Loan storage loan = loans[loan_id];

        // Bidder should send exactly what the borrower is asking
        require(msg.value == loan.amount);
        bid_id = loan.number_of_bids++;
        Bid storage bid = loan.offered_bids[bid_id];
        bid.interest_rate = bid_interest_rate;
        bid.collateral_amount = bid_collateral_amount;
        bid.exipry = bid_exipry;
        bid.lender = msg.sender;
        bid.settlement_amount = loan.amount + (loan.amount * bid.interest_rate * loan.time_period);
    }

    function accept_loan(uint loan_id, uint bid_id) payable public returns (bool) {
        Loan storage loan = loans[loan_id];
        if( msg.sender != loan.borrower) {
            return false;
        }
        Bid storage bid = loan.offered_bids[bid_id];
        if(block.number > bid.exipry) {
            return false;
        }
        // Borrower should send the collateral demanded by lender
        // Note that the collateral will be stored with the contract and won't be sent to lender
        require(msg.value == bid.collateral_amount);
        loan.accepted_bid_id = bid_id;
        
        // Move money to borrower
        loan.borrower.transfer(loan.amount);
        
        loan.loan_status = Status.Accepted;
        
        return true;
    }

    function settle_loan(uint loan_id) payable public {
        Loan storage loan = loans[loan_id];
        
        // Only borrower can call this function
        require(msg.sender == loan.borrower);
        Bid storage bid = loan.offered_bids[loan.accepted_bid_id];
        
        // Borrower should send the settlement amount ( principal + interest )
        require(msg.value == bid.settlement_amount);
        
        // Time period should have passed        
        require(block.number >= loan.time_period);
        
        // Move loan + interest to lenders account and
        bid.lender.transfer(bid.settlement_amount);
        
        // Move collateral to borrowers account
        loan.borrower.transfer(bid.collateral_amount);
        
        loan.loan_status = Status.Settled;
    }
    
    function close_bid(uint loan_id, uint bid_id) public returns (bool) {
        // Close unaccepted bid whose exipry has passed or which aren't accepted
        //       Free up money for the current account
        Loan storage loan = loans[loan_id];
        Bid storage bid = loan.offered_bids[bid_id];
        
        if(loan.loan_status == Status.Open) {
            if(bid.exipry < block.number) {
                // Send the lender his money back as his loan has expired
                bid.lender.transfer(loan.amount);
                return true;
            } else {
                // Bid hasn't expired yet
                return false;
            }
        } else {
            if(loan.accepted_bid_id != bid_id) {
                // Send the lender his money back as his loan has not been accepted
                bid.lender.transfer(loan.amount);
                return true;
            } else {
                // The Bid has been already accepted
                return false;
            }
        }
    }
    
    function mark_default(uint loan_id) public returns (bool) {
        Loan storage loan = loans[loan_id];
        require(loan.loan_status == Status.Accepted);
        require(loan.time_period > block.number);
        Bid storage accepted_bid = loan.offered_bids[loan.accepted_bid_id];
        accepted_bid.lender.transfer(accepted_bid.collateral_amount);
        loan.loan_status = Status.Default;
    }
}
