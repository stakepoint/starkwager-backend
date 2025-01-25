use starknet::ContractAddress;
use starknet::{testing, contract_address_const};

use contracts::wager::interface::{IStrkWagerDispatcher, IStrkWagerDispatcherTrait};
use contracts::tests::utils::{deploy_wager};

use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, spy_events, EventSpyAssertionsTrait,
};

#[test]
fn test_set_escrow_address() {
    let (wager, _) = deploy_wager();

    let new_address = contract_address_const::<'new_address'>();

    wager.set_escrow_address(new_address);

    let updated_address: ContractAddress = wager.get_escrow_address();

    assert_eq!(updated_address, new_address);
}

#[test]
#[should_panic(expected: ('Invalid address',))]
fn test_set_escrow_address_zero_address_fails() {
    let (wager, _) = deploy_wager();
    let zero_address: ContractAddress = contract_address_const::<0>();

    wager.set_escrow_address(zero_address);
}

#[test]
fn test_get_escrow_address() {
    let (wager, _) = deploy_wager();
    let first_address = contract_address_const::<'new_address'>();

    wager.set_escrow_address(first_address);
    let initial_address: ContractAddress = wager.get_escrow_address();

    // Check if the initial address is as expected
    assert!(initial_address == first_address, "Initial escrow address is not being returned");

    let second_address = contract_address_const::<'second_address'>();
    wager.set_escrow_address(second_address);
    let final_address: ContractAddress = wager.get_escrow_address();

    // Check if the updated address is as expected
    assert!(final_address == second_address, "The function did not return the updated address");
}
