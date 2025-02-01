use starknet::ContractAddress;
use starknet::{testing, contract_address_const};

use contracts::wager::wager::StrkWager;
use contracts::wager::types::{Mode, Category};

use contracts::wager::interface::{IStrkWagerDispatcher, IStrkWagerDispatcherTrait};
use contracts::escrow::interface::IEscrowDispatcherTrait;
use contracts::tests::utils::{deploy_wager, OWNER, deploy_escrow};
use openzeppelin::token::erc20::interface::IERC20DispatcherTrait;

use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, spy_events, EventSpyAssertionsTrait, cheat_caller_address, CheatSpan
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

fn create_wager(deposit: u256, stake: u256) {
    let (wager, wager_contract) = deploy_wager();
    let (escrow, strk_dispatcher) = deploy_escrow();
    let creator = OWNER();
    let mut spy = spy_events();

    wager.set_escrow_address(escrow.contract_address);
    cheat_caller_address(strk_dispatcher.contract_address, creator, CheatSpan::TargetCalls(1));
    strk_dispatcher.approve(escrow.contract_address, deposit);
    escrow.deposit_to_wallet(creator, deposit);

    assert(strk_dispatcher.balance_of(escrow.contract_address) == deposit, 'wrong amount');
    assert(escrow.get_balance(creator) == deposit, 'wrong balance');

    let title = "My Wager";
    let terms = "My terms";
    let category = Category::Sports;
    let mode = Mode::HeadToHead;

    cheat_caller_address(wager_contract, creator, CheatSpan::TargetCalls(1));
    println!("Creator's balance: {}", escrow.get_balance(creator));
    println!("Creator's stake: {}", stake);
    let wager_id = wager.create_wager(category, title.clone(), terms.clone(), stake, mode);
    let expected_event = StrkWager::Event::WagerCreated(
        StrkWager::WagerCreatedEvent { wager_id, category, title, terms, creator, stake, mode }
    );

    spy.assert_emitted(@array![(wager_contract, expected_event)]);
}
