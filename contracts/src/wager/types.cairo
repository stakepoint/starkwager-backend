use starknet::ContractAddress;

#[derive(Drop, Serde, starknet::Store, Clone)]
pub struct Wager {
    pub wager_id: u64,
    pub category: Category,
    pub title: ByteArray,
    pub terms: ByteArray,
    pub creator: ContractAddress,
    pub stake: u256,
    pub winner: ContractAddress,
    pub mode: Mode,
    pub state: WagerState,
    pub resolution_time: u64,
    pub created_at: u64,
}

#[derive(Drop, Copy, Serde, PartialEq, starknet::Store, Default)]
pub enum Category {
    #[default]
    Sports,
    Politics,
    Entertainment,
    Crypto,
    Stocks,
    Games,
    Technology,
    Health,
    Others,
}

#[derive(Drop, Copy, Serde, PartialEq, starknet::Store, Default)]
pub enum Mode {
    #[default]
    HeadToHead,
    Group,
}

#[derive(Drop, Copy, Serde, PartialEq, starknet::Store, Default)]
pub enum Claim {
    #[default]
    No,
    Yes,
}

#[derive(Drop, Copy, Serde, PartialEq, starknet::Store, Default, Debug)]
pub enum WagerState {
    #[default]
    Pending,
    Active,
    VotingPhase,
    Resolved,
    Cancelled
}
