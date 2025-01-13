#[starknet::contract]
pub mod Escrow {
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map
    };
    use starknet::{ContractAddress, get_contract_address};

    use contracts::escrow::interface::IEscrow;

    #[storage]
    struct Storage {
        strk_dispatcher: IERC20Dispatcher,
        user_balance: Map::<ContractAddress, u256>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {}

    #[constructor]
    fn constructor(ref self: ContractState, strk_dispatcher: IERC20Dispatcher,) {
        self.strk_dispatcher.write(strk_dispatcher);
    }

    #[abi(embed_v0)]
    impl EscrowImpl of IEscrow<ContractState> {
        fn deposit_to_wallet(ref self: ContractState, user: ContractAddress, amount: u256) {
            let strk_dispatcher = self.strk_dispatcher.read();
            // transfers funds to escrow
            strk_dispatcher.transfer_from(user, get_contract_address(), amount);
            self.user_balance.entry(user).write(amount + self.get_balance(user));
        }

        fn get_balance(self: @ContractState, user: ContractAddress) -> u256 {
            self.user_balance.entry(user).read()
        }
    }
}
