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
        escrow.contract_address, wager.contract_address,
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
        escrow.contract_address, wager.contract_address,
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
        escrow.contract_address, wager.contract_address,
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
        escrow.contract_address, wager.contract_address,
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

