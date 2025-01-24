use starknet::ContractAddress;
use starknet::testing::set_caller_address;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use contracts::escrow::interface::{IEscrowDispatcher, IEscrowDispatcherTrait};
use contracts::tests::utils::{deploy_mock_erc20, OWNER, BOB};
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address,
};

fn set_wager_caller(escrow_address: ContractAddress) {
    let mock_wager_address = contract_address_const::<0x123>();
    set_caller_address(mock_wager_address);
}

#[test]
fn test_deposit_to_wallet() {
    let (escrow, strk_dispatcher) = deploy_escrow();
    set_wager_caller(escrow.contract_address);

    let amount = 50_u256;

    // approve escrow to spend
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.approve(escrow.contract_address, amount);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // deposit to wallet
    escrow.deposit_to_wallet(OWNER(), amount);

    assert(strk_dispatcher.balance_of(escrow.contract_address) == amount, 'wrong amount');
    assert(escrow.get_balance(OWNER()) == amount, 'wrong balance');
}

#[test]
#[should_panic(expected = "Invalid address")]
fn test_deposit_to_wallet_zero_address() {
    let (escrow, _) = deploy_escrow();
    set_wager_caller(escrow.contract_address);

    // deposit to wallet with zero address
    escrow.deposit_to_wallet(0.try_into().unwrap(), 50_u256);
}

#[test]
fn test_withdraw_from_wallet() {
    let (escrow, strk_dispatcher) = deploy_escrow();
    set_wager_caller(escrow.contract_address);

    let initial_balance = 1000_u256;
    let withdrawal_amount = 500_u256;

    // approve escrow to spend
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.approve(escrow.contract_address, initial_balance);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // deposit to wallet
    escrow.deposit_to_wallet(OWNER(), initial_balance);

    // withdraw from wallet
    escrow.withdraw_from_wallet(OWNER(), withdrawal_amount);

    let final_balance = escrow.get_balance(OWNER());
    assert(final_balance == initial_balance - withdrawal_amount, 'wrong balance');
}

#[test]
#[should_panic(expected = "Invalid address")]
fn test_withdraw_from_wallet_zero_address() {
    let (escrow, _) = deploy_escrow();
    set_wager_caller(escrow.contract_address);

    // withdraw from wallet with zero address
    escrow.withdraw_from_wallet(0.try_into().unwrap(), 500_u256);
}

#[test]
#[should_panic(expected = "Insufficient funds")]
fn test_withdraw_from_wallet_not_enough_balance() {
    let (escrow, strk_dispatcher) = deploy_escrow();
    set_wager_caller(escrow.contract_address);

    let initial_balance = 100_u256;
    let withdrawal_amount = 500_u256;

    // approve escrow to spend
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.approve(escrow.contract_address, initial_balance);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // deposit to wallet
    escrow.deposit_to_wallet(OWNER(), initial_balance);

    // try to withdraw more than available balance
    escrow.withdraw_from_wallet(OWNER(), withdrawal_amount);
}

#[test]
#[should_panic(expected = "Amount must be positive")]
fn test_amount_must_be_positive() {
    let (escrow, strk_dispatcher) = deploy_escrow();
    set_wager_caller(escrow.contract_address);

    let amount = 0_u256;

    // approve escrow to spend
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.approve(escrow.contract_address, amount);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // deposit to wallet with zero amount
    escrow.deposit_to_wallet(OWNER(), amount);
    assert(escrow.get_balance(OWNER()) > amount, 'amount must be positive');
}

#[test]
#[should_panic(expected = "Caller is missing role")]
fn test_unauthorized_access() {
    let (escrow, _) = deploy_escrow();

    // Try to call deposit_to_wallet without setting wager caller
    escrow.deposit_to_wallet(OWNER(), 50_u256);
}
