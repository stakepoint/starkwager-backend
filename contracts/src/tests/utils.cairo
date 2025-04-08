use starknet::{ContractAddress, get_block_timestamp};

use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, spy_events, EventSpyAssertionsTrait, cheat_caller_address, CheatSpan,
};

use contracts::wager::wager::StrkWager;
use contracts::wager::types::{Mode, Category, Claim, WagerState};

use contracts::escrow::interface::{IEscrowDispatcher, IEscrowDispatcherTrait};
use contracts::wager::interface::{IStrkWagerDispatcher, IStrkWagerDispatcherTrait};

pub fn OWNER() -> ContractAddress {
    'owner'.try_into().unwrap()
}

pub fn ADMIN() -> ContractAddress {
    'admin'.try_into().unwrap()
}

pub fn WAGER_ADDRESS() -> ContractAddress {
    'wager'.try_into().unwrap()
}

pub fn ALICE() -> ContractAddress {
    'alice'.try_into().unwrap()
}

pub fn BOB() -> ContractAddress {
    'bob'.try_into().unwrap()
}

pub fn deploy_mock_erc20() -> IERC20Dispatcher {
    let contract = declare("MyToken").unwrap().contract_class();
    let mut calldata = array![];
    OWNER().serialize(ref calldata);

    let (contract_address, _) = contract.deploy(@calldata).unwrap();

    IERC20Dispatcher { contract_address }
}

pub fn deploy_escrow(
    wager_address: ContractAddress, strk_dispatcher: IERC20Dispatcher
) -> (IEscrowDispatcher, IERC20Dispatcher) {
    let contract = declare("Escrow").unwrap().contract_class();

    let mut calldata = array![];
    strk_dispatcher.serialize(ref calldata);
    wager_address.serialize(ref calldata);

    let (contract_address, _) = contract.deploy(@calldata).unwrap();

    (IEscrowDispatcher { contract_address }, strk_dispatcher)
}

pub fn deploy_wager(
    admin_address: ContractAddress, strk_dispatcher: IERC20Dispatcher
) -> (IStrkWagerDispatcher, ContractAddress) {
    let contract = declare("StrkWager").unwrap().contract_class();
    let mut calldata = array![];
    let strk_address = strk_dispatcher.contract_address;
    admin_address.serialize(ref calldata);
    strk_address.serialize(ref calldata);

    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    let dispatcher = IStrkWagerDispatcher { contract_address };

    (dispatcher, contract_address)
}

pub fn setup() -> (IStrkWagerDispatcher, IEscrowDispatcher, IERC20Dispatcher) {
    let strk_dispatcher = deploy_mock_erc20();

    let (wager, wager_contract) = deploy_wager(ADMIN(), strk_dispatcher);
    let (escrow, strk_dispatcher) = deploy_escrow(wager_contract, strk_dispatcher);

    (wager, escrow, strk_dispatcher)
}

pub fn create_head_to_head_wager(
    wager: IStrkWagerDispatcher,
    escrow: IEscrowDispatcher,
    strk_dispatcher: IERC20Dispatcher,
    deposit: u256,
    stake: u256,
    resolution_time: u64,
) -> u64 {
    let creator = OWNER();
    let mut spy = spy_events();

    // approve enough allowance
    cheat_caller_address(strk_dispatcher.contract_address, creator, CheatSpan::TargetCalls(1));
    strk_dispatcher.approve(escrow.contract_address, deposit + stake);
    stop_cheat_caller_address(strk_dispatcher.contract_address);

    start_cheat_caller_address(wager.contract_address, creator); // Simulate Wager Contract
    wager.fund_wallet(deposit);
    stop_cheat_caller_address(wager.contract_address);

    // Create the wager
    let title = "My Wager";
    let terms = "My terms";
    let category = Category::Sports;
    let mode = Mode::HeadToHead;
    let claim = Claim::Yes;
    let state = WagerState::Pending;

    // Get timestamp just before creation for event assertion
    let expected_created_at = get_block_timestamp();

    cheat_caller_address(wager.contract_address, creator, CheatSpan::TargetCalls(1));
    let wager_id = wager
        .create_wager(category, title.clone(), terms.clone(), stake, mode, claim, resolution_time);
    stop_cheat_caller_address(wager.contract_address);

    spy
        .assert_emitted(
            @array![
                (
                    wager.contract_address,
                    StrkWager::Event::WagerCreated(
                        StrkWager::WagerCreatedEvent {
                            wager_id,
                            category,
                            title,
                            terms,
                            creator,
                            stake,
                            mode,
                            state,
                            resolution_time,
                            created_at: expected_created_at
                        }
                    )
                )
            ]
        );

    wager_id
}
