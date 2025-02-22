use starknet::ContractAddress;
use starknet::{contract_address_const, get_caller_address};

use contracts::wager::wager::StrkWager;
use contracts::wager::types::{Category, Mode};
use contracts::wager::interface::{IStrkWagerDispatcher, IStrkWagerDispatcherTrait};
use contracts::escrow::interface::IEscrowDispatcherTrait;
use contracts::tests::utils::{OWNER, ADMIN, BOB, setup, create_wager};
use openzeppelin::token::erc20::interface::IERC20DispatcherTrait;

use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, spy_events, EventSpyAssertionsTrait,
};


#[test]
#[should_panic(expected: 'Caller is missing role')]
fn test_set_escrow_address_fail() {
    let (_wager, _escrow, _strk_dispatcher) = setup();

    let new_address = contract_address_const::<'new_address'>();
    start_cheat_caller_address(wager.contract_address, new_address);
    wager.set_escrow_address(new_address);
    stop_cheat_caller_address(wager.contract_address);
}

#[test]
fn test_set_escrow_address() {
    let (wager, escrow, strk_dispatcher) = setup();

    let mut spy = spy_events();

    let new_address = contract_address_const::<'new_address'>();
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(new_address);
    stop_cheat_caller_address(wager.contract_address);
    spy
        .assert_emitted(
            @array![
                (
                    wager.contract_address,
                    StrkWager::Event::EscrowAddressUpdated(
                        StrkWager::EscrowAddressEvent {
                            old_address: contract_address_const::<
                                0,
                            >(), // Assuming initial address is zero
                            new_address: new_address,
                        },
                    ),
                ),
            ],
        );

    let updated_address: ContractAddress = wager.get_escrow_address();

    assert_eq!(updated_address, new_address);
}

#[test]
#[should_panic(expected: ('Invalid address',))]
fn test_set_escrow_address_zero_address_fails() {
    let (wager, escrow, strk_dispatcher) = setup();

    let zero_address: ContractAddress = contract_address_const::<0>();

    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(zero_address);
    stop_cheat_caller_address(wager.contract_address);
}

#[test]
fn test_get_escrow_address() {
    let (wager, escrow, strk_dispatcher) = setup();

    let first_address = contract_address_const::<'new_address'>();

    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(first_address);
    stop_cheat_caller_address(wager.contract_address);
    let initial_address: ContractAddress = wager.get_escrow_address();

    // Check if the initial address is as expected
    assert!(initial_address == first_address, "Initial escrow address is not being returned");

    let second_address = contract_address_const::<'second_address'>();
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(second_address);
    stop_cheat_caller_address(wager.contract_address);
    let final_address: ContractAddress = wager.get_escrow_address();

    // Check if the updated address is as expected
    assert!(final_address == second_address, "The function did not return the updated address");
}

#[test]
fn test_create_wager_success() {
    let (wager, escrow, strk_dispatcher) = setup();

    let mut spy = spy_events();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    create_wager(wager, escrow, strk_dispatcher, 3000, 2000);
}

#[test]
#[should_panic(expected: 'Insufficient balance')]
fn test_create_wager_insufficient_balance() {
    let (wager, escrow, strk_dispatcher) = setup();

    let mut spy = spy_events();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);
    create_wager(wager, escrow, strk_dispatcher, 2000, 2200);
}

#[test]
fn test_fund_wallet_success() {
    // Deploy contracts
    let (wager, escrow, strk_dispatcher) = setup();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);
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
    let (wager, escrow, strk_dispatcher) = setup();

    // Try to fund wallet without escrow configured
    wager.fund_wallet(100_u256);
}

#[test]
#[should_panic(expected: ('Amount must be positive',))]
fn test_fund_wallet_zero_amount() {
    let (wager, escrow, strk_dispatcher) = setup();

    // Set escrow address
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    // Test with zero amount - should panic
    wager.fund_wallet(0_u256);
}

#[test]
#[should_panic(expected: ('ERC20: insufficient allowance',))]
fn test_fund_wallet_without_approval() {
    let (wager, escrow, strk_dispatcher) = setup();

    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    // Try to fund without any token approval
    start_cheat_caller_address(wager.contract_address, OWNER());
    wager.fund_wallet(50_u256);
    stop_cheat_caller_address(wager.contract_address);
}


#[test]
fn test_join_wager_success() {
    let (wager, escrow, strk_dispatcher) = setup();

    let mut spy = spy_events();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    // Create a wager
    let stake = 100_u256;
    let wager_id = create_wager(wager, escrow, strk_dispatcher, stake, stake);

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
                        StrkWager::WagerJoinedEvent { wager_id, participant: owner },
                    ),
                ),
            ],
        );
}

#[test]
#[should_panic(expected: ('Insufficient balance',))]
fn test_join_wager_insufficient_balance() {
    // Deploy contracts
    let (wager, escrow, strk_dispatcher) = setup();
    let bob = BOB();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    // Create a wager
    let stake = 100_u256;
    let deposit = 20_u256; // Insufficient deposit
    let wager_id = create_wager(wager, escrow, strk_dispatcher, stake, stake);

    // Mint tokens for BOB
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.transfer(bob, deposit);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // BOB approves tokens
    start_cheat_caller_address(strk_dispatcher.contract_address, bob);
    strk_dispatcher.approve(escrow.contract_address, deposit);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Fund wallet with insufficient amount
    start_cheat_caller_address(wager.contract_address, bob);
    wager.fund_wallet(deposit);

    // Attempt to join the wager (should panic)
    wager.join_wager(wager_id);
    stop_cheat_caller_address(wager.contract_address);
}


#[test]
#[should_panic(expected: ('Wager is already resolved',))]
fn test_join_wager_resolved() {
    let (wager, escrow, strk_dispatcher) = setup();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    // Create a wager
    let stake = 100_u256;
    let wager_id = create_wager(wager, escrow, strk_dispatcher, stake, stake);

    // Resolve the wager
    let owner = OWNER();
    wager.resolve_wager(wager_id, owner);

    start_cheat_caller_address(wager.contract_address, owner);
    wager.join_wager(wager_id);
    stop_cheat_caller_address(wager.contract_address);
}


#[test]
fn test_get_wager() {
    let (wager, escrow, strk_dispatcher) = setup();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    // Create a wager
    let stake = 1000_u256;
    let deposit = 2000_u256;
    let wager_id = create_wager(wager, escrow, strk_dispatcher, deposit, stake);

    let retrieved_wager = wager.get_wager(wager_id);

    assert!(retrieved_wager.wager_id == wager_id, "Incorrect wager ID");
    assert!(retrieved_wager.category == Category::Sports, "Incorrect category");
    assert!(retrieved_wager.title == "My Wager", "Incorrect title");
    assert!(retrieved_wager.terms == "My terms", "Incorrect terms");
    assert!(retrieved_wager.creator == OWNER(), "Incorrect creator");
    assert!(retrieved_wager.stake == stake, "Incorrect stake");
    assert!(!retrieved_wager.resolved, "Wager should not be resolved");
    assert!(retrieved_wager.mode == Mode::HeadToHead, "Incorrect mode");
}
#[test]
fn test_is_wager_participant_true() {
    let (wager, escrow, strk_dispatcher) = setup();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    // Create a wager
    let stake = 100_u256;
    let wager_id = create_wager(wager, escrow, strk_dispatcher, stake, stake);

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

    // Check if the participant is registered
    let is_participant = wager.is_wager_participant(wager_id, owner);
    assert!(is_participant, "Caller should be a participant");
}

#[test]
fn test_is_wager_participant_false() {
    let (wager, escrow, strk_dispatcher) = setup();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    // Create a wager
    let stake = 100_u256;
    let wager_id = create_wager(wager, escrow, strk_dispatcher, stake, stake);

    // Check if a non-participant is registered
    let non_participant = BOB();
    let is_participant = wager.is_wager_participant(wager_id, non_participant);
    assert!(!is_participant, "Caller should not be a participant");
}

#[test]
fn test_is_wager_participant_invalid_wager() {
    let (wager, escrow, strk_dispatcher) = setup();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    // Check if a caller is registered in a non-existent wager
    let invalid_wager_id = 999; // Non-existent wager ID
    let caller = OWNER();
    let is_participant = wager.is_wager_participant(invalid_wager_id, caller);
    assert!(!is_participant, "Caller should not be a participant in a non-existent wager");
}
