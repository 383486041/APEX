extends Node
## AudioSynthesizer Autoload Singleton
## Pure GDScript procedural PCM waveform synthesizer using AudioStreamGenerator.
## Distinctly synthesizes:
## - Armor Hits (crystalline metallic energy clink with pitch scaling per combo hit & armor tier)
## - Flesh Hits (heavy low-frequency organic meaty thump, completely distinct from armor hits)
## - Shield Crack (iconic loud glass/crystal shatter + high-voltage electric arc discharge)
## - Gunshots, Multi-Stage Reloads, Melee/Heirloom Slashes, Knockdown Flare, and Loot Tick Burst.

var player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var sample_rate: float = 22050.0
var muted: bool = false

func _ready() -> void:
	player = AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = sample_rate
	gen.buffer_length = 0.45
	player.stream = gen
	add_child(player)
	player.play()
	playback = player.get_stream_playback()

func synthesize_burst(freq_start: float, freq_end: float, duration: float, noise_mix: float = 0.25, vol: float = 0.35, mod_freq: float = 0.0) -> void:
	if muted or playback == null:
		return
	var total_frames: int = int(sample_rate * duration)
	var avail: int = playback.get_frames_available()
	var count: int = mini(total_frames, avail)
	var phase: float = 0.0
	var mod_phase: float = 0.0
	for i in range(count):
		var t: float = float(i) / float(maxi(1, count))
		var env: float = exp(-t * 4.2)
		var freq: float = lerpf(freq_start, freq_end, t)
		if mod_freq > 0.0:
			mod_phase += mod_freq / sample_rate
			freq += sin(mod_phase * TAU) * (freq * 0.22)
		phase += freq / sample_rate
		var tone: float = sin(phase * TAU)
		var harmonic: float = sin(phase * TAU * 2.0) * 0.35
		var noise: float = (randf() * 2.0 - 1.0)
		var sample: float = ((tone + harmonic) * (1.0 - noise_mix) + noise * noise_mix) * env * vol
		playback.push_frame(Vector2(sample, sample))

func play_gunshot(cat: String) -> void:
	match cat:
		"SNIPER":
			synthesize_burst(150.0, 28.0, 0.26, 0.58, 0.50)
		"SHOTGUN":
			synthesize_burst(135.0, 38.0, 0.20, 0.68, 0.46)
		"SMG":
			synthesize_burst(310.0, 95.0, 0.07, 0.35, 0.30)
		"PISTOL":
			synthesize_burst(260.0, 75.0, 0.11, 0.38, 0.36)
		"MELEE":
			synthesize_burst(420.0, 110.0, 0.12, 0.55, 0.40)
		_:
			synthesize_burst(230.0, 68.0, 0.09, 0.40, 0.34)

## Iconic Charge Rifle (滋崩) Phase 1: High-frequency rising tracking laser buzz ("滋")
func play_charge_rifle_charge(progress: float) -> void:
	var f: float = lerpf(340.0, 1420.0, clampf(progress, 0.0, 1.0))
	synthesize_burst(f, f + 38.0, 0.055, 0.12, 0.32, 52.0)

## Iconic Charge Rifle (滋崩) Phase 2: Thunderous explosive plasma blast ("崩")
func play_charge_rifle_blast() -> void:
	# 1. Colossal low-frequency sub-bass shockwave
	synthesize_burst(160.0, 22.0, 0.35, 0.65, 0.62)
	# 2. Piercing high-voltage electric arc crack
	synthesize_burst(2450.0, 280.0, 0.24, 0.45, 0.54, 160.0)
	# 3. Resonant metallic plasma chamber discharge
	synthesize_burst(880.0, 360.0, 0.30, 0.12, 0.40)

func play_reload_step(step_name: String) -> void:
	match step_name:
		"mag_out":
			synthesize_burst(620.0, 280.0, 0.08, 0.25, 0.28)
		"mag_in":
			synthesize_burst(320.0, 780.0, 0.09, 0.20, 0.34)
		"bolt_slap":
			synthesize_burst(940.0, 420.0, 0.11, 0.35, 0.38)
		"lever_cock":
			synthesize_burst(520.0, 880.0, 0.08, 0.22, 0.30)

func play_melee_Whoosh(is_heavy: bool = false) -> void:
	if is_heavy:
		synthesize_burst(340.0, 85.0, 0.18, 0.48, 0.42)
	else:
		synthesize_burst(480.0, 140.0, 0.12, 0.42, 0.34)

## Metallic crystalline energy impact when hitting an enemy's Evo Shield / Armor
func play_armor_hit(evo_level: int = 2, is_headshot: bool = false, combo_hits: int = 1) -> void:
	var pitch_boost: float = minf(320.0, float(combo_hits) * 32.0) + float(evo_level) * 45.0
	if is_headshot:
		synthesize_burst(1520.0 + pitch_boost, 2240.0 + pitch_boost, 0.095, 0.08, 0.44, 180.0)
	else:
		synthesize_burst(1080.0 + pitch_boost, 1420.0 + pitch_boost, 0.068, 0.12, 0.36, 140.0)

## Heavy, low-mid organic meaty thud when hitting unshielded flesh (HP)
func play_flesh_hit(is_headshot: bool = false) -> void:
	if is_headshot:
		synthesize_burst(340.0, 115.0, 0.10, 0.32, 0.44)
		synthesize_burst(1280.0, 860.0, 0.05, 0.05, 0.28)
	else:
		synthesize_burst(210.0, 62.0, 0.085, 0.42, 0.40)

## Iconic Apex Legends loud glass/crystal shatter + electric arc zap on Shield Crack!
func play_shield_crack() -> void:
	# Stage 1: Crystalline glass shatter burst
	synthesize_burst(2450.0, 1120.0, 0.12, 0.62, 0.55, 320.0)
	# Stage 2: High-voltage arc discharge sweep
	synthesize_burst(1920.0, 260.0, 0.22, 0.38, 0.52, 95.0)

func play_knockdown() -> void:
	synthesize_burst(540.0, 1180.0, 0.26, 0.10, 0.46)

## Iconic Apex Legends Elimination / Kill Confirmed audio cue:
## High metallic chime + resonant harmonic chime + low-frequency punch
func play_kill_confirmed() -> void:
	synthesize_burst(2450.0, 3200.0, 0.08, 0.05, 0.45)
	synthesize_burst(1318.5, 880.0, 0.24, 0.06, 0.42, 120.0)
	synthesize_burst(160.0, 48.0, 0.26, 0.32, 0.48)

func play_evo_level_up() -> void:
	synthesize_burst(523.25, 1046.5, 0.24, 0.02, 0.38)

func play_loot_tick_open() -> void:
	synthesize_burst(660.0, 1480.0, 0.28, 0.12, 0.42, 60.0)

func play_ability(kind: String) -> void:
	match kind:
		"void":
			synthesize_burst(340.0, 88.0, 0.28, 0.18, 0.38)
		"scan":
			synthesize_burst(195.0, 880.0, 0.28, 0.10, 0.38)
		"stim":
			synthesize_burst(680.0, 1240.0, 0.16, 0.22, 0.34)
		"grapple":
			synthesize_burst(440.0, 920.0, 0.15, 0.30, 0.36)
		"jumppad":
			synthesize_burst(180.0, 760.0, 0.24, 0.12, 0.40)
		_:
			synthesize_burst(280.0, 740.0, 0.20, 0.14, 0.35)
