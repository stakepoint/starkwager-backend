use starknet::ContractAddress;
use starknet::{testing, contract_address_const, get_caller_address};

use contracts::wager::wager::StrkWager;
use contracts::wager::types::{Category, Mode};
use contracts::wager::interface::{IStrkWagerDispatcher, IStrkWagerDispatcherTrait};
use contracts::escrow::interface::IEscrowDispatcherTrait;
use contracts::tests::utils::{deploy_wager, create_wager, deploy_mock_erc20, deploy_escrow, OWNER};
use openzeppelin::token::erc20::interface::IERC20DispatcherTrait;

use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, spy_events, EventSpyAssertionsTrait
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
fn test_create_wager_success() {
    create_wager(3000, 2000);
}

#[test]
#[should_panic(expected: 'Insufficient balance')]
fn test_create_wager_insufficient_balance() {
    create_wager(2000, 2200);
}

#[test]
fn test_fund_wallet_success() {
    // Deploy contracts
    let (wager, wager_address) = deploy_wager();
    let (escrow, strk_dispatcher) = deploy_escrow(wager_address);

    // Configure wager with escrow
    wager.set_escrow_address(escrow.contract_address);

    let amount = 50_u256;
    let owner = OWNER();

    // Approve tokens from OWNER for escrow
    start_cheat_caller_address(strk_dispatcher.contract_address, owner);
    strk_dispatcher.approve(escrow.contract_address, amount);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Set OWNER as caller for wager contract
    start_cheat_caller_address(wager.contract_address, owner);
    wager.fund_wallet(amount);
    stop_cheat_caller_address(wager.contract_address);
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
    let (wager, wager_address) = deploy_wager();

    // Deploy escrow - using the correct signature without arguments
    let (escrow, strk_dispatcher) = deploy_escrow(wager_address);

    // Set escrow address
    wager.set_escrow_address(escrow.contract_address);

    // Test with zero amount - should panic
    wager.fund_wallet(0_u256);
}

#[test]
#[should_panic(expected: ('ERC20: insufficient allowance',))]
fn test_fund_wallet_without_approval() {
    let (wager, wager_address) = deploy_wager();
    let (escrow, strk_dispatcher) = deploy_escrow(wager_address);

    wager.set_escrow_address(escrow.contract_address);

    // Try to fund without any token approval
    start_cheat_caller_address(wager.contract_address, OWNER());
    wager.fund_wallet(50_u256);
    stop_cheat_caller_address(wager.contract_address);
}


#[test]
fn test_join_wager_success() {
    let (wager, wager_address) = deploy_wager();
    let (escrow, strk_dispatcher) = deploy_escrow(wager_address);
    let mut spy = spy_events();

    // Configure wager with escrow
    wager.set_escrow_address(escrow.contract_address);

    // Create a wager
    let stake = 100_u256;
    let wager_id = create_wager(stake, stake);

    // Approve tokens from OWNER for escrow
    let owner = OWNER();
    start_cheat_caller_address(strk_dispatcher.contract_address, owner);
    strk_dispatcher.approve(escrow.contract_address, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Fund the wallet of the participant
    start_cheat_caller_address(wager.contract_address, owner);
    wager.fund_wallet(stake);
    stop_cheat_caller_address(wager.contract_address);

    // Join the wager
    start_cheat_caller_address(wager.contract_address, owner);
    wager.join_wager(wager_id);
    stop_cheat_caller_address(wager.contract_address);

    let participants = wager.get_wager_participants(wager_id);
    let mut found = false;
    for participant_address in participants {
        if participant_address == @owner {
            found = true;
            break;
        }
    };
    assert!(found, "Participant should be added to the wager");

    spy
        .assert_emitted(
            @array![
                (
                    wager.contract_address,
                    StrkWager::Event::WagerJoined(
                        StrkWager::WagerJoinedEvent { wager_id, participant: owner }
                    )
                )
            ]
        );
}


#[test]
#[should_panic(expected: ('Wager is already resolved',))]
fn test_join_wager_resolved() {
    let (wager, wager_address) = deploy_wager();
    let (escrow, strk_dispatcher) = deploy_escrow(wager_address);

    // Configure wager with escrow
    wager.set_escrow_address(escrow.contract_address);

    // Create a wager
    let stake = 100_u256;
    let wager_id = create_wager(stake, stake);

    // Resolve the wager
    let owner = OWNER();
    wager.resolve_wager(wager_id, owner);

    start_cheat_caller_address(wager.contract_address, owner);
    wager.join_wager(wager_id);
    stop_cheat_caller_address(wager.contract_address);
}


#[test]
#[should_panic(expected: 'Insufficient balance to join wager')]
fn test_join_wager_insufficient_balance() {
    // Deploy contracts
    let (wager, wager_address) = deploy_wager();
    let (escrow, strk_dispatcher) = deploy_escrow(wager_address);

    // Configure wager with escrow
    wager.set_escrow_address(escrow.contract_address);

    // Create a wager
    let stake = 100_u256;
    let deposit = 50_u256;
    let wager_id = create_wager(deposit, stake);

    let owner = OWNER();
    start_cheat_caller_address(wager.contract_address, owner);
    wager.join_wager(wager_id);
    stop_cheat_caller_address(wager.contract_address);
}
