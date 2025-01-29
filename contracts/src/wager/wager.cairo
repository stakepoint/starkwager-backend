#[starknet::contract]
pub mod StrkWager {
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map,
    };

    use starknet::{ContractAddress, get_caller_address};

    use contracts::escrow::interface::{IEscrowDispatcher, IEscrowDispatcherTrait};

    use contracts::wager::interface::IStrkWager;
    use contracts::wager::types::{Wager, Category, Mode};

    #[storage]
    struct Storage {
        wager_count: u64,
        wagers: Map<u64, Wager>,
        wager_participants: Map<u64, Map<u64, ContractAddress>>, // wager_id -> idx -> participants
        wager_participants_count: Map<u64, u64>, // wager_id -> count
        escrow_address: ContractAddress,
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

        fn get_balance(self: @ContractState, address: ContractAddress) -> u256 {
            let escrow_dispatcher = IEscrowDispatcher {
                contract_address: self.escrow_address.read()
            };
            escrow_dispatcher.get_balance(address)
        }

        //TODO
        fn create_wager(
            ref self: ContractState,
            category: Category,
            title: ByteArray,
            terms: ByteArray,
            stake: u256
        ) -> u64 {
            0
        }

        //TODO
        fn join_wager(ref self: ContractState, wager_id: u64) {}

        //TODO
        fn get_wager(self: @ContractState, wager_id: u64) -> Wager {
            // search the storage for the `wager_id`.
            self.wagers.entry(wager_id).read()
        }

        //TODO
        fn get_wager_participants(self: @ContractState, wager_id: u64) -> Span<ContractAddress> {
            array![].span()
        }
    }
}
