use std::env::args;
use std::fs::read;
use std::fs::write;
use std::process::exit;

fn main() {
	let args: Vec<String> = args().collect();
	if args.len() != 3 {
		eprintln!("Expected two arguments");
		exit(1);
	}

	let input = read(&args[2]).unwrap_or_else(|error| {
		eprintln!("Failed to open {}: {}", args[2], error);
		exit(1);
	});

	let mut output = Vec::<u8>::new();

	for i in (0..input.len()).step_by(2) {
		let color = u16::from_le_bytes([input[i], input[i + 1]]);
		output.push(((color >> 5 & 0b11111) * 8) as u8);
		output.push(((color & 0b11111) * 8) as u8);
		output.push(((color >> 10) * 8) as u8);
	}

	write(&args[1], output).unwrap_or_else(|error| {
		eprintln!("Failed to write to {}: {}", args[1], error);
		exit(1);
	});
}