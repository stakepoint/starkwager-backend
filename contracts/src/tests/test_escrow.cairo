use starknet::ContractAddress;
use starknet::{testing, contract_address_const};

use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

use contracts::escrow::interface::{IEscrowDispatcher, IEscrowDispatcherTrait};
use contracts::tests::utils::{deploy_mock_erc20, OWNER, BOB, deploy_escrow};


use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, spy_events, EventSpyAssertionsTrait,
};


#[test]
fn test_set_escrow_address() {
    let (escrow, _) = deploy_escrow();

    let new_address = contract_address_const::<'new_address'>();

    start_cheat_caller_address(escrow.contract_address, OWNER());
    escrow.set_escrow_address(new_address);
    stop_cheat_caller_address(escrow.contract_address);

    let updated_address: ContractAddress = escrow.get_escrow_address();

    assert_eq!(updated_address, new_address);
}


#[test]
#[should_panic(expected: ('Invalid address',))]
fn test_set_escrow_address_zero_address_fails() {
    // Arrange
    let (escrow, _) = deploy_escrow();
    let zero_address: ContractAddress = starknet::contract_address_const::<0>();

    // Act & Assert (should panic)
    start_cheat_caller_address(escrow.contract_address, OWNER());
    escrow.set_escrow_address(zero_address);
    stop_cheat_caller_address(escrow.contract_address);
}

#[test]
fn test_get_escrow_address() {
    let (escrow, _) = deploy_escrow();
    let first_address = contract_address_const::<'new_address'>();

    escrow.set_escrow_address(first_address);
    let initial_address: ContractAddress = escrow.get_escrow_address();

    // Check if the initial address is as expected
    assert!(
        initial_address == first_address, "Initial escrow address is not being
        returned"
    );

    let second_address = contract_address_const::<'second_address'>();
    escrow.set_escrow_address(second_address);
    let final_address: ContractAddress = escrow.get_escrow_address();

    // Check if the updated address is as expected
    assert!(final_address == second_address, "The function did not return the updated address");
}

#[test]
fn test_deposit_to_wallet() {
    let (escrow, strk_dispatcher) = deploy_escrow();

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
#[should_panic(expected: ('Invalid address',))]
fn test_deposit_to_wallet_zero_address() {
    let (escrow, _) = deploy_escrow();

    // deposit to wallet
    escrow.deposit_to_wallet(0.try_into().unwrap(), 50_u256);
}

#[test]
fn test_withdraw_from_wallet() {
    let (escrow, strk_dispatcher) = deploy_escrow();

    let initial_balance = 1000_u256;
    let withdrawal_amount = 500_u256;
    //let amount = 50_u256;

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
#[should_panic(expected: ('Invalid address',))]
fn test_withdraw_from_wallet_zero_address() {
    let (escrow, _) = deploy_escrow();

    // withdraw from wallet
    escrow.withdraw_from_wallet(0.try_into().unwrap(), 500_u256);
}

#[test]
#[should_panic(expected: ('Insufficient funds',))]
fn test_withdraw_from_wallet_not_enough_balance() {
    let (escrow, strk_dispatcher) = deploy_escrow();

    let initial_balance = 100_u256;
    let withdrawal_amount = 500_u256;

    // approve escrow to spend
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.approve(escrow.contract_address, initial_balance);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // deposit to wallet
    escrow.deposit_to_wallet(OWNER(), initial_balance);

    escrow.withdraw_from_wallet(OWNER(), withdrawal_amount);
}

#[test]
#[should_panic(expected: ('Amount must be positive',))]
fn test_amount_must_be_positive() {
    let (escrow, strk_dispatcher) = deploy_escrow();

    let amount = 0_u256;

    // approve escrow to spend
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.approve(escrow.contract_address, amount);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // deposit to wallet
    escrow.deposit_to_wallet(OWNER(), amount);
    assert(escrow.get_balance(OWNER()) > amount, 'amount must be positive');
}

