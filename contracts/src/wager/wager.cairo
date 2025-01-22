#[starknet::contract]
pub mod StrkWager {
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map,
    };
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use core::num::traits::Zero;
    use core::option::OptionTrait;

    use contracts::wager::interface::IStrkWager;
    use contracts::wager::types::{Wager, Category, Mode};
    use contracts::escrow::interface::{IEscrowDispatcher, IEscrowDispatcherTrait};

    #[storage]
    struct Storage {
        escrow: IEscrowDispatcher,
        wager_count: u64,
        wagers: Map<u64, Wager>,
        wager_participants: Map<u64, Map<u64, ContractAddress>>, // wager_id -> idx -> participants
        wager_participants_count: Map<u64, u64>, // wager_id -> count
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        WagerCreated: WagerCreated,
        WagerJoined: WagerJoined,
    }

    #[derive(Drop, starknet::Event)]
    pub struct WagerCreated {
        wager_id: u64,
        creator: ContractAddress,
        stake: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct WagerJoined {
        wager_id: u64,
        participant: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, escrow_address: ContractAddress) {
        self.escrow.write(IEscrowDispatcher { contract_address: escrow_address });
        
        // Grant WAGER_ROLE to this contract
        self.escrow.read().grant_wager_role(get_contract_address());
    }

    #[abi(embed_v0)]
    impl StrkWagerImpl of IStrkWager<ContractState> {
        fn fund_wallet(ref self: ContractState, amount: u256) {
            let caller = get_caller_address();
            self.escrow.read().deposit_to_wallet(caller, amount);
        }

        fn withdraw_from_wallet(ref self: ContractState, amount: u256) {
            let caller = get_caller_address();
            self.escrow.read().withdraw_from_wallet(caller, amount);
        }

        fn get_balance(self: @ContractState, address: ContractAddress) -> u256 {
            self.escrow.read().get_balance(address)
        }

        fn create_wager(
            ref self: ContractState,
            category: Category,
            title: ByteArray,
            terms: ByteArray,
            stake: u256
        ) -> u64 {
            let caller = get_caller_address();
            assert(stake > 0, 'Stake must be positive');
            assert(self.get_balance(caller) >= stake, 'Insufficient balance');

            let wager_id = self.wager_count.read() + 1;
            self.wager_count.write(wager_id);

            let wager = Wager {
                wager_id,
                category,
                title,
                terms,
                creator: caller,
                stake,
                resolved: false,
                winner: Default::default(),
                mode: Mode::HeadToHead,
            };

            self.wagers.write(wager_id, wager);
            self.wager_participants.entry(wager_id).write(0, caller);
            self.wager_participants_count.write(wager_id, 1);

            self.emit(WagerCreated { wager_id, creator: caller, stake });

            wager_id
        }

        fn join_wager(ref self: ContractState, wager_id: u64) {
            let caller = get_caller_address();
            let mut wager = self.wagers.read(wager_id);
            assert(!wager.resolved, 'Wager already resolved');

            let participants_count = self.wager_participants_count.read(wager_id);
            assert(participants_count < 2, 'Wager is full');

            assert(self.get_balance(caller) >= wager.stake, 'Insufficient balance');

            self.wager_participants.entry(wager_id).write(participants_count, caller);
            self.wager_participants_count.write(wager_id, participants_count + 1);

            self.emit(WagerJoined { wager_id, participant: caller });
        }

        fn get_wager(self: @ContractState, wager_id: u64) -> Wager {
            self.wagers.read(wager_id)
        }

        fn get_wager_participants(self: @ContractState, wager_id: u64) -> Span<ContractAddress> {
            let count = self.wager_participants_count.read(wager_id);
            let mut participants = ArrayTrait::new();
            let mut i = 0;
            loop {
                if i >= count {
                    break;
                }
                participants.append(self.wager_participants.entry(wager_id).read(i));
                i += 1;
            };
            participants.span()
        }
    }

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn assert_only_participant(self: @ContractState, wager_id: u64, address: ContractAddress) {
            let participants = self.get_wager_participants(wager_id);
            let mut is_participant = false;
            let mut i = 0;
            loop {
                if i >= participants.len() {
                    break;
                }
                if participants[i] == address {
                    is_participant = true;
                    break;
                }
                i += 1;
            };
            assert(is_participant, 'Not a wager participant');
        }
    }
}

