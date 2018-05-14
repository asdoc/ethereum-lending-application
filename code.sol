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
        uint start_block_number;
    }

    struct Bid {
        uint interest_rate;
        uint collateral_amount;
        address lender;
        uint loan_id;
        uint expiry;
        uint settlement_amount;
        bool closed;
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
        uint bid_expiry) public payable returns (uint bid_id) {
        Loan storage loan = loans[loan_id];

        // Bidder should not be the loan borrower
        require(msg.sender != loan.borrower);

        // Bidder should send exactly what the borrower is asking
        require(msg.value == loan.amount);
        bid_id = loan.number_of_bids++;
        Bid storage bid = loan.offered_bids[bid_id];
        bid.interest_rate = bid_interest_rate;
        bid.collateral_amount = bid_collateral_amount;
        // Block number at which the bid will expire
        bid.expiry = bid_expiry;
        bid.lender = msg.sender;
        bid.settlement_amount = loan.amount + (loan.amount * bid.interest_rate * loan.time_period)/1000;
        bid.closed = false;
    }

    function accept_loan(uint loan_id, uint bid_id) payable public returns (bool) {
        Loan storage loan = loans[loan_id];
        if( msg.sender != loan.borrower) {
            return false;
        }
        require(loan.loan_status == Status.Open);

        Bid storage bid = loan.offered_bids[bid_id];
        if(block.number > bid.expiry) {
            // Expiry has passed
            return false;
        }
        // Borrower should send the collateral demanded by lender
        // Note that the collateral will be stored with the contract and won't be sent to lender
        require(msg.value == bid.collateral_amount);
        loan.accepted_bid_id = bid_id;
        loan.start_block_number = block.number;

        // Move money to borrower
        loan.borrower.transfer(loan.amount);
        
        loan.loan_status = Status.Accepted;
        
        return true;
    }

    function settle_loan(uint loan_id) payable public {
        Loan storage loan = loans[loan_id];
        
        require(loan.loan_status == Status.Accepted);

        // Only borrower can call this function
        require(msg.sender == loan.borrower);
        Bid storage bid = loan.offered_bids[loan.accepted_bid_id];
        
        // Borrower should send the settlement amount ( principal + interest )
        require(msg.value == bid.settlement_amount);
        
        // Time period should have passed        
        require(block.number >= (loan.start_block_number + loan.time_period));
        
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

        require(bid.closed == false);
        require(loan.accepted_bid_id != bid_id);

        if(loan.loan_status == Status.Open) {
            if(bid.expiry < block.number) {
                // Send the lender his money back as his loan has expired
                bid.lender.transfer(loan.amount);
                bid.closed = true;
                return true;
            } else {
                // Bid hasn't expired yet
                return false;
            }
        } else {
            if(loan.accepted_bid_id != bid_id) {
                // Send the lender his money back as his loan has not been accepted
                bid.lender.transfer(loan.amount);
                bid.closed = true;
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
        require((loan.start_block_number + loan.time_period) > block.number);
        Bid storage accepted_bid = loan.offered_bids[loan.accepted_bid_id];
        accepted_bid.lender.transfer(accepted_bid.collateral_amount);
        loan.loan_status = Status.Default;
    }
    
    function pass_block() public { }
    
    function get_block_number() public view returns (uint block_number) {
        block_number = block.number;
    }
    
    function get_settlement_amount(uint loan_id) public view returns(uint settlement_amount) {
        Loan storage loan = loans[loan_id];
        Bid storage bid = loan.offered_bids[loan.accepted_bid_id];
        settlement_amount = bid.settlement_amount;
    }
    
    function get_loan_count() public view returns(uint loan_count) {
        loan_count = number_of_loans;
    }
    
    function get_loan(uint loan_id) public view returns(uint amount, uint time_period, 
        Status status, uint number_of_bids, address borrower, uint start_block_number) {
        Loan storage loan = loans[loan_id];
        amount = loan.amount;
        time_period = loan.time_period;
        status = loan.loan_status;
        number_of_bids = loan.number_of_bids;
        borrower = loan.borrower;
        start_block_number = loan.start_block_number;
    }
    
    function get_bid(uint loan_id, uint bid_id) public view returns (uint interest_rate, uint collateral_amount, 
                    address lender, uint expiry, uint settlement_amount) {
        Loan storage loan = loans[loan_id];
        Bid storage bid = loan.offered_bids[bid_id];
        interest_rate = bid.interest_rate;
        collateral_amount = bid.collateral_amount;
        lender = bid.lender;
        expiry = bid.expiry;
        settlement_amount = bid.settlement_amount;
    }
}
