#[starknet::contract]
pub mod StrkWager {
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map,
    };

    use contracts::wager::interface::IStrkWager;
    use contracts::wager::types::{Wager};

    #[storage]
    struct Storage {
        wagers: Map<u64, Wager>,
        wager_participants: Map<u64, Map<u64, ContractAddress>>, // wager_id -> idx -> participants
        wager_participants_count: Map<u64, u64>, // wager_id -> count
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {}

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[abi(embed_v0)]
    impl StrkWagerImpl of IStrkWager<ContractState> {
        //TODO
        fn fund_wallet(ref self: ContractState, amount: u256) {}

        //TODO
        fn withdraw_from_wallet(ref self: ContractState, amount: u256) {}

        //TODO
        fn get_balance(ref self: ContractState) -> u256 {}

        //TODO
        fn create_wager(
            ref self: ContractState,
            category: Category,
            title: ByteArray,
            terms: ByteArray,
            stake: u256
        ) -> u64 {}

        //TODO
        fn join_wager(ref self: ContractState, wager_id: u64) {}

        //TODO
        fn get_wager(ref self: ContractState, wager_id: u64) -> Wager {}
    }
}
