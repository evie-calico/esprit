/// xp-calc is used for estimating the XP yield of a dungeon to balance enemy levels and dungeon length.

use clap::Parser;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Cli {
	#[arg(short, long)]
	lower_level: u8,
	
	#[arg(short, long)]
	upper_level: u8,
	
	#[arg(short, long)]
	floors: u16,
	
	#[arg(short, long)]
	player_level: u8,

	#[arg(short, long, default_value="5")]
	enemies_per_floor: u16,
}

fn get_xp_target(level: u8) -> u16 {
	let level = level as u16;
	12 * level * level
}

fn add_xp_to_level(mut level: u8, mut xp: u16) -> u8 {
	while xp >= get_xp_target(level) {
		xp -= get_xp_target(level);
		level += 1;
	}
	level
}

fn get_xp_reward(level: u8) -> u16 {
	let level = level as u16;
	15 + 10 * level
}

fn main() {
	let cli = Cli::parse();

	let lower_yield = get_xp_reward(cli.lower_level) * cli.enemies_per_floor * cli.floors;
	let upper_yield = get_xp_reward(cli.upper_level) * cli.enemies_per_floor * cli.floors;
	let average_yield = (lower_yield + upper_yield) / 2;

	let lower_level = add_xp_to_level(cli.player_level, lower_yield);
	let upper_level = add_xp_to_level(cli.player_level, upper_yield);
	let average_level = add_xp_to_level(cli.player_level, average_yield);

	println!("Total XP from dungeon: {lower_yield}-{upper_yield} (Average: {average_yield})");
	println!("Starting at level {}, the player would reach levels {lower_level}-{upper_level} (Average: {average_level})", cli.player_level);
}