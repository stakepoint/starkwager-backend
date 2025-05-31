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

#[derive(Copy, Drop, Serde)]
pub struct Achievement {
    pub achievement_type: AchievementType,
    pub earned_at: u64,
    pub wager_id: u64,
}

#[derive(Copy, Drop, Serde, PartialEq)]
pub enum AchievementType {
    FirstWager, // Created first wager
    FirstWin, // Won first wager
    FirstJoin, // Joined first wager
    WinStreak5, // 5 consecutive wins
    WinStreak10, // 10 consecutive wins
    AccuratePrediction, // 80%+ accuracy over 10 wagers
    HighStaker, // Placed wager worth 1000+ STRK
    FrequentPlayer, // Participated in 50+ wagers
    WealthyWinner, // Won 10,000+ STRK total
    QuickWinner, // Won within first 24 hours of wager creation
}

#[derive(Copy, Drop, Serde)]
pub struct UserStats {
    pub total_wagers_created: u64,
    pub total_wagers_joined: u64,
    pub total_wins: u64,
    pub total_losses: u64,
    pub current_win_streak: u64,
    pub best_win_streak: u64,
    pub total_volume_wagered: u256,
    pub total_winnings: u256,
    pub accuracy_percentage: u64, // percentage (0-100)
}

impl AchievementTypeIntoFelt252 of Into<AchievementType, felt252> {
    fn into(self: AchievementType) -> felt252 {
        match self {
            AchievementType::FirstWager => 'FIRSTWAGER',
            AchievementType::FirstWin => 'FIRSTWIN',
            AchievementType::FirstJoin => 'FIRSTJOIN',
            AchievementType::WinStreak5 => 'WINSTREAK5',
            AchievementType::WinStreak10 => 'WINSTREAK10',
            AchievementType::AccuratePrediction => 'ACCURATEPREDICTION',
            AchievementType::HighStaker => 'HIGHSTAKER',
            AchievementType::FrequentPlayer => 'FREQUENTPLAYER',
            AchievementType::WealthyWinner => 'WEALTHYWINNER',
            AchievementType::QuickWinner => 'QUICKWINNER',
        }
    }
}

impl Felt252TryIntoAchievementType of TryInto<felt252, AchievementType> {
    fn try_into(self: felt252) -> Option<AchievementType> {
        if self == 'FIRSTWAGER' {
            Option::Some(AchievementType::FirstWager)
        } else if self == 'FIRSTWIN' {
            Option::Some(AchievementType::FirstWin)
        } else if self == 'FIRSTJOIN' {
            Option::Some(AchievementType::FirstJoin)
        } else if self == 'WINSTREAK5' {
            Option::Some(AchievementType::WinStreak5)
        } else if self == 'WINSTREAK10' {
            Option::Some(AchievementType::WinStreak10)
        } else if self == 'ACCURATEPREDICTION' {
            Option::Some(AchievementType::AccuratePrediction)
        } else if self == 'HIGHSTAKER' {
            Option::Some(AchievementType::HighStaker)
        } else if self == 'FREQUENTPLAYER' {
            Option::Some(AchievementType::FrequentPlayer)
        } else if self == 'WEALTHYWINNER' {
            Option::Some(AchievementType::WealthyWinner)
        } else if self == 'QUICKWINNER' {
            Option::Some(AchievementType::QuickWinner)
        } else {
            Option::None
        }
    }
}


