class_name RiotSounds
extends RefCounted
## Original synthesized placeholders, not imported game samples/music.
static var cache := {}
const FREQUENCIES := {"navigate": 520, "confirm": 740, "back": 370, "countdown": 440, "go": 880,
	"drift": 220, "mini_turbo": 660, "boost_pad": 820, "mushroom": 780, "collision": 130,
	"pickup": 1040, "item_use": 610, "item_hit": 160, "lap": 990, "finish": 1180}

static func sound(event: StringName) -> AudioStreamWAV:
	if cache.has(event): return cache[event]
	var looping := event in [&"engine", &"music", &"drift_loop"]
	var length := 8.0 if event == &"music" else (1.0 if looping else 0.18)
	var samples := roundi(22050 * length)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var notes := [220.0, 261.6256, 329.6276, 293.6648, 220.0, 293.6648, 329.6276, 261.6256]
	for index in samples:
		var time := float(index) / 22050
		var value := 0.0
		if event == &"engine":
			value = sin(TAU * 100 * time) * 0.17 + sin(TAU * 200 * time) * 0.07 + sin(TAU * 300 * time) * 0.025
		elif event == &"drift_loop":
			value = (sin(TAU * 1110 * time) + sin(TAU * 1730 * time)) * 0.055
		elif event == &"music":
			var beat := fmod(time, 0.5)
			var note: float = notes[int(time * 2) % notes.size()]
			value = (sin(TAU * note * time) + 0.3 * sin(TAU * note * 2 * time)) * sin(PI * beat / 0.5) * 0.11
		else:
			var frequency: float = FREQUENCIES.get(String(event), 500)
			var envelope := sin(PI * time / length) * (1 - time / length)
			value = sin(TAU * frequency * (time + time * time)) * envelope * 0.22
		data.encode_s16(index * 2, roundi(clampf(value, -0.9, 0.9) * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = data
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = samples
	cache[event] = stream
	return stream
