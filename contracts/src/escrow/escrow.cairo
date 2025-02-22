#[starknet::contract]
pub mod Escrow {
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map,
    };
    use starknet::{ContractAddress, get_contract_address};
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
        strk_dispatcher: IERC20Dispatcher,
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


    const WAGER_ROLE: felt252 = selector!("WAGER_ROLE"); // Unique identifier for the role

    #[constructor]
    fn constructor(
        ref self: ContractState, strk_dispatcher: IERC20Dispatcher, wager_contract: ContractAddress,
    ) {
        self.strk_dispatcher.write(strk_dispatcher);
        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(WAGER_ROLE, wager_contract);
    }

    #[abi(embed_v0)]
    impl EscrowImpl of IEscrow<ContractState> {
        fn deposit_to_wallet(ref self: ContractState, from: ContractAddress, amount: u256) {
            self.accesscontrol.assert_only_role(WAGER_ROLE);

            // Validate input
            assert(!from.is_zero(), 'Invalid address');
            assert(amount > 0, 'Amount must be positive');

            let strk_dispatcher = self.strk_dispatcher.read();

            // transfers funds to escrow
            assert(strk_dispatcher.balance_of(from) >= amount, 'Insufficient balance');
            self.user_balance.entry(from).write(amount + self.get_balance(from));
            strk_dispatcher.transfer_from(from, get_contract_address(), amount);
            self.emit(DepositEvent { from, amount });
        }

        fn withdraw_from_wallet(ref self: ContractState, to: ContractAddress, amount: u256) {
            self.accesscontrol.assert_only_role(WAGER_ROLE);
            let strk_dispatcher = self.strk_dispatcher.read();

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
            self.accesscontrol.assert_only_role(WAGER_ROLE);
            self.user_balance.entry(address).read()
        }

        //TODO
        fn fund_wager(self: @ContractState, wager_id: u64, amount: u256) {}
    }
}
