## Audit Fixes

### Rosca.sol
1. Potential Reentrancy Attack in payoutPot Function
    > Moved token transfer as last call
    > Defined Rosca token as Immutable so it cannot be modified afterwards
2. Transfer Amount Might Be Zero - Acknowldged
	> Pot balance is only payedOut when it has reached the Roscas Goal Amount
	> Full balance is transfered. 
3. Pot Funding Exceeding Goal
	> Introduced check to compare amount to remaining fundable amount
4. Overfunding Vulnerability
	> Added condition to check for excess funds and keep a record of this. 
5. Missing Update of isPotted
	> Update is there 
	> Added test to check for this. 
6. No Member Limit
	> Added check for members limit
7. Recipient and Caller Overlap - Acknowldged
	> Caller can be anyone. As payOut can also be triggered automaticaly externally.
8. Floating Pragma
	> Fixed pragma locking
9. Reliance on External Contracts - Acknowledged
	> CalcTime is an internal library. hence we take full responsibility of its lifecycle

### RoscaSpaces.sol
1. No Removal or Deletion Mechanism 
	> Added End rosca function. 
2. Lack of Input Validation
	> Check if owner is actually member in all returned roscas
3. Potential Scalability Issue with Data Retrieval
	> Added "pagination" to getRoscaSpaces
4. No Emergency Shutdown
	> Add pausable by Admin member
5. Lack of Input Validation for Array Access
	> Add bounds check
	> Compare if actually exists in Rosca List
6. No Rate Limiting
	> Added Limit of space to 10 per user. 
7. Redundant Data Structures
	> !TODO Refactor in later version as this will change the logic alot
8. Floating Pragma
	> Fixed pragma locking
9. Lack of Access Control - Acknowledged
	> Any one should be able to create a Rosca
	> Fee might be introduced to limit spamming 

### LoansInterest.sol
1. Lack of Input Validation
	> Add input validation to ensure rate is within 10000 basis points
2.  Floating Pragma
	> Fixed pragma locking

PersonalSpaces.sol
1. Token Address Update Risk
	> Added check to ensure token is always the same
2. Potential reentrancy attack 
	> Moved token transfer after check and state managment
3. Missing Allowance Check before Token Transfer
	> Added allowance check
4. Logic Bug: Non-owners can’t fund personal spaces - Acknowledged
	> A personal space is only for the owner and no else should fund it
5. No way to retrieve ERC20 tokens if sent directly - Acknowledged
	> fundPersonalSpace check for the token allowance for the prticular space hence user can only approve that specific token
	> !TODO add a refundToken fn should there be a direct transfer
6. No way to delete personal spaces - Acknowledge
	> !TODO add automatic Deletion of space after a grace period of being closed. 
7. Potential Revert on Already Withdrawn Personal Space
	> Added check for activity status
	> Added check of currentbalance before withdraw.
8.  Redundant Goal Amount Check
	> Removed redundant goal check
9.  Ambiguous Function Return
	> Added  return true statement
10. Lack of Input Length Check
	> Added Input length check
11. Duplicate storage and checks for space IDs - Acknowledged
	> !TODO Refactor in later version as this will change the logic alot
12. Floating Pragma
	> Fixed pragma locking

### P2PLoans.sol
1. Borrower Loan Repayment Guarantee - Acknowledged
	> This is by design as this are Non coletrized loans. 
	> External mechanism are implemented to mitigate default as a business case
2. Missing Token Address Check 
	> Added token address check 
3. Missing Allowance Check
	> Added allowance checks
4. Unsupported Ether Transactions
	> Removed payable as Loans will only support ERC20 tokens (stablecoins)
5. Floating Pragma
	> Fixed pragma locking
6. Unused Variables in Contract - Acknowledged
	> isPrivate and bCreditScore are used in the Frontend. 
7. Error Message Inconsistency
	> Fixed error message inconsistency

### CalcTime.sol
1.  Potential Infinite Loop in _getDayNo and _getOcurranceNo 
	> Added a default return statement
	> Followed up by checks for this where the function are used
2. Lack of Input Validation
	> Added Input validation
3. Misleading Comments
	> Fixed comments
4. Use of block.timestamp - Acknoweledged
	> The deadline set from this timestamp is not critical. 

### Best Practices
1. Misleading Transfer Message - Acknowledged
	> !TODO Use custom errors in later version
2. Contract Upgradability - Acknowledeged 
	> This will be handled in Hardhat during deployement 
3. Limited Documentation : LoansInterest
	> Added comments in the contract 
