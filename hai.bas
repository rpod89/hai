/* 
 The HAI the Hidden SAI backed by DERO is an attempt to 
 create a hidden stable coin with a colleteral of 25% 
 for the dARCH 2021 competition

 Created by 89ron - MIT License 
*/


FUNCTION InitializePrivate() Uint64
10 STORE("owner", signer())
20 STORE("collateral", 4)   // collateral is 25% of dero deposited
30 STORE("price", 10)       // price is update through an Oracle 
40 STORE("liquidity_pool", 0)      
60 RETURN 0
END FUNCTION


// ++ Public ++

// user can convert Dero for the hai
FUNCTION Buy() Uint64
10 DIM deposit, collateral, hai as Uint64
20 LET deposit = DEROVALUE()
30 IF require(deposit > 0, "invalid deposit value") > 0 THEN GOTO 999
41 LET collateral = deposit / LOAD("collateral")
50 IF require(collateral > 0, "invalid collateral value") > 0 THEN GOTO 999
60 LET hai = deposit - collateral
70 IF add_to_liquidity_pool(deposit) > 0 THEN GOTO 999
80 IF issue_hai(hai) > 0 THEN GOTO 999
90 RETURN 0
999 RETURN 999
END FUNCTION

// users can redeem their hai for Dero
FUNCTION Sell() Uint64
10 DIM deposit, collateral, hai as Uint64
20 LET hai = TOKENVALUE()
30 IF require(hai > 0, "invalid hai value") > 0 THEN GOTO 999
40 LET collateral = hai / LOAD("collateral") 
50 IF require(collateral > 0, "invalid collateral value") > 0 THEN GOTO 999
60 LET hai = hai + collateral
70 IF issue_dero(hai) > 0 THEN GOTO 999
80 RETURN 0
999 RETURN 999
END FUNCTION

// users can look at the current conversion price 
FUNCTION Price() Uint64
10 RETURN LOAD("price")
END FUNCTION

// users can look at the liquidity pool
FUNCTION Liquidity() Uint64
10 RETURN LOAD("liquidity_pool")
END FUNCTION

// ++ ADMIN ++

// The owner update the price with a centralized Oracle
FUNCTION SetPrice(price Uint64) Uint64
10 IF require(SIGNER() == LOAD("owner"), "Only the owner have access") > 0 THEN GOTO 999
20 IF require(price > 0, "invalid value") > 0 THEN GOTO 999
30 STORE("price", price)
40 RETURN 0
END FUNCTION

// -- Private --

FUNCTION issue_hai(hai Uint64) Uint64
10 DIM total as Uint64
20 IF require(hai > 0, "invalid hai value") > 0 THEN GOTO 999
30 LET total = hai * LOAD("price")
40 ADD_VALUE(SIGNER(), total)
50 RETURN 0
999 RETURN 999
END FUNCTION

FUNCTION issue_dero(dero Uint64) Uint64
10 DIM total as Uint64
20 IF require(dero > 0, "invalid dero value") > 0 THEN GOTO 999
30 LET total = dero / LOAD("price")
40 IF remove_from_liquidity_pool(total) > 0 THEN GOTO 999
60 SEND_DERO_TO_ADDRESS(SIGNER(), total)
70 RETURN 0
999 RETURN 999
END FUNCTION

// add dero to the liquidity pool
FUNCTION add_to_liquidity_pool(deposit Uint64) Uint64
10 IF require(deposit > 0, "invalid deposit value") > 0 THEN GOTO 999
20 STORE("liquidity_pool", LOAD("liquidity_pool") + deposit)
30 RETURN 0
999 RETURN 999
END FUNCTION

// remove deros from the liquidity pool
FUNCTION remove_from_liquidity_pool(deposit Uint64) Uint64
10 IF require(deposit < LOAD("liquidity_pool"), "invalid deposit value") > 0 THEN GOTO 999
20 STORE("liquidity_pool", LOAD("liquidity_pool") - deposit)  
30 RETURN 0
999 RETURN 999
END FUNCTION

// == Library(s) ==


// ++ require ++

FUNCTION require(condition Uint64, error_msg String) Uint64
10 IF require_(condition) == 0 THEN GOTO 30
    20 RETURN error(error_msg)
30 RETURN 0
END FUNCTION

FUNCTION require_(condition Uint64) Uint64 
10 IF condition == 1 THEN GOTO 40
    20 RETURN 1
40 RETURN 0
END FUNCTION

FUNCTION error(error_msg String) Uint64
10 IF "invalid value" == error_msg THEN GOTO 40
11 IF "invalid dero value" == error_msg THEN GOTO 41
12 IF "invalid hai value" == error_msg THEN GOTO 42
13 IF "invalid deposit value" == error_msg THEN GOTO 43
14 IF "invalid collateral value" == error_msg THEN GOTO 44
20 IF "Only the owner have access" == error_msg THEN GOTO 50
30 IF "" == error_msg THEN GOTO 9999
40 RETURN 10
41 RETURN 11
42 RETURN 12
43 RETURN 13
44 RETURN 14
50 RETURN 777 
9999 RETURN 99
END FUNCTION

// -- require --
