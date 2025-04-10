#[starknet::contract]
pub mod Escrow {
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map
    };
    use starknet::{ContractAddress, get_contract_address, get_caller_address};
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin_access::accesscontrol::{AccessControlComponent};
    use openzeppelin_access::ownable::OwnableComponent;

    use contracts::escrow::interface::IEscrow;
    use core::num::traits::Zero;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    #[abi(embed_v0)]
    impl AccessControlImpl =
        AccessControlComponent::AccessControlImpl<ContractState>;

    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        strk_address: ContractAddress,
        user_balance: Map::<ContractAddress, u256>,
        wager_stake: Map::<u64, u256>, // wager_id -> total stake
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Deposit: DepositEvent,
        Withdraw: WithdrawEvent,
        FundsDistributedEvent: FundsDistributedEvent,
        FundsRefundedEvent: FundsRefundedEvent,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
    }

    #[derive(Drop, starknet::Event)]
    pub struct DepositEvent {
        from: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct WithdrawEvent {
        to: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct FundsDistributedEvent {
        pub wager_id: u64,
        pub winner: ContractAddress,
        pub amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct FundsRefundedEvent {
        pub wager_id: u64,
        pub participant: ContractAddress,
        pub amount: u256,
    }


    const WAGER_ROLE: felt252 = selector!("WAGER_ROLE"); // Unique identifier for the role

    #[constructor]
    fn constructor(
        ref self: ContractState, strk_address: ContractAddress, wager_contract: ContractAddress
    ) {
        self.strk_address.write(strk_address);
        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(WAGER_ROLE, wager_contract);
    }

    #[abi(embed_v0)]
    impl EscrowImpl of IEscrow<ContractState> {
        fn deposit_to_wallet(ref self: ContractState, from: ContractAddress, amount: u256) {
            self.accesscontrol.assert_only_role(WAGER_ROLE);

            let strk_dispatcher = IERC20Dispatcher { contract_address: self.strk_address.read() };

            // Validate input
            assert(!from.is_zero(), 'Invalid address');
            assert(amount > 0, 'Amount must be positive');

            // transfers funds to escrow
            assert(strk_dispatcher.balance_of(from) >= amount, 'Insufficient balance');
            self.user_balance.entry(from).write(amount + self.get_balance(from));
            strk_dispatcher.transfer_from(from, get_contract_address(), amount);
            self.emit(DepositEvent { from, amount });
        }

        fn withdraw_from_wallet(ref self: ContractState, to: ContractAddress, amount: u256) {
            self.accesscontrol.assert_only_role(WAGER_ROLE);
            let strk_dispatcher = IERC20Dispatcher { contract_address: self.strk_address.read() };

            // Validate recipient address
            assert(!to.is_zero(), 'Invalid address');

            // checks if to address has enough funds
            assert(self.get_balance(to) >= amount, 'Insufficient funds');

            // update balance first to prevent reentrancy
            self.user_balance.entry(to).write(self.get_balance(to) - amount);

            // transfers funds from escrow
            strk_dispatcher.transfer(to, amount);
            self.emit(WithdrawEvent { to, amount });
        }

        fn get_balance(self: @ContractState, address: ContractAddress) -> u256 {
            self.user_balance.entry(address).read()
        }

        fn fund_wager(
            ref self: ContractState, wager_id: u64, address: ContractAddress, amount: u256
        ) {
            self.accesscontrol.assert_only_role(WAGER_ROLE);

            // Validate inputs
            assert(!address.is_zero(), 'Invalid address');
            assert(amount > 0, 'Amount must be positive');

            // Check if user has sufficient balance
            let user_balance = self.get_balance(address);
            assert(user_balance >= amount, 'Insufficient balance');

            // Update user balance first to prevent reentrancy
            self.user_balance.entry(address).write(user_balance - amount);

            // Update wager stake
            let current_stake = self.wager_stake.entry(wager_id).read();
            self.wager_stake.entry(wager_id).write(current_stake + amount);
        }

        fn get_wager_stake(self: @ContractState, wager_id: u64) -> u256 {
            self.wager_stake.entry(wager_id).read()
        }

        fn distribute_funds(ref self: ContractState, wager_id: u64, winner: ContractAddress) {
            self.accesscontrol.assert_only_role(WAGER_ROLE);

            // Validate inputs
            assert(!winner.is_zero(), 'Invalid winner address');

            // Get the total stake for this wager
            let total_stake = self.wager_stake.entry(wager_id).read();
            assert(total_stake > 0, 'No funds in wager');

            // Clear the wager stake first to prevent reentrancy
            self.wager_stake.entry(wager_id).write(0);

            // Update winner's balance
            let winner_balance = self.get_balance(winner);
            self.user_balance.entry(winner).write(winner_balance + total_stake);

            // Emit event for the distribution
            self.emit(FundsDistributedEvent { wager_id, winner, amount: total_stake });
        }

        fn refund_wager(
            ref self: ContractState, wager_id: u64, stake: u256, participants: Span<ContractAddress>
        ) {
            self.accesscontrol.assert_only_role(WAGER_ROLE);

            // Get the total stake for this wager
            let total_stake = self.wager_stake.entry(wager_id).read();
            assert(total_stake > 0, 'No funds in wager');

            // Clear the wager stake first to prevent reentrancy
            self.wager_stake.entry(wager_id).write(0);

            // Refund each participant their stake
            let mut refunded_amount: u256 = 0;
            let mut i = 0;
            let participants_len = participants.len();

            while i < participants_len {
                let participant = *participants.at(i);
                assert(!participant.is_zero(), 'Invalid participant');

                // Update participant's balance
                let participant_balance = self.get_balance(participant);
                self.user_balance.entry(participant).write(participant_balance + stake);

                // Track refunded amount
                refunded_amount += stake;

                // Emit event for each refund
                self.emit(FundsRefundedEvent { wager_id, participant, amount: stake });

                i += 1;
            };

            // Ensure all funds are accounted for
            assert(refunded_amount == total_stake, 'Refund amount mismatch');
        }
    }
}
