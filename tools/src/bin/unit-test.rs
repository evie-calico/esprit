use evunit::{run_tests, read_symfile};
use evunit::log::SilenceLevel;
use evunit::registers::Registers;
use evunit::test::TestConfig;
use std::collections::HashMap;
use std::process::exit;

type Symfile = HashMap<String, (u32, u16)>;

fn get_bit_a(
	tests: &mut Vec<TestConfig>,
	symfile: &Symfile,
	base_test: &TestConfig,
) {
	let get_bit_a = symfile["GetBitA"].1;

	for i in 0..8 {
		let mut test = base_test.clone();
		test.name = format!("GetBitA({i})");

		test.initial = test.initial
			.with_a(i)
			.with_pc(get_bit_a);

		test.result = Some(Registers::new()
			.with_a(1 << i));

		tests.push(test);
	}
}

fn get_xp_reward(
	tests: &mut Vec<TestConfig>,
	symfile: &Symfile,
	base_test: &TestConfig,
) {
	let get_xp_reward = symfile["GetXpReward"].1;

	for i in 0..=20 {
		let mut test = base_test.clone();
		test.name = format!("GetXpReward({i})");

		test.initial = test.initial
			.with_a(i)
			.with_pc(get_xp_reward);

		test.result = Some(Registers::new()
			.with_a(i * 10 + 15));

		tests.push(test);
	}
}

fn get_flag(
	tests: &mut Vec<TestConfig>,
	symfile: &Symfile,
	base_test: &TestConfig,
) {
	let get_flag = symfile["GetFlag"].1;
	let flag_array = symfile["wFlags"].1;

	for i in 0..=255 {
		let mut test = base_test.clone();
		test.name = format!("GetFlag({i})");

		test.initial = test.initial
			.with_c(i)
			.with_pc(get_flag);

		test.result = Some(Registers::new()
			.with_a(1 << (i & 0b111))
			.with_hl(flag_array + ((i as u16) >> 3)));

		tests.push(test);
	}
}

fn main() {
	let rom = "../bin/esprit.gb";
	let sym = Some(String::from("../bin/esprit.sym"));
	let symfile = read_symfile(&sym);

	// Universal config.
	let mut base_test = TestConfig::new(String::new());
	base_test.initial.sp = Some(symfile["wStack.top"].1);
	base_test.enable_breakpoints = true;
	base_test.crash_addresses = vec![0x0038];

	// Generate some tests!
	let mut tests = Vec::new();
	get_bit_a(&mut tests, &symfile, &base_test);
	get_xp_reward(&mut tests, &symfile, &base_test);
	get_flag(&mut tests, &symfile, &base_test);

	// Run and exit.
	let result = run_tests(rom, &tests, SilenceLevel::None);

	if result.is_err() {
		exit(1);
	}
}
