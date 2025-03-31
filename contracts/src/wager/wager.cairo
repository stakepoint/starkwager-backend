#[starknet::contract]
pub mod StrkWager {
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map,
    };

    use starknet::{ContractAddress, get_caller_address, contract_address_const};
    use core::num::traits::Zero;

    use contracts::escrow::interface::{IEscrowDispatcher, IEscrowDispatcherTrait};

    use contracts::wager::interface::IStrkWager;
    use contracts::wager::types::{Wager, Category, Mode, Claim, WagerState};
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::access::accesscontrol::{AccessControlComponent};
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

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
        wagers: Map<u64, Wager>, // wager_id -> Wager
        wager_participants: Map<u64, Map<u64, ContractAddress>>, // wager_id -> idx -> participants
        wager_participants_mapping: Map<(u64, ContractAddress), bool>,
        wager_participants_claim: Map::<
            u64, Map<ContractAddress, Claim>,
        >, // wager_id -> participant -> Claim
        wager_outcome_votes: Map<(u64, ContractAddress), bool>, // wager_id -> participant -> vote
        wager_outcome_submitted: Map<
            (u64, ContractAddress), bool
        >, // wager_id -> participant ->  submitted
        claim: Claim,
        wager_participants_count: Map<u64, u64>, // wager_id -> count
        escrow_address: ContractAddress,
        strk_address: ContractAddress,
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
        WagerCancelled: WagerEventCancelled,
        OutcomeSubmitted: OutcomeSubmittedEvent,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        WagerResolvedEvent: WagerResolvedEvent,
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
        pub state: WagerState,
    }

    #[derive(Drop, starknet::Event)]
    pub struct WagerJoinedEvent {
        pub wager_id: u64,
        pub participant: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct WagerEventCancelled {
        pub wager_id: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct OutcomeSubmittedEvent {
        pub wager_id: u64,
        pub participant: ContractAddress,
        pub vote: bool,
    }

    #[derive(Drop, starknet::Event)]
    pub struct WagerResolvedEvent {
        pub wager_id: u64,
        pub winner: ContractAddress,
    }

    const ADMIN_ROLE: felt252 = selector!("ADMIN_ROLE"); // Unique identifier for the role


    #[constructor]
    fn constructor(
        ref self: ContractState, admin_contract: ContractAddress, strk_address: ContractAddress,
    ) {
        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(ADMIN_ROLE, admin_contract);
        self.strk_address.write(strk_address);
    }

    #[abi(embed_v0)]
    impl StrkWagerImpl of IStrkWager<ContractState> {
        fn fund_wallet(ref self: ContractState, amount: u256) {
            let escrow_dispatcher = self._escrow_dispatcher();

            // Validate amount
            assert(amount > 0, 'Amount must be positive');

            // Get caller address
            let caller = get_caller_address();
            assert(!caller.is_zero(), 'Invalid caller address');

            // Call deposit_to_wallet on escrow contract
            escrow_dispatcher.deposit_to_wallet(caller, amount);
        }

        fn withdraw_from_wallet(ref self: ContractState, amount: u256) {
            let to = get_caller_address();
            let escrow_dispatcher = self._escrow_dispatcher();

            escrow_dispatcher.withdraw_from_wallet(to, amount);
        }

        fn get_balance(self: @ContractState, address: ContractAddress) -> u256 {
            let escrow_dispatcher = self._escrow_dispatcher();
            escrow_dispatcher.get_balance(address)
        }

        fn create_wager(
            ref self: ContractState,
            category: Category,
            title: ByteArray,
            terms: ByteArray,
            stake: u256,
            mode: Mode,
            claim: Claim,
        ) -> u64 {
            assert(self._has_sufficient_balance(stake), 'Insufficient balance');

            let creator = get_caller_address();
            let wager_id = self.wager_count.read() + 1;
            let state = WagerState::Pending;
            let new_wager = Wager {
                wager_id,
                category,
                title: title.clone(),
                terms: terms.clone(),
                creator,
                stake,
                winner: contract_address_const::<0>(),
                mode,
                state,
            };

            self.wagers.entry(wager_id).write(new_wager);
            self.wager_count.write(wager_id);
            let participant_id = self.wager_participants_count.entry(wager_id).read() + 1;
            self.wager_participants.entry(wager_id).entry(participant_id).write(creator);
            self.wager_outcome_submitted.entry((wager_id, creator)).write(false);
            self.wager_participants_mapping.entry((wager_id, creator)).write(true);
            self.wager_participants_count.entry(wager_id).write(participant_id);
            self._submit_claim(wager_id, creator, claim);

            let in_app_balance = self.get_balance(creator);
            if in_app_balance < stake {
                self._top_up_in_app_wallet(stake, in_app_balance);
            }

            self._fund_wager(wager_id, stake);

            self
                .emit(
                    WagerCreatedEvent {
                        wager_id, category, title, terms, creator, stake, mode, state
                    }
                );

            wager_id
        }

        fn join_wager(ref self: ContractState, wager_id: u64, claim: Claim) {
            let mut wager = self.get_wager(wager_id);
            let caller = get_caller_address();

            assert(!wager.creator.is_zero(), 'Wager does not exist');
            assert(wager.state != WagerState::Resolved, 'Wager is already resolved');
            assert(wager.state != WagerState::Cancelled, 'Wager is cancelled');

            // Check if caller is already a participant
            assert(!self.is_wager_participant(wager_id, caller), 'Already a participant');

            if wager.mode == Mode::HeadToHead {
                assert(
                    self.wager_participants_count.entry(wager_id).read() == 1,
                    'Head-to-head wager full',
                );
            }
            assert(self._has_sufficient_balance(wager.stake), 'Insufficient balance');

            let participant_id = self.wager_participants_count.entry(wager_id).read() + 1;
            self.wager_participants.entry(wager_id).entry(participant_id).write(caller);
            self.wager_participants_mapping.entry((wager_id, caller)).write(true);
            self.wager_participants_count.entry(wager_id).write(participant_id);
            self._submit_claim(wager_id, caller, claim);

            let in_app_balance = self.get_balance(caller);
            if in_app_balance < wager.stake {
                self._top_up_in_app_wallet(wager.stake, in_app_balance);
            }

            self._fund_wager(wager_id, wager.stake);

            wager.state = WagerState::Active;
            self.wagers.entry(wager_id).write(wager);

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

        fn get_wager_participant_claim(
            self: @ContractState, wager_id: u64, participant: ContractAddress,
        ) -> Claim {
            self._get_participant_claim(wager_id, participant)
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
            self.accesscontrol.assert_only_role(ADMIN_ROLE);

            let mut wager = self.wagers.entry(wager_id).read();
            assert(wager.state != WagerState::Resolved, 'Wager is already resolved');
            assert(!wager.creator.is_zero(), 'Wager does not exist');

            assert(self.is_wager_participant(wager_id, winner), 'Winner is not a participant');

            wager.state = WagerState::Resolved;
            wager.winner = winner;

            self.wagers.entry(wager_id).write(wager);

            self.emit(WagerResolvedEvent { wager_id, winner });
        }

        fn cancel_wager(ref self: ContractState, wager_id: u64) {
            let mut wager = self.wagers.entry(wager_id).read();
            assert(wager.state != WagerState::Cancelled, 'Wager is already cancelled');
            let participants = self.wager_participants_count.entry(wager_id).read();
            assert(
                participants == 1, 'Wager cannot be cancelled'
            ); // 1 because the wager by default has the creator as a participant
            wager.state = WagerState::Cancelled;
            self.wagers.entry(wager_id).write(wager);
            self.emit(WagerEventCancelled { wager_id });
        }

        fn is_wager_participant(
            self: @ContractState, wager_id: u64, caller: ContractAddress,
        ) -> bool {
            self.wager_participants_mapping.entry((wager_id, caller)).read()
        }

        fn has_outcome_submitted(
            self: @ContractState, wager_id: u64, caller: ContractAddress
        ) -> bool {
            self.wager_outcome_submitted.entry((wager_id, caller)).read()
        }

        fn submit_outcome(ref self: ContractState, wager_id: u64, vote: bool) {
            let wager = self.get_wager(wager_id);
            let caller = get_caller_address();

            assert(!wager.creator.is_zero(), 'Wager does not exist');
            assert(wager.state != WagerState::Resolved, 'Wager is already resolved');

            // Check if caller is a participant
            assert(!self.is_wager_participant(wager_id, caller), 'Not a participant');

            assert(!self.has_outcome_submitted(wager_id, caller), 'Participant already submitted');

            self.wager_outcome_votes.entry((wager_id, caller)).write(vote);
            self.wager_outcome_submitted.entry((wager_id, caller)).write(true);

            self.emit(OutcomeSubmittedEvent { wager_id, participant: caller, vote });
        }

        fn resolve_wager_based_on_outcome(
            ref self: ContractState, wager_id: u64, final_outcome: Claim,
        ) {
            let mut wager = self.wagers.entry(wager_id).read();

            assert(wager.state != WagerState::Resolved, 'wager_is_already_resolved');

            match wager.mode {
                Mode::HeadToHead => {
                    let participant_count = self.wager_participants_count.entry(wager_id).read();
                    assert(participant_count > 0, 'wager_have_no_participants');

                    let mut winner = contract_address_const::<0>();
                    let mut i = 1;

                    while i <= participant_count {
                        let participant = self.wager_participants.entry(wager_id).entry(i).read();
                        let claim = self
                            .wager_participants_claim
                            .entry(wager_id)
                            .entry(participant)
                            .read();

                        if claim == final_outcome {
                            winner = participant;
                            break;
                        }
                        i += 1;
                    };

                    assert(!winner.is_zero(), 'no_matching_claim');
                    let updated_wager = Wager { state: WagerState::Resolved, winner, ..wager };

                    self.wagers.entry(wager_id).write(updated_wager);

                    // Emit an event for resolution
                    self.emit(WagerResolvedEvent { wager_id, winner });
                },
                Mode::Group => { assert(false, 'not_group_allow'); },
            }
        }

        fn check_resolution(self: @ContractState, wager_id: u64) -> Option<bool> {
        // Get the wager
        let wager = self.wagers.entry(wager_id).read();
        
        // Verify wager exists
        assert(!wager.creator.is_zero(), 'Wager does not exist');
        
        // Verify wager hasn't been resolved
        assert(wager.state != WagerState::Resolved, 'Wager already resolved');
        assert(wager.state != WagerState::Cancelled, 'Wager is cancelled');

        // Handle based on wager mode
        match wager.mode {
            Mode::HeadToHead => {
                // Check participant count (should be 2 for head-to-head)
                let participant_count = self.wager_participants_count.entry(wager_id).read();
                if participant_count != 2 {
                    return Option::None; // Not enough participants yet
                }

                // Get both participants
                let participant1 = self.wager_participants.entry(wager_id).entry(1).read();
                let participant2 = self.wager_participants.entry(wager_id).entry(2).read();

                // Check if both have submitted outcomes
                let submitted1 = self.wager_outcome_submitted.entry((wager_id, participant1)).read();
                let submitted2 = self.wager_outcome_submitted.entry((wager_id, participant2)).read();

                if !submitted1 || !submitted2 {
                    return Option::None; // Not all outcomes submitted
                }

                // Get the submitted outcomes
                let vote1 = self.wager_outcome_votes.entry((wager_id, participant1)).read();
                let vote2 = self.wager_outcome_votes.entry((wager_id, participant2)).read();

                // Check if they agree
                if vote1 == vote2 {
                    Option::Some(vote1) // Consensus reached, return the outcome
                } else {
                    Option::None // No consensus
                }
            },
            Mode::Group => {
                // For now, return None as group mode resolution isn't specified
                // Could be extended later with different consensus rules
                Option::None
            }
        }
    }
    }

    #[generate_trait]
    pub impl InternalFunctions of InternalFunctionsTrait {
        fn _has_sufficient_balance(ref self: ContractState, stake: u256) -> bool {
            let caller = get_caller_address();
            let in_app_balance = self.get_balance(caller);
            if in_app_balance >= stake {
                return true;
            }

            // Evaluating external wallet balance
            let strk_dispatcher = IERC20Dispatcher { contract_address: self.strk_address.read() };
            let external_balance = strk_dispatcher.balance_of(caller);
            if external_balance >= stake {
                return true;
            }

            if external_balance + in_app_balance >= stake {
                return true;
            }

            false
        }

        fn _fund_wager(self: @ContractState, wager_id: u64, amount: u256) {
            self._escrow_dispatcher().fund_wager(wager_id, get_caller_address(), amount);
        }

        fn _escrow_dispatcher(self: @ContractState) -> IEscrowDispatcher {
            let escrow_address = self.escrow_address.read();
            assert(!escrow_address.is_zero(), 'Escrow not configured');

            IEscrowDispatcher { contract_address: escrow_address }
        }

        fn _top_up_in_app_wallet(ref self: ContractState, stake: u256, in_app_balance: u256) {
            let top_up = stake - in_app_balance;
            self.fund_wallet(top_up);
        }

        fn _submit_claim(
            ref self: ContractState, wager_id: u64, participant: ContractAddress, claim: Claim,
        ) {
            self.wager_participants_claim.entry(wager_id).entry(participant).write(claim);
        }

        fn _get_participant_claim(
            self: @ContractState, wager_id: u64, participant: ContractAddress,
        ) -> Claim {
            self.wager_participants_claim.entry(wager_id).entry(participant).read()
        }
    }
}
