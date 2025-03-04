use starknet::ContractAddress;
use starknet::{testing, contract_address_const};

use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

use contracts::escrow::interface::{IEscrowDispatcher, IEscrowDispatcherTrait};
use contracts::tests::utils::{deploy_mock_erc20, OWNER, BOB, deploy_escrow, setup};

use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, spy_events, EventSpyAssertionsTrait,
};

#[test]
#[should_panic(expected: ('Caller is missing role',))]
fn test_deposit_to_wallet_unauthorized() {
    let (wager, escrow, strk_dispatcher) = setup();

    let amount = 50_u256;

    // Approve escrow to spend
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.approve(escrow.contract_address, amount);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Attempt to deposit to wallet from an unauthorized address (BOB)
    start_cheat_caller_address(escrow.contract_address, BOB()); // Simulate unauthorized caller
    escrow.deposit_to_wallet(OWNER(), amount);
}

#[test]
#[should_panic(expected: ('Insufficient balance',))]
fn test_deposit_to_wallet_insufficient_balance() {
    let (wager, escrow, strk_dispatcher) = setup();

    let amount = 50_u256;

    // Approve escrow to spend
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.approve(escrow.contract_address, amount);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Deposit to wallet (caller is Wager Contract, which has WAGER_ROLE)
    start_cheat_caller_address(
        escrow.contract_address, wager.contract_address
    ); // Simulate Wager Contract
    escrow.deposit_to_wallet(BOB(), amount);
    stop_cheat_caller_address(escrow.contract_address);
}

#[test]
fn test_deposit_to_wallet_ok() {
    let (wager, escrow, strk_dispatcher) = setup();

    let amount = 50_u256;

    // Approve escrow to spend
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.approve(escrow.contract_address, amount);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Deposit to wallet (caller is Wager Contract, which has WAGER_ROLE)
    start_cheat_caller_address(
        escrow.contract_address, wager.contract_address
    ); // Simulate Wager Contract
    escrow.deposit_to_wallet(OWNER(), amount);

    assert(strk_dispatcher.balance_of(escrow.contract_address) == amount, 'wrong amount');
    assert(escrow.get_balance(OWNER()) == amount, 'wrong balance');
    stop_cheat_caller_address(escrow.contract_address);
}

#[test]
fn test_withdraw_from_wallet() {
    let (wager, escrow, strk_dispatcher) = setup();

    let initial_balance = 1000_u256;
    let withdrawal_amount = 500_u256;

    // Approve escrow to spend
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.approve(escrow.contract_address, initial_balance);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Deposit to wallet (caller is Wager Contract, which has WAGER_ROLE)
    start_cheat_caller_address(
        escrow.contract_address, wager.contract_address
    ); // Simulate Wager Contract
    escrow.deposit_to_wallet(OWNER(), initial_balance);

    // Withdraw from wallet (caller is Wager Contract, which has WAGER_ROLE)
    escrow.withdraw_from_wallet(OWNER(), withdrawal_amount);

    let final_balance = escrow.get_balance(OWNER());
    stop_cheat_caller_address(escrow.contract_address);
    assert(final_balance == initial_balance - withdrawal_amount, 'wrong balance');
}

#[test]
#[should_panic(expected: ('Caller is missing role',))]
fn test_withdraw_from_wallet_unauthorized() {
    let (wager, escrow, strk_dispatcher) = setup();

    let initial_balance = 1000_u256;
    let withdrawal_amount = 500_u256;

    // Approve escrow to spend
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.approve(escrow.contract_address, initial_balance);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Deposit to wallet (caller is Wager Contract, which has WAGER_ROLE)
    start_cheat_caller_address(escrow.contract_address, OWNER()); // Simulate Wager Contract
    escrow.deposit_to_wallet(OWNER(), initial_balance);
    stop_cheat_caller_address(escrow.contract_address);

    // Attempt to withdraw from wallet from an unauthorized address (BOB)
    start_cheat_caller_address(escrow.contract_address, BOB()); // Simulate unauthorized caller
    escrow.withdraw_from_wallet(OWNER(), withdrawal_amount);
}

#[test]
fn test_get_balance() {
    let (wager, escrow, strk_dispatcher) = setup();

    let amount = 50_u256;

    // Approve escrow to spend
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.approve(escrow.contract_address, amount);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Deposit to wallet (caller is Wager Contract, which has WAGER_ROLE)
    start_cheat_caller_address(
        escrow.contract_address, wager.contract_address
    ); // Simulate Wager Contract
    escrow.deposit_to_wallet(OWNER(), amount);

    // Get balance (caller is Wager Contract, which has WAGER_ROLE)
    let balance = escrow.get_balance(OWNER());
    stop_cheat_caller_address(escrow.contract_address);

    assert(balance == amount, 'wrong balance');
}

#[test]
#[should_panic(expected: ('Invalid address',))]
fn test_deposit_to_wallet_zero_address() {
    let (wager, escrow, strk_dispatcher) = setup();

    // deposit to wallet
    start_cheat_caller_address(escrow.contract_address, wager.contract_address);
    escrow.deposit_to_wallet(0.try_into().unwrap(), 50_u256);
}

#[test]
#[should_panic(expected: ('Invalid address',))]
fn test_withdraw_from_wallet_zero_address() {
    let (wager, escrow, strk_dispatcher) = setup();

    // withdraw from wallet
    start_cheat_caller_address(escrow.contract_address, wager.contract_address);
    escrow.withdraw_from_wallet(0.try_into().unwrap(), 500_u256);
}

#[test]
#[should_panic(expected: ('Insufficient funds',))]
fn test_withdraw_from_wallet_not_enough_balance() {
    let (wager, escrow, strk_dispatcher) = setup();

    let initial_balance = 100_u256;
    let withdrawal_amount = 500_u256;

    // approve escrow to spend
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.approve(escrow.contract_address, initial_balance);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // deposit to wallet
    start_cheat_caller_address(escrow.contract_address, wager.contract_address);
    escrow.deposit_to_wallet(OWNER(), initial_balance);

    escrow.withdraw_from_wallet(OWNER(), withdrawal_amount);
}

#[test]
#[should_panic(expected: ('Amount must be positive',))]
fn test_amount_must_be_positive() {
    let (wager, escrow, strk_dispatcher) = setup();

    let amount = 0_u256;

    // approve escrow to spend
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.approve(escrow.contract_address, amount);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // deposit to wallet
    start_cheat_caller_address(escrow.contract_address, wager.contract_address);
    escrow.deposit_to_wallet(OWNER(), amount);
    assert(escrow.get_balance(OWNER()) > amount, 'amount must be positive');
}

#[test]
#[should_panic(expected: ('Caller is missing role',))]
fn test_get_balance_unauthorized() {
    let (wager, escrow, strk_dispatcher) = setup();

    let amount = 50_u256;

    // Approve escrow to spend
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.approve(escrow.contract_address, amount);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Deposit to wallet (caller is Wager Contract, which has WAGER_ROLE)
    start_cheat_caller_address(escrow.contract_address, OWNER()); // Simulate Wager Contract
    escrow.deposit_to_wallet(OWNER(), amount);
    stop_cheat_caller_address(escrow.contract_address);

    // Attempt to get balance from an unauthorized address (BOB)
    start_cheat_caller_address(escrow.contract_address, BOB()); // Simulate unauthorized caller
    escrow.get_balance(OWNER());
}

#[test]
fn test_fund_wager() {
    let (wager, escrow, strk_dispatcher) = setup();

    let deposit_amount = 100_u256;
    let wager_amount = 50_u256;
    let wager_id = 1_u64;

    // Approve escrow to spend
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.approve(escrow.contract_address, deposit_amount);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Deposit to wallet first
    start_cheat_caller_address(escrow.contract_address, wager.contract_address);
    escrow.deposit_to_wallet(OWNER(), deposit_amount);

    // Fund the wager
    escrow.fund_wager(wager_id, OWNER(), wager_amount);

    // Check balances
    let final_user_balance = escrow.get_balance(OWNER());
    let wager_stake = escrow.get_wager_stake(wager_id);
    stop_cheat_caller_address(escrow.contract_address);

    assert(final_user_balance == deposit_amount - wager_amount, 'wrong user balance');
    assert(wager_stake == wager_amount, 'wrong wager stake');
}

#[test]
#[should_panic(expected: ('Insufficient balance',))]
fn test_fund_wager_insufficient_balance() {
    let (wager, escrow, strk_dispatcher) = setup();

    let deposit_amount = 20_u256;
    let wager_amount = 50_u256;
    let wager_id = 1_u64;

    // Approve escrow to spend
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.approve(escrow.contract_address, deposit_amount);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Deposit to wallet first
    start_cheat_caller_address(escrow.contract_address, wager.contract_address);
    escrow.deposit_to_wallet(OWNER(), deposit_amount);

    // Try to fund the wager with more than the deposited amount
    escrow.fund_wager(wager_id, OWNER(), wager_amount);
}

#[test]
#[should_panic(expected: ('Caller is missing role',))]
fn test_fund_wager_unauthorized() {
    let (wager, escrow, strk_dispatcher) = setup();

    let wager_amount = 50_u256;
    let wager_id = 1_u64;

    // Attempt to fund wager from an unauthorized address (BOB)
    start_cheat_caller_address(escrow.contract_address, BOB());
    escrow.fund_wager(wager_id, OWNER(), wager_amount);
}

#[test]
fn test_fund_multiple_wagers() {
    let (wager, escrow, strk_dispatcher) = setup();

    let deposit_amount = 100_u256;
    let wager1_amount = 30_u256;
    let wager2_amount = 40_u256;
    let wager1_id = 1_u64;
    let wager2_id = 2_u64;

    // Approve escrow to spend
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.approve(escrow.contract_address, deposit_amount);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Deposit to wallet first
    start_cheat_caller_address(escrow.contract_address, wager.contract_address);
    escrow.deposit_to_wallet(OWNER(), deposit_amount);

    // Fund first wager
    escrow.fund_wager(wager1_id, OWNER(), wager1_amount);

    // Fund second wager
    escrow.fund_wager(wager2_id, OWNER(), wager2_amount);

    // Check balances
    let final_user_balance = escrow.get_balance(OWNER());
    let wager1_stake = escrow.get_wager_stake(wager1_id);
    let wager2_stake = escrow.get_wager_stake(wager2_id);
    stop_cheat_caller_address(escrow.contract_address);

    assert(
        final_user_balance == deposit_amount - wager1_amount - wager2_amount, 'wrong user balance'
    );
    assert(wager1_stake == wager1_amount, 'wrong wager1 stake');
    assert(wager2_stake == wager2_amount, 'wrong wager2 stake');
}

// stop
#[test]
#[should_panic(expected: ('Invalid address',))]
fn test_fund_wager_zero_address() {
    let (wager, escrow, strk_dispatcher) = setup();

    let wager_id = 1_u64;
    let amount = 50_u256;

    // Attempt to fund wager with zero address
    start_cheat_caller_address(escrow.contract_address, wager.contract_address);
    escrow.fund_wager(wager_id, 0.try_into().unwrap(), amount);
}

#[test]
#[should_panic(expected: ('Amount must be positive',))]
fn test_fund_wager_zero_amount() {
    let (wager, escrow, strk_dispatcher) = setup();

    let wager_id = 1_u64;
    let amount = 0_u256;

    // Attempt to fund wager with zero amount
    start_cheat_caller_address(escrow.contract_address, wager.contract_address);
    escrow.fund_wager(wager_id, OWNER(), amount);
}

#[test]
fn test_incremental_funding() {
    let (wager, escrow, strk_dispatcher) = setup();

    let deposit_amount = 100_u256;
    let first_funding = 20_u256;
    let second_funding = 30_u256;
    let wager_id = 1_u64;

    // Approve escrow to spend
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.approve(escrow.contract_address, deposit_amount);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Deposit to wallet
    start_cheat_caller_address(escrow.contract_address, wager.contract_address);
    escrow.deposit_to_wallet(OWNER(), deposit_amount);

    // First funding
    escrow.fund_wager(wager_id, OWNER(), first_funding);

    let mid_user_balance = escrow.get_balance(OWNER());
    let mid_wager_stake = escrow.get_wager_stake(wager_id);
    assert(mid_user_balance == deposit_amount - first_funding, 'wrong mid user balance');
    assert(mid_wager_stake == first_funding, 'wrong mid wager stake');

    // Second funding
    escrow.fund_wager(wager_id, OWNER(), second_funding);

    let final_user_balance = escrow.get_balance(OWNER());
    let final_wager_stake = escrow.get_wager_stake(wager_id);
    stop_cheat_caller_address(escrow.contract_address);

    assert(
        final_user_balance == deposit_amount - first_funding - second_funding,
        'wrong final user balance'
    );
    assert(final_wager_stake == first_funding + second_funding, 'wrong final wager stake');
}

#[test]
fn test_get_wager_stake() {
    let (wager, escrow, strk_dispatcher) = setup();

    let wager_id = 1_u64;
    let amount = 50_u256;
    let deposit_amount = 100_u256;

    // Owner deposits
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.approve(escrow.contract_address, deposit_amount);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Deposit to wallet and fund wager
    start_cheat_caller_address(escrow.contract_address, wager.contract_address);
    escrow.deposit_to_wallet(OWNER(), deposit_amount);
    escrow.fund_wager(wager_id, OWNER(), amount);

    // Get wager stake
    let stake = escrow.get_wager_stake(wager_id);
    stop_cheat_caller_address(escrow.contract_address);

    assert(stake == amount, 'wrong wager stake');
}

#[test]
#[should_panic(expected: ('Caller is missing role',))]
fn test_get_wager_stake_unauthorized() {
    let (wager, escrow, strk_dispatcher) = setup();

    let wager_id = 1_u64;

    // Attempt to get wager stake from unauthorized address
    start_cheat_caller_address(escrow.contract_address, BOB());
    escrow.get_wager_stake(wager_id);
}

#[test]
fn test_deposit_fund_withdraw_flow() {
    let (wager, escrow, strk_dispatcher) = setup();

    let deposit_amount = 100_u256;
    let wager_amount = 50_u256;
    let withdraw_amount = 25_u256;
    let wager_id = 1_u64;

    // Approve escrow to spend
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.approve(escrow.contract_address, deposit_amount);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Deposit to wallet
    start_cheat_caller_address(escrow.contract_address, wager.contract_address);
    escrow.deposit_to_wallet(OWNER(), deposit_amount);

    // Fund wager
    escrow.fund_wager(wager_id, OWNER(), wager_amount);

    // Withdraw some funds
    escrow.withdraw_from_wallet(OWNER(), withdraw_amount);

    // Check final balances
    let final_user_balance = escrow.get_balance(OWNER());
    let wager_stake = escrow.get_wager_stake(wager_id);
    let escrow_balance = strk_dispatcher.balance_of(escrow.contract_address);
    stop_cheat_caller_address(escrow.contract_address);

    assert(
        final_user_balance == deposit_amount - wager_amount - withdraw_amount, 'wrong user balance'
    );
    assert(wager_stake == wager_amount, 'wrong wager stake');
    assert(escrow_balance == deposit_amount - withdraw_amount, 'wrong escrow balance');
}

#[test]
fn test_max_u64_wager_id() {
    let (wager, escrow, strk_dispatcher) = setup();

    let deposit_amount = 100_u256;
    let wager_amount = 50_u256;
    let wager_id = 18446744073709551615_u64; // Max u64 value

    // Approve escrow to spend
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.approve(escrow.contract_address, deposit_amount);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Deposit to wallet
    start_cheat_caller_address(escrow.contract_address, wager.contract_address);
    escrow.deposit_to_wallet(OWNER(), deposit_amount);

    // Fund wager with max u64 ID
    escrow.fund_wager(wager_id, OWNER(), wager_amount);

    // Check stake
    let wager_stake = escrow.get_wager_stake(wager_id);
    stop_cheat_caller_address(escrow.contract_address);

    assert(wager_stake == wager_amount, 'wrong wager stake');
}
