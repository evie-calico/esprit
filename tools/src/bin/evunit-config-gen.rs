fn main() {
	for i in 0..8 {
		println!("
			[GetBitA_{i}]
			pc = \"GetBitA\"
			a = {i}
			[GetBitA_{i}.result]
			a = {}", 1 << i
		);
	}

	for i in 1..=20 {
		println!("
			[GetXpReward_{i}]
			pc = \"GetXpReward\"
			a = {i}
			[GetXpReward_{i}.result]
			a = {}", i * 10 + 15
		);
	}
}
