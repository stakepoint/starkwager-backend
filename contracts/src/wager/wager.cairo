#[starknet::contract]
pub mod StrkWager {
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    use contracts::wager::interface::IStrkWager;

    #[storage]
    struct Storage {
    }

    #[abi(embed_v0)]
    impl StrkWagerImpl of IStrkWager<ContractState> {
    }
}