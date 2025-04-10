use starknet::{ContractAddress, get_block_timestamp};
use contracts::escrow::interface::IEscrowDispatcherTrait;
use contracts::tests::utils::{ADMIN, setup, create_head_to_head_wager};
use contracts::wager::interface::{IStrkWagerDispatcherTrait};


use snforge_std::{start_cheat_caller_address, stop_cheat_caller_address,};

#[test]
#[should_panic(expected: ('Invalid winner address',))]
fn test_distribute_funds_invalid_winner_address() {
    let (wager, escrow, _) = setup();

    start_cheat_caller_address(escrow.contract_address, wager.contract_address);
    escrow.distribute_funds(1, 0.try_into().unwrap());
}

#[test]
#[should_panic(expected: ('No funds in wager',))]
fn test_distribute_funds_no_funds() {
    let (wager, escrow, _) = setup();

    start_cheat_caller_address(escrow.contract_address, wager.contract_address);
    escrow.distribute_funds(1, 1.try_into().unwrap());
}

#[test]
fn test_distribute_funds_ok() {
    let (wager, escrow, strk_dispatcher) = setup();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    let stake = 100_u256;
    let deposit = 100_u256;
    let resolution_time = get_block_timestamp() + 100;
    let wager_id = create_head_to_head_wager(
        wager, escrow, strk_dispatcher, deposit, stake, resolution_time
    );

    let john: ContractAddress = 'john'.try_into().unwrap();

    start_cheat_caller_address(escrow.contract_address, wager.contract_address);
    escrow.distribute_funds(wager_id, john);

    assert(escrow.get_balance(john) == stake, 'wrong balance');
    assert(escrow.get_wager_stake(wager_id) == 0, 'wrong wager stake');
}

#[test]
#[should_panic(expected: ('No funds in wager',))]
fn test_refund_wager_no_funds_in_wager() {
    let (wager, escrow, _) = setup();
    let john: ContractAddress = 'john'.try_into().unwrap();

    start_cheat_caller_address(escrow.contract_address, wager.contract_address);
    escrow.refund_wager(1, 0, array![john].span());
}

#[test]
#[should_panic(expected: ('Refund amount mismatch',))]
fn test_refund_wager_refund_mismatch() {
    let (wager, escrow, strk_dispatcher) = setup();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    let stake = 100_u256;
    let deposit = 100_u256;
    let resolution_time = get_block_timestamp() + 100;
    let wager_id = create_head_to_head_wager(
        wager, escrow, strk_dispatcher, deposit, stake, resolution_time
    );

    let john: ContractAddress = 'john'.try_into().unwrap();

    start_cheat_caller_address(escrow.contract_address, wager.contract_address);
    escrow.refund_wager(wager_id, 50, array![john].span());
}

#[test]
fn test_refund_wager_ok() {
    let (wager, escrow, strk_dispatcher) = setup();

    // Configure wager with escrow
    start_cheat_caller_address(wager.contract_address, ADMIN());
    wager.set_escrow_address(escrow.contract_address);
    stop_cheat_caller_address(wager.contract_address);

    let stake = 100_u256;
    let deposit = 100_u256;
    let resolution_time = get_block_timestamp() + 100;
    let wager_id = create_head_to_head_wager(
        wager, escrow, strk_dispatcher, deposit, stake, resolution_time
    );

    let john: ContractAddress = 'john'.try_into().unwrap();

    start_cheat_caller_address(escrow.contract_address, wager.contract_address);
    escrow.refund_wager(wager_id, stake, array![john].span());

    assert(escrow.get_balance(john) == stake, 'wrong balance');
    assert(escrow.get_wager_stake(wager_id) == 0, 'wrong wager stake');
}
