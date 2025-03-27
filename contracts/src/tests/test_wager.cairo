use starknet::ContractAddress;
use starknet::{testing, contract_address_const, get_caller_address};

use contracts::wager::wager::StrkWager;
use contracts::wager::types::{Category, Mode, Claim, WagerState};
use contracts::wager::interface::{IStrkWagerDispatcher, IStrkWagerDispatcherTrait};
use contracts::escrow::interface::IEscrowDispatcherTrait;
use contracts::tests::utils::{OWNER, ADMIN, ALICE, BOB, setup, create_wager};
use openzeppelin::token::erc20::interface::IERC20DispatcherTrait;

use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, spy_events, EventSpyAssertionsTrait
};


#[test]
#[should_panic(expected: 'Caller is missing role')]
fn test_set_escrow_address_fail() {
    let (wager, escrow, strk_dispatcher) = setup();

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
fn test_create_wager_success_with_in_app_wallet_balance() {
    let (wager, escrow, strk_dispatcher) = setup();

    let mut spy = spy_events();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    create_wager(wager, escrow, strk_dispatcher, 3000, 2000);
}

#[test]
fn test_create_wager_success_with_external_wallet_balance() {
    let (wager, escrow, strk_dispatcher) = setup();

    let mut spy = spy_events();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);
    // user have less deposite than required for stake, but still has enough balance on his external
    // wallet
    create_wager(wager, escrow, strk_dispatcher, 2000, 2200);
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

    // transfer all funds to another account so OWNER has inssuficient balance on external wallet
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher
        .transfer(contract_address_const::<'any-address'>(), strk_dispatcher.balance_of(OWNER()));
    stop_cheat_caller_address(strk_dispatcher.contract_address);

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
fn test_join_wager_success_with_in_app_wallet_balance() {
    let (wager, escrow, strk_dispatcher) = setup();

    let mut spy = spy_events();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    // Create a wager
    let stake = 100_u256;
    let claim = Claim::Yes;
    let wager_id = create_wager(wager, escrow, strk_dispatcher, stake, stake);

    let owner = OWNER();
    let bob = BOB();

    // Mint tokens for BOB
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.transfer(bob, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // BOB approves tokens
    start_cheat_caller_address(strk_dispatcher.contract_address, bob);
    strk_dispatcher.approve(escrow.contract_address, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Fund the wallet of the participant
    start_cheat_caller_address(wager.contract_address, bob);
    wager.fund_wallet(stake);
    stop_cheat_caller_address(wager.contract_address);

    // Join the wager
    start_cheat_caller_address(wager.contract_address, bob);
    wager.join_wager(wager_id, claim);
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
                        StrkWager::WagerJoinedEvent { wager_id, participant: bob }
                    )
                )
            ]
        );
}

#[test]
fn test_join_wager_success_with_external_wallet_balance() {
    let (wager, escrow, strk_dispatcher) = setup();
    let claim = Claim::No;

    let mut spy = spy_events();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    // Create a wager
    let stake = 100_u256;
    let deposit = stake - 10;
    let wager_id = create_wager(wager, escrow, strk_dispatcher, deposit, stake);

    let owner = OWNER();
    let bob = BOB();
    let claim = Claim::No;

    // Mint tokens for BOB
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.transfer(bob, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // BOB approves tokens
    start_cheat_caller_address(strk_dispatcher.contract_address, bob);
    strk_dispatcher.approve(escrow.contract_address, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Fund the in-app wallet of the participant (not enough)
    start_cheat_caller_address(wager.contract_address, bob);
    wager.fund_wallet(deposit);
    stop_cheat_caller_address(wager.contract_address);

    // approve spending from external wallet
    start_cheat_caller_address(strk_dispatcher.contract_address, bob);
    strk_dispatcher.approve(escrow.contract_address, deposit);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Join the wager
    start_cheat_caller_address(wager.contract_address, bob);
    wager.join_wager(wager_id, claim);
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
                        StrkWager::WagerJoinedEvent { wager_id, participant: bob }
                    )
                )
            ]
        );
}

#[test]
#[should_panic(expected: ('Insufficient balance',))]
fn test_join_wager_insufficient_balance() {
    // Deploy contracts
    let (wager, escrow, strk_dispatcher) = setup();
    let bob = BOB();
    let claim = Claim::No;

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    // Create a wager
    let stake = 100_u256;
    let deposit = 20_u256; // Insufficient deposit
    let wager_id = create_wager(wager, escrow, strk_dispatcher, deposit, stake);

    // Mint tokens for BOB (not enough)
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
    wager.join_wager(wager_id, claim);
    stop_cheat_caller_address(wager.contract_address);
}


#[test]
#[should_panic(expected: ('Wager is already resolved',))]
fn test_join_wager_resolved() {
    let (wager, escrow, strk_dispatcher) = setup();
    let claim = Claim::No;

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
    wager.join_wager(wager_id, claim);
    stop_cheat_caller_address(wager.contract_address);
}


#[test]
fn test_get_wager_ok() {
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
    assert!(retrieved_wager.state != WagerState::Resolved, "Wager should not be resolved");
    assert!(retrieved_wager.mode == Mode::HeadToHead, "Incorrect mode");
}

#[test]
fn test_wager_withdraw_from_wallet_success() {
    let (wager, escrow, strk_dispatcher) = setup();
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    let amount = 50_u256;
    let owner = OWNER();
    let initial_balance = strk_dispatcher.balance_of(owner);
    // Approve tokens from OWNER for escrow
    start_cheat_caller_address(strk_dispatcher.contract_address, owner);
    strk_dispatcher.approve(escrow.contract_address, amount);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Set OWNER as caller for wager contract
    start_cheat_caller_address(wager.contract_address, owner);
    wager.fund_wallet(amount);
    let remaining_balance = initial_balance - amount;
    assert(strk_dispatcher.balance_of(owner) == remaining_balance, 'FUNDING FAILED.');
    wager.withdraw_from_wallet(amount);
    assert(strk_dispatcher.balance_of(owner) == initial_balance, 'WITHDRAWAL FAILED');
    stop_cheat_caller_address(wager.contract_address);
}

#[test]
#[should_panic(expected: ('Head-to-head wager full',))]
fn test_join_wager_head_to_head_full() {
    let (wager, escrow, strk_dispatcher) = setup();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    // Create a wager
    let stake = 100_u256;
    let wager_id = create_wager(wager, escrow, strk_dispatcher, stake, stake);

    let bob = BOB();
    let claim = Claim::No;
    // Mint tokens for BOB and approve
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.transfer(bob, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // BOB approves tokens and funds wallet
    start_cheat_caller_address(strk_dispatcher.contract_address, bob);
    strk_dispatcher.approve(escrow.contract_address, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    start_cheat_caller_address(wager.contract_address, bob);
    wager.fund_wallet(stake);
    wager.join_wager(wager_id, claim);
    stop_cheat_caller_address(wager.contract_address);

    // Try to join with a third participant - should fail
    let alice = ALICE();
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.transfer(alice, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Alice approves tokens and funds wallet
    start_cheat_caller_address(strk_dispatcher.contract_address, alice);
    strk_dispatcher.approve(escrow.contract_address, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    start_cheat_caller_address(wager.contract_address, alice);
    wager.fund_wallet(stake);
    wager.join_wager(wager_id, claim); // Should panic here
    stop_cheat_caller_address(wager.contract_address);
}

#[test]
fn test_is_wager_participant() {
    let (wager, escrow, strk_dispatcher) = setup();

    let mut spy = spy_events();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    // Create a wager
    let stake = 100_u256;
    let wager_id = create_wager(wager, escrow, strk_dispatcher, stake, stake);
    let claim = Claim::No;

    let owner = OWNER();
    let bob = BOB();

    // Mint tokens for BOB
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.transfer(bob, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // BOB approves tokens
    start_cheat_caller_address(strk_dispatcher.contract_address, bob);
    strk_dispatcher.approve(escrow.contract_address, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Fund the wallet of the participant
    start_cheat_caller_address(wager.contract_address, bob);
    wager.fund_wallet(stake);
    stop_cheat_caller_address(wager.contract_address);

    // Join the wager
    start_cheat_caller_address(wager.contract_address, bob);
    wager.join_wager(wager_id, claim);
    stop_cheat_caller_address(wager.contract_address);

    assert(wager.is_wager_participant(wager_id, owner), 'owner is a participant');
    assert(wager.is_wager_participant(wager_id, bob), 'bob is a participant');
    assert(!wager.is_wager_participant(wager_id, ALICE()), 'alice is non participant');
}

#[test]
fn test_join_wager_with_claim() {
    let (wager, escrow, strk_dispatcher) = setup();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    // Create a wager
    let stake = 100_u256;
    let wager_id = create_wager(wager, escrow, strk_dispatcher, stake, stake);
    let claim = Claim::No;

    let owner = OWNER();
    let bob = BOB();
    // Mint tokens for BOB
    start_cheat_caller_address(strk_dispatcher.contract_address, owner);
    strk_dispatcher.transfer(bob, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // BOB approves tokens
    start_cheat_caller_address(strk_dispatcher.contract_address, bob);
    strk_dispatcher.approve(escrow.contract_address, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Fund the wallet of the participant
    start_cheat_caller_address(wager.contract_address, bob);
    wager.fund_wallet(stake);
    stop_cheat_caller_address(wager.contract_address);

    // Join the wager
    start_cheat_caller_address(wager.contract_address, bob);
    wager.join_wager(wager_id, claim);
    stop_cheat_caller_address(wager.contract_address);

    assert(wager.get_wager_participant_claim(wager_id, bob) == claim, 'incorrect claim');
}

#[test]
fn test_create_wager_with_claim() {
    let (wager, escrow, strk_dispatcher) = setup();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    // Create a wager
    let stake = 100_u256;
    let wager_id = create_wager(wager, escrow, strk_dispatcher, stake, stake);
    let claim = Claim::Yes;

    let owner = OWNER();

    // check owner claim
    assert(wager.get_wager_participant_claim(wager_id, owner) == claim, 'incorrect claim');
}

#[test]
fn test_fund_wager_for_create_and_join_wager() {
    let (wager, escrow, strk_dispatcher) = setup();
    let claim = Claim::No;

    let mut spy = spy_events();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    let balance_before = wager.get_balance(OWNER());

    // Create a wager
    start_cheat_caller_address(wager.contract_address, OWNER());
    let stake = 100_u256;
    let wager_id = create_wager(wager, escrow, strk_dispatcher, stake, stake);

    assert(escrow.get_wager_stake(wager_id) == stake, 'wrong total stake');
    stop_cheat_caller_address(wager.contract_address);

    let owner = OWNER();
    let bob = BOB();

    // Mint tokens for BOB
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.transfer(bob, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // BOB approves tokens
    start_cheat_caller_address(strk_dispatcher.contract_address, bob);
    strk_dispatcher.approve(escrow.contract_address, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Fund the wallet of the participant
    start_cheat_caller_address(wager.contract_address, bob);
    wager.fund_wallet(stake);
    stop_cheat_caller_address(wager.contract_address);

    let bob_balance_before = wager.get_balance(bob);

    // Join the wager
    start_cheat_caller_address(wager.contract_address, bob);
    wager.join_wager(wager_id, claim);
    stop_cheat_caller_address(wager.contract_address);

    assert(escrow.get_wager_stake(wager_id) == stake * 2, 'wrong total stake');
}

#[test]
#[should_panic(expected: ('Already a participant',))]
fn test_join_wager_if_already_a_participant() {
    let (wager, escrow, strk_dispatcher) = setup();

    let mut spy = spy_events();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    // Create a wager
    let stake = 100_u256;
    let claim = Claim::Yes;
    let wager_id = create_wager(wager, escrow, strk_dispatcher, stake, stake);

    let owner = OWNER();
    let bob = BOB();

    // Mint tokens for BOB
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.transfer(bob, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // BOB approves tokens
    start_cheat_caller_address(strk_dispatcher.contract_address, bob);
    strk_dispatcher.approve(escrow.contract_address, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Fund the wallet of the participant
    start_cheat_caller_address(wager.contract_address, bob);
    wager.fund_wallet(stake);
    stop_cheat_caller_address(wager.contract_address);

    // Join the wager
    start_cheat_caller_address(wager.contract_address, owner);
    wager.join_wager(wager_id, claim);
    wager.join_wager(wager_id, claim);
    stop_cheat_caller_address(wager.contract_address);
}

#[test]
fn test_wager_state_transitions() {
    // Set up the test environment
    let (wager, escrow, strk_dispatcher) = setup();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    // 1. Create a wager and verify Pending state
    let stake = 1000_u256;
    let deposit = 2000_u256;
    let wager_id = create_wager(wager, escrow, strk_dispatcher, deposit, stake);

    let created_wager = wager.get_wager(wager_id);
    assert!(
        created_wager.state == WagerState::Pending,
        "Wager should be in Pending state after creation"
    );

    // 2. Have another user join the wager and verify Active state
    let participant = BOB();

    // Fund the participant
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.transfer(participant, deposit);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Approve escrow to spend tokens
    start_cheat_caller_address(strk_dispatcher.contract_address, participant);
    strk_dispatcher.approve(escrow.contract_address, deposit);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Join the wager
    start_cheat_caller_address(wager.contract_address, participant);
    wager.join_wager(wager_id, Claim::Yes);
    stop_cheat_caller_address(wager.contract_address);

    let active_wager = wager.get_wager(wager_id);
    assert!(
        active_wager.state == WagerState::Active, "Wager should be in Active state after joining"
    );

    // 3. Resolve the wager and verify Resolved state
    start_cheat_caller_address(wager.contract_address, OWNER());
    wager.resolve_wager(wager_id, OWNER());
    stop_cheat_caller_address(wager.contract_address);

    let resolved_wager = wager.get_wager(wager_id);
    assert!(
        resolved_wager.state == WagerState::Resolved,
        "Wager should be in Resolved state after resolution"
    );
    assert!(resolved_wager.winner == OWNER(), "Winner should be correctly set");
}

#[test]
#[should_panic(expected: ('Wager is already resolved',))]
fn test_cannot_join_resolved_wager() {
    // Set up the test environment
    let (wager, escrow, strk_dispatcher) = setup();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    // 1. Create a wager
    let stake = 1000_u256;
    let deposit = 2000_u256;
    let wager_id = create_wager(wager, escrow, strk_dispatcher, deposit, stake);

    // 2. Have BOB join the wager
    let participant = BOB();

    // Fund the participant
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.transfer(participant, deposit);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Approve escrow to spend tokens
    start_cheat_caller_address(strk_dispatcher.contract_address, participant);
    strk_dispatcher.approve(escrow.contract_address, deposit);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Join the wager
    start_cheat_caller_address(wager.contract_address, participant);
    wager.join_wager(wager_id, Claim::Yes);
    stop_cheat_caller_address(wager.contract_address);

    // 3. Resolve the wager
    start_cheat_caller_address(wager.contract_address, OWNER());
    wager.resolve_wager(wager_id, OWNER());
    stop_cheat_caller_address(wager.contract_address);

    // 4. Attempt to have another user join the already resolved wager - should fail
    let third_participant = ALICE();

    // Fund the third participant
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.transfer(third_participant, deposit);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Approve escrow to spend tokens
    start_cheat_caller_address(strk_dispatcher.contract_address, third_participant);
    strk_dispatcher.approve(escrow.contract_address, deposit);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Try to join the resolved wager - this should panic
    start_cheat_caller_address(wager.contract_address, third_participant);
    wager.join_wager(wager_id, Claim::Yes);
    stop_cheat_caller_address(wager.contract_address);
}

#[test]
fn test_submit_outcome_pass() {
    // Deploy contracts
    let (wager, escrow, strk_dispatcher) = setup();
    let bob = BOB();

    let mut spy = spy_events();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    // Create a wager
    let stake = 100_u256;
    let deposit = 20_u256; // Insufficient deposit
    let wager_id = create_wager(wager, escrow, strk_dispatcher, deposit, stake);

    start_cheat_caller_address(wager.contract_address, bob);

    let vote = true;
    wager.submit_outcome(wager_id, vote);

    assert(wager.has_outcome_submitted(wager_id, bob), 'outcome not registered');

    spy
        .assert_emitted(
            @array![
                (
                    wager.contract_address,
                    StrkWager::Event::OutcomeSubmitted(
                        StrkWager::OutcomeSubmittedEvent { wager_id, participant: bob, vote }
                    )
                )
            ]
        );
}

#[test]
#[should_panic(expected: 'Participant already submitted')]
fn test_submit_outcome_fail_double_submit() {
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
    let wager_id = create_wager(wager, escrow, strk_dispatcher, deposit, stake);

    start_cheat_caller_address(wager.contract_address, bob);

    wager.submit_outcome(wager_id, true);

    wager.submit_outcome(wager_id, true);
}

#[test]
#[should_panic(expected: 'Wager is already resolved')]
fn test_submit_outcome_fail_wager_resolved() {
    // Set up the test environment
    let (wager, escrow, strk_dispatcher) = setup();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    // 1. Create a wager
    let stake = 1000_u256;
    let deposit = 2000_u256;
    let wager_id = create_wager(wager, escrow, strk_dispatcher, deposit, stake);

    // 2. Have BOB join the wager
    let participant = BOB();

    // Fund the participant
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.transfer(participant, deposit);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Approve escrow to spend tokens
    start_cheat_caller_address(strk_dispatcher.contract_address, participant);
    strk_dispatcher.approve(escrow.contract_address, deposit);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Join the wager
    start_cheat_caller_address(wager.contract_address, participant);
    wager.join_wager(wager_id, Claim::Yes);
    stop_cheat_caller_address(wager.contract_address);

    // 3. Resolve the wager
    start_cheat_caller_address(wager.contract_address, OWNER());
    wager.resolve_wager(wager_id, OWNER());
    stop_cheat_caller_address(wager.contract_address);

    // 4. Attempt to have another user join the already resolved wager - should fail
    let third_participant = ALICE();

    // Fund the third participant
    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.transfer(third_participant, deposit);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Approve escrow to spend tokens
    start_cheat_caller_address(strk_dispatcher.contract_address, third_participant);
    strk_dispatcher.approve(escrow.contract_address, deposit);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Try to join the resolved wager - this should panic
    start_cheat_caller_address(wager.contract_address, third_participant);
    wager.submit_outcome(wager_id, true);
    stop_cheat_caller_address(strk_dispatcher.contract_address);
}

#[test]
#[should_panic(expected: 'Not a participant')]
fn test_submit_outcome_fail_not_a_participant() {
    let (wager, escrow, strk_dispatcher) = setup();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    // Create a wager
    let stake = 100_u256;
    let claim = Claim::Yes;
    let wager_id = create_wager(wager, escrow, strk_dispatcher, stake, stake);

    let owner = OWNER();
    let bob = BOB();

    // Mint tokens for BOB
    start_cheat_caller_address(strk_dispatcher.contract_address, owner);
    strk_dispatcher.transfer(bob, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // BOB approves tokens
    start_cheat_caller_address(strk_dispatcher.contract_address, bob);
    strk_dispatcher.approve(escrow.contract_address, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    // Fund the wallet of the participant
    start_cheat_caller_address(wager.contract_address, bob);
    wager.fund_wallet(stake);
    stop_cheat_caller_address(wager.contract_address);

    // Try to submit outcome - should panic
    start_cheat_caller_address(wager.contract_address, owner);
    wager.submit_outcome(wager_id, true);
    stop_cheat_caller_address(wager.contract_address);
}

#[test]
#[should_panic(expected: 'Wager does not exist')]
fn test_submit_outcome_fail_wager_no_exists() {
    let (wager, _, _) = setup();

    wager.submit_outcome(1, true);
}

#[test]
fn test_resolve_wager_based_on_outcome() {
    let (wager, escrow, strk_dispatcher) = setup();

    let mut spy = spy_events();

    let stake = 100_u256;
    let deposit = 100_u256;

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.approve(escrow.contract_address, 500_u256);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    start_cheat_caller_address(wager.contract_address, OWNER());
    wager.fund_wallet(deposit);
    stop_cheat_caller_address(wager.contract_address);

    // Create the wager
    let title = "My Wager";
    let terms = "My terms";
    let category = Category::Sports;
    let mode = Mode::HeadToHead;
    let claim = Claim::No;

    let alice = ALICE();
    let bob = BOB();
    let final_outcome = Claim::Yes;

    start_cheat_caller_address(strk_dispatcher.contract_address, OWNER());
    strk_dispatcher.transfer(alice, stake);
    strk_dispatcher.transfer(bob, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    start_cheat_caller_address(strk_dispatcher.contract_address, alice);
    strk_dispatcher.approve(escrow.contract_address, stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    start_cheat_caller_address(wager.contract_address, alice);
    wager.fund_wallet(stake);
    stop_cheat_caller_address(wager.contract_address);

    start_cheat_caller_address(wager.contract_address, OWNER());
    let wager_id = wager.create_wager(category, title.clone(), terms.clone(), stake, mode,claim );
    stop_cheat_caller_address(wager.contract_address);

    start_cheat_caller_address(wager.contract_address, alice);
    wager.join_wager(wager_id, final_outcome);
    stop_cheat_caller_address(wager.contract_address);


    start_cheat_caller_address(wager.contract_address, OWNER());
    wager.resolve_wager_based_on_outcome(wager_id, final_outcome);
    stop_cheat_caller_address(wager.contract_address);

    let resolved_wager = wager.get_wager(wager_id);
    assert_eq!(resolved_wager.winner, alice, "alice_should_winner");
    assert(resolved_wager.state == WagerState::Resolved, 'Wager_should_marked_resolved');
}
