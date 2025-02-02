use starknet::ContractAddress;
use starknet::{testing, contract_address_const, get_caller_address};

use contracts::wager::wager::StrkWager;

use contracts::wager::interface::{IStrkWagerDispatcher, IStrkWagerDispatcherTrait};
use contracts::tests::utils::{deploy_wager, deploy_mock_erc20, deploy_escrow, OWNER};
use contracts::escrow::interface::{IEscrowDispatcher, IEscrowDispatcherTrait};

use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, spy_events, EventSpyAssertionsTrait,
};

#[test]
fn test_set_escrow_address() {
    let (wager, contract_address) = deploy_wager();
    let mut spy = spy_events();

    let new_address = contract_address_const::<'new_address'>();

    wager.set_escrow_address(new_address);
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    StrkWager::Event::EscrowAddressUpdated(
                        StrkWager::EscrowAddressEvent {
                            old_address: contract_address_const::<
                                0
                            >(), // Assuming initial address is zero
                            new_address: new_address
                        }
                    )
                )
            ]
        );

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

#[test]
#[should_panic(expected: ('Escrow not configured',))]
fn test_fund_wallet_no_escrow() {
    // Deploy wager without setting escrow
    let (wager, _) = deploy_wager();
    
    // Try to fund wallet without escrow configured
    wager.fund_wallet(100_u256);
}

#[test]
#[should_panic(expected: ('Amount must be positive',))]
fn test_fund_wallet_zero_amount() {
    // Deploy contracts
    let (wager, _) = deploy_wager();
    
    // Deploy escrow - using the correct signature without arguments
    let (escrow, strk_dispatcher) = deploy_escrow();
    
    // Set escrow address
    wager.set_escrow_address(escrow.contract_address);
    
    // Test with zero amount - should panic
    wager.fund_wallet(0_u256);
}