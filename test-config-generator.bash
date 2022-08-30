# Generator for any configs with many variants.
# Output is concatenated onto the end of test-config.toml

# GetBitA
for i in {0..7}
do
	echo "
[GetBitA_$i]
pc = \"GetBitA\"
a = $i
[GetBitA_$i.result]
a = $((1 << $i))
"
done

# GetXpReward
for i in {0..20}
do
	echo "
[GetXpReward_$i]
pc = \"GetXpReward\"
a = $i
[GetXpReward_$i.result]
a = $(($i * 10 + 15))
"
done
