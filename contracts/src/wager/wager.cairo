#[starknet::contract]
pub mod StrkWager {
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map,
    };

    use starknet::{ContractAddress, get_caller_address, contract_address_const};
    use core::num::traits::Zero;

    use contracts::escrow::interface::{IEscrowDispatcher, IEscrowDispatcherTrait};

    use contracts::wager::interface::IStrkWager;
    use contracts::wager::types::{Wager, Category, Mode};
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin_access::accesscontrol::{AccessControlComponent};

    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    #[abi(embed_v0)]
    impl AccessControlImpl =
        AccessControlComponent::AccessControlImpl<ContractState>;

    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        wager_count: u64,
        wagers: Map<u64, Wager>,
        wager_participants: Map<u64, Map<u64, ContractAddress>>, // wager_id -> idx -> participants
        wager_participants_count: Map<u64, u64>, // wager_id -> count
        escrow_address: ContractAddress,
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        EscrowAddressUpdated: EscrowAddressEvent,
        WagerCreated: WagerCreatedEvent,
        WagerJoined: WagerJoinedEvent,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
    }

    #[derive(Drop, starknet::Event)]
    pub struct EscrowAddressEvent {
        pub old_address: ContractAddress,
        pub new_address: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct WagerCreatedEvent {
        pub wager_id: u64,
        pub category: Category,
        pub title: ByteArray,
        pub terms: ByteArray,
        pub creator: ContractAddress,
        pub stake: u256,
        pub mode: Mode,
    }

    #[derive(Drop, starknet::Event)]
    pub struct WagerJoinedEvent {
        pub wager_id: u64,
        pub participant: ContractAddress,
    }

    const ADMIN_ROLE: felt252 = selector!("ADMIN_ROLE"); // Unique identifier for the role


    #[constructor]
    fn constructor(ref self: ContractState, admin_contract: ContractAddress) {
        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(ADMIN_ROLE, admin_contract);
    }

    #[abi(embed_v0)]
    impl StrkWagerImpl of IStrkWager<ContractState> {
        fn fund_wallet(ref self: ContractState, amount: u256) {
            // Validate amount
            assert(amount > 0, 'Amount must be positive');

            // Get caller address
            let caller = get_caller_address();
            assert(!caller.is_zero(), 'Invalid caller address');

            // Get escrow contract address and create dispatcher
            let escrow_address = self.escrow_address.read();
            assert(!escrow_address.is_zero(), 'Escrow not configured');

            let escrow_dispatcher = IEscrowDispatcher { contract_address: escrow_address };

            // Call deposit_to_wallet on escrow contract
            escrow_dispatcher.deposit_to_wallet(caller, amount);
        }

        //TODO
        fn withdraw_from_wallet(ref self: ContractState, amount: u256) {}

        fn get_balance(self: @ContractState, address: ContractAddress) -> u256 {
            let escrow_dispatcher = IEscrowDispatcher {
                contract_address: self.escrow_address.read()
            };
            escrow_dispatcher.get_balance(address)
        }

        fn create_wager(
            ref self: ContractState,
            category: Category,
            title: ByteArray,
            terms: ByteArray,
            stake: u256,
            mode: Mode
        ) -> u64 {
            let creator = get_caller_address();
            let creator_balance = self.get_balance(creator);

            assert(creator_balance >= stake, 'Insufficient balance');
            let wager_id = self.wager_count.read() + 1;

            let new_wager = Wager {
                wager_id,
                category,
                title: title.clone(),
                terms: terms.clone(),
                creator,
                stake,
                resolved: false,
                winner: contract_address_const::<0>(),
                mode
            };

            self.wagers.entry(wager_id).write(new_wager);
            self.wager_count.write(wager_id);
            let participant_id = self.wager_participants_count.entry(wager_id).read() + 1;
            self.wager_participants.entry(wager_id).entry(participant_id).write(creator);
            self.wager_participants_count.entry(wager_id).write(participant_id);

            self.emit(WagerCreatedEvent { wager_id, category, title, terms, creator, stake, mode });

            wager_id
        }


        fn join_wager(ref self: ContractState, wager_id: u64) {
            let wager = self.wagers.entry(wager_id).read();
            assert(!wager.resolved, 'Wager is already resolved');

            let caller = get_caller_address();
            println!("caller: {:?}", caller);
            let caller_balance = self.get_balance(caller);
            println!("caller_balance: {:?}", caller_balance);
            println!("wager stake: {:?}", wager.stake);
            assert(caller_balance >= wager.stake, 'Insufficient balance');

            let participant_id = self.wager_participants_count.entry(wager_id).read() + 1;
            self.wager_participants.entry(wager_id).entry(participant_id).write(caller);
            self.wager_participants_count.entry(wager_id).write(participant_id);

            self.emit(WagerJoinedEvent { wager_id, participant: caller });
        }

        fn get_wager(self: @ContractState, wager_id: u64) -> Wager {
            self.wagers.entry(wager_id).read()
        }


        fn get_wager_participants(self: @ContractState, wager_id: u64) -> Span<ContractAddress> {
            let participant_count = self.wager_participants_count.entry(wager_id).read();
            let mut participants = array![];
            let mut i = 1;

            while i <= participant_count {
                let participant = self.wager_participants.entry(wager_id).entry(i).read();
                participants.append(participant);
                i += 1;
            };

            participants.span()
        }

        fn get_escrow_address(self: @ContractState) -> ContractAddress {
            self.escrow_address.read()
        }
        fn set_escrow_address(ref self: ContractState, new_address: ContractAddress) {
            self.accesscontrol.assert_only_role(ADMIN_ROLE);
            assert(!new_address.is_zero(), 'Invalid address');

            let old_address = self.escrow_address.read();
            self.escrow_address.write(new_address);

            self.emit(EscrowAddressEvent { old_address: old_address, new_address: new_address });
        }

        fn resolve_wager(ref self: ContractState, wager_id: u64, winner: ContractAddress) {
            let mut wager = self.wagers.entry(wager_id).read();
            assert(!wager.resolved, 'Wager is already resolved');

            wager.resolved = true;
            wager.winner = winner;

            self.wagers.entry(wager_id).write(wager);
        }
    }

    #[generate_trait]
    pub impl InternalFunctions of InternalFunctionsTrait {
        //TODO
        fn _check_balance(self: @ContractState) -> bool {
            true
        }

        //TODO
        fn _fund_wager(self: @ContractState, wager_id: u64, amount: u256) {}
    }
}
