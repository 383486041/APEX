extends Node
## AudioSynthesizer Autoload Singleton (Godot 4.3 Pro Acoustic Wavebank Edition)
## Replaces single-channel basic tones with an 8-Channel Polyphonic 44.1kHz 16-bit PCM Acoustic Engine.
## Modeled after Respawn Entertainment's Apex Legends sound design architecture:
## - 4-Layer Firearm Acoustics: (1) Mechanical Bolt/Hammer Transient, (2) Muzzle Blast Impulse, (3) Supersonic N-Wave Crack, (4) Canyon Reverb Tail
## - Distinct Caliber & Weapon Archetype Profiles: R-301/R-99 Light high-RPM snap, Flatline/Rampage Heavy punch, Volt/Nemesis/Havoc Energy plasma chirp, Peacekeeper/Mastiff/EVA-8 Shotgun blast + lever/pump mechanical action, Bocek Compound Bow string twang + carbon arrow whoosh, Kraber .50-Cal cannon boom
## - Authentic Consumable SFX:
##   - Shield Battery / Shield Cell: Mechanical cap twist + rising turbine capacitor whine (320Hz -> 1920Hz) + crystalline shield lock chime
##   - Syringe / Medkit: Auto-injector spring click + pressurized bio-gel pneumatic hiss + medical monitor confirmation beep
## - Footsteps, Supply Bin hydraulic hiss, Door actuation, Armor/Flesh hits, and Glass-Shatter + Arc Shield Crack.

const SAMPLE_RATE: int = 44100
const NUM_CHANNELS: int = 16

var channels: Array[AudioStreamPlayer] = []
var heal_channel: AudioStreamPlayer
var charge_channel: AudioStreamPlayer
var announcer_channel: AudioStreamPlayer
var voice_channel: AudioStreamPlayer
var next_channel_idx: int = 0
var muted: bool = false

# Pre-baked high-frequency reusable WAV cache for zero-latency polyphonic playback
var wav_cache: Dictionary = {}
var sfx_cache: Dictionary = {}

const SOUND_MAP: Dictionary = {
	# Assault Rifles - Authentic Crisp Single Shots
	"r301": "res://assets/sounds/1_Guns/Assault_Rifles/R301_Carbine/Single Shot.mp3",
	"flatline": "res://assets/sounds/1_Guns/Assault_Rifles/VK47_Flatline/Single Shot.mp3",
	"hemlok": "res://assets/sounds/1_Guns/Assault_Rifles/Hemlok_AR/Single Shot.mp3",
	"havoc": "res://assets/sounds/1_Guns/Assault_Rifles/Havoc_Rifle/Single Shot.mp3",
	"g7": "res://assets/sounds/1_Guns/Assault_Rifles/G7_Scout/Shot.mp3",
	"nemesis": "res://assets/sounds/1_Guns/Assault_Rifles/Hemlok_AR/Single Shot.mp3",

	# SMGs - Authentic Crisp Single Shots
	"r99": "res://assets/sounds/1_Guns/SMGs/R99_SMG/Single Shot.mp3",
	"volt": "res://assets/sounds/1_Guns/SMGs/Volt_SMG/Single Shot.mp3",
	"alternator": "res://assets/sounds/1_Guns/SMGs/Alternator/Single Shot.mp3",
	"prowler": "res://assets/sounds/1_Guns/SMGs/Prowler_PDW/Single Shot.mp3",
	"car": "res://assets/sounds/1_Guns/SMGs/R99_SMG/Single Shot.mp3",

	# Snipers & Marksman - High Caliber Thunder Shots
	"kraber": "res://assets/sounds/1_Guns/Snipers/Kraber_50Cal/Shot without Chamber.mp3",
	"sentinel": "res://assets/sounds/1_Guns/Snipers/Sentinel/Shot.mp3",
	"chargerifle": "res://assets/sounds/1_Guns/Snipers/Charge_Rifle/Shot.mp3",
	"longbow": "res://assets/sounds/1_Guns/Snipers/Longbow_DMR/Shot.mp3",
	"tripletake": "res://assets/sounds/1_Guns/Snipers/Triple_Take/Shot.mp3",
	"repeater3030": "res://assets/sounds/1_Guns/Snipers/Longbow_DMR/Shot.mp3",

	# Shotguns - Punchy Blast Shots
	"peacekeeper": "res://assets/sounds/1_Guns/Shotguns/Peacekeeper/Shot.mp3",
	"mastiff": "res://assets/sounds/1_Guns/Shotguns/Mastiff/Shot.mp3",
	"eva8": "res://assets/sounds/1_Guns/Shotguns/Eva8_Auto/Shot.mp3",
	"mozambique": "res://assets/sounds/1_Guns/Shotguns/Mozambique/Shot.mp3",

	# LMGs - Authentic Heavy Single Shots
	"devotion": "res://assets/sounds/1_Guns/LMGs/Devotion_LMG/Single Shot.mp3",
	"spitfire": "res://assets/sounds/1_Guns/LMGs/M600_Spitfire/Single Shot.mp3",
	"lstar": "res://assets/sounds/1_Guns/LMGs/LStar_EMG/Single Shot.mp3",
	"rampage": "res://assets/sounds/1_Guns/LMGs/M600_Spitfire/Single Shot.mp3",

	# Pistols - Snappy Shots
	"wingman": "res://assets/sounds/1_Guns/Pistols/Wingman/Shot.mp3",
	"re45": "res://assets/sounds/1_Guns/Pistols/RE45_Auto/Single Shot.mp3",
	"p2020": "res://assets/sounds/1_Guns/Pistols/P2020/Shot.mp3",

	# Combat Feedback & HUD
	"shield_crack": "res://assets/sounds/3_Combat_and_HUD/Shield_Crack.mp3",
	"knockdown": "res://assets/sounds/3_Combat_and_HUD/Knockdown_Sound.mp3",
	"ping": "res://assets/sounds/3_Combat_and_HUD/Ping_Sound.mp3",
	"shield_cell": "res://assets/sounds/3_Combat_and_HUD/Shield_Cell_Heal.mp3",
	"evo_shield": "res://assets/sounds/3_Combat_and_HUD/Evo_Shield_Upgrade.mp3",
	"jumpmaster": "res://assets/sounds/3_Combat_and_HUD/Jumpmaster_Drop.mp3",
	"apex_predator": "res://assets/sounds/3_Combat_and_HUD/Apex_Predator.mp3",
	"mozambique_here": "res://assets/sounds/3_Combat_and_HUD/Mozambique_Here.mp3",

	# Announcer
	"announcer_first_blood": "res://assets/sounds/4_Announcer/First_Blood.mp3",
	"announcer_kill_leader": "res://assets/sounds/4_Announcer/New_Kill_Leader.mp3",
	"announcer_apex_champions": "res://assets/sounds/4_Announcer/Apex_Champions.mp3",
	"announcer_champion_eliminated": "res://assets/sounds/4_Announcer/Champion_Eliminated.mp3",
	"announcer_care_package_delivering": "res://assets/sounds/4_Announcer/Care_Package_Delivering.mp3",
	"announcer_care_package_arrived": "res://assets/sounds/4_Announcer/Care_Package_Arrived.mp3"
}

const LEGEND_VOICES: Dictionary = {
	"octane": [
		"res://assets/sounds/5_Legends_Voice/Octane/I have a need for speed.mp3",
		"res://assets/sounds/5_Legends_Voice/Octane/you need to move faster than that Amigo.mp3",
		"res://assets/sounds/5_Legends_Voice/Octane/These legs werent made for walking.mp3"
	],
	"pathfinder": [
		"res://assets/sounds/5_Legends_Voice/Pathfinder/Good Luck Have Fun Pathfinder.mp3",
		"res://assets/sounds/5_Legends_Voice/Pathfinder/Hi Friends apex legends.mp3",
		"res://assets/sounds/5_Legends_Voice/Pathfinder/Lets go for a ride.mp3",
		"res://assets/sounds/5_Legends_Voice/Pathfinder/Ready and Excited Pathfinder.mp3"
	],
	"mirage": [
		"res://assets/sounds/5_Legends_Voice/Mirage/Bamboozled.mp3",
		"res://assets/sounds/5_Legends_Voice/Mirage/Apex legends Mirage Bamboozle.mp3",
		"res://assets/sounds/5_Legends_Voice/Mirage/Mirage Sound Effect.mp3"
	],
	"wraith": [
		"res://assets/sounds/5_Legends_Voice/Wraith/They wont see me coming.mp3",
		"res://assets/sounds/5_Legends_Voice/Wraith/Ever get a feeling you're not alone in the room.mp3"
	],
	"caustic": [
		"res://assets/sounds/5_Legends_Voice/Caustic/caustic join my experiment.mp3",
		"res://assets/sounds/5_Legends_Voice/Caustic/caustic simply remark.mp3",
		"res://assets/sounds/5_Legends_Voice/Caustic/Apex Legends - Caustic.mp3"
	],
	"lifeline": [
		"res://assets/sounds/5_Legends_Voice/Lifeline/Lifeline_Voice.mp3"
	],
	"crypto": [
		"res://assets/sounds/5_Legends_Voice/Crypto/Crypto_Voice.mp3"
	],
	"revenant": [
		"res://assets/sounds/5_Legends_Voice/Revenant/Revenant_Voice.mp3"
	],
	"gibraltar": [
		"res://assets/sounds/5_Legends_Voice/Gibraltar/Gibraltar_Voice.mp3"
	]
}

const GRENADE_SOUNDS: Dictionary = {
	"arc_star_throw": "res://assets/sounds/2_Grenades/Arc_Star/Throw Arc Star.mp3",
	"arc_star_detonation": "res://assets/sounds/2_Grenades/Arc_Star/Arc Star Detonation.mp3",
	"arc_star_explosion": "res://assets/sounds/2_Grenades/Arc_Star/Arc Star Explosion.mp3",
	"frag_throw": "res://assets/sounds/2_Grenades/Frag_Grenade/Throw Frag.mp3",
	"frag_explosion": "res://assets/sounds/2_Grenades/Frag_Grenade/Frag Explosion.mp3",
	"thermite_throw": "res://assets/sounds/2_Grenades/Thermite_Grenade/Throw Thermite.mp3",
	"thermite_explosion": "res://assets/sounds/2_Grenades/Thermite_Grenade/Thermite Explosion and Residue.mp3"
}

func _ready() -> void:
	for i in range(NUM_CHANNELS):
		var p := AudioStreamPlayer.new()
		p.name = "PolyChannel_%d" % i
		p.volume_db = -2.0
		add_child(p)
		channels.append(p)

	heal_channel = AudioStreamPlayer.new()
	heal_channel.name = "HealChannel"
	heal_channel.volume_db = -1.5
	add_child(heal_channel)

	charge_channel = AudioStreamPlayer.new()
	charge_channel.name = "ChargeChannel"
	charge_channel.volume_db = -1.5
	add_child(charge_channel)

	announcer_channel = AudioStreamPlayer.new()
	announcer_channel.name = "AnnouncerChannel"
	announcer_channel.volume_db = 1.0
	add_child(announcer_channel)

	voice_channel = AudioStreamPlayer.new()
	voice_channel.name = "VoiceChannel"
	voice_channel.volume_db = 1.0
	add_child(voice_channel)

	_prebake_core_soundbank()
	_preload_authentic_soundbank()

func _preload_authentic_soundbank() -> void:
	for key: String in SOUND_MAP:
		var path: String = SOUND_MAP[key]
		if ResourceLoader.exists(path):
			var s: AudioStream = load(path)
			if s != null:
				sfx_cache[key] = s
	for key: String in GRENADE_SOUNDS:
		var path: String = GRENADE_SOUNDS[key]
		if ResourceLoader.exists(path):
			var s: AudioStream = load(path)
			if s != null:
				sfx_cache[key] = s

func get_sfx(key: String) -> AudioStream:
	if sfx_cache.has(key):
		return sfx_cache[key]
	if SOUND_MAP.has(key):
		var path: String = SOUND_MAP[key]
		if ResourceLoader.exists(path):
			var s: AudioStream = load(path)
			if s != null:
				sfx_cache[key] = s
				return s
	return null

func toggle_mute() -> bool:
	muted = not muted
	if muted:
		stop_heal_sound()
	return muted

func _play_wav(stream: AudioStream, pitch_scale: float = 1.0, vol_db: float = -2.0) -> void:
	_play_stream(stream, pitch_scale, vol_db)

func _play_stream(stream: AudioStream, pitch_scale: float = 1.0, vol_db: float = -2.0) -> void:
	if muted or stream == null or channels.is_empty():
		return
	var ch: AudioStreamPlayer = channels[next_channel_idx]
	next_channel_idx = (next_channel_idx + 1) % channels.size()
	ch.stream = stream
	ch.pitch_scale = clampf(pitch_scale, 0.5, 2.0)
	ch.volume_db = vol_db
	ch.play()


## Builds a 16-bit mono AudioStreamWAV from an Array of layered acoustic descriptors
func _build_layered_wav(duration: float, layers: Array) -> AudioStreamWAV:
	var num_samples: int = maxi(64, int(float(SAMPLE_RATE) * duration))
	var pcm := PackedByteArray()
	pcm.resize(num_samples * 2)

	var phases: Array[float] = []
	var mod_phases: Array[float] = []
	var lp_states: Array[float] = []
	for _l in layers:
		phases.append(0.0)
		mod_phases.append(0.0)
		lp_states.append(0.0)

	var inv_sr: float = 1.0 / float(SAMPLE_RATE)

	for i in range(num_samples):
		var t_sec: float = float(i) * inv_sr
		var mixed: float = 0.0

		for l_idx in range(layers.size()):
			var ld: Dictionary = layers[l_idx]
			var start_t: float = float(ld.get("delay", 0.0))
			var l_dur: float = float(ld.get("dur", duration))
			if t_sec < start_t or t_sec > start_t + l_dur:
				continue

			var lt: float = (t_sec - start_t) / maxf(0.001, l_dur)
			var attack: float = float(ld.get("attack", 0.004))
			var decay_rate: float = float(ld.get("decay", 5.5))
			var env: float = exp(-lt * decay_rate)
			if (t_sec - start_t) < attack:
				env *= (t_sec - start_t) / maxf(0.0005, attack)

			var f0: float = float(ld.get("f_start", 220.0))
			var f1: float = float(ld.get("f_end", 60.0))
			var curve_exp: float = float(ld.get("curve", 1.0))
			var freq: float = lerpf(f0, f1, pow(lt, curve_exp))

			var mod_f: float = float(ld.get("mod_freq", 0.0))
			if mod_f > 0.0:
				mod_phases[l_idx] += mod_f * inv_sr
				freq += sin(mod_phases[l_idx] * TAU) * (freq * float(ld.get("mod_depth", 0.2)))

			phases[l_idx] += freq * inv_sr
			var ph: float = phases[l_idx] * TAU

			var wave_type: String = str(ld.get("wave", "sine"))
			var tone: float = 0.0
			match wave_type:
				"saw":
					tone = 2.0 * (phases[l_idx] - floor(phases[l_idx] + 0.5))
				"square":
					tone = 1.0 if sin(ph) >= 0.0 else -1.0
				"tri":
					tone = 2.0 * absf(2.0 * (phases[l_idx] - floor(phases[l_idx] + 0.5))) - 1.0
				"metallic":
					tone = (sin(ph) + 0.55 * sin(ph * 1.414) + 0.35 * sin(ph * 2.732)) * 0.55
				_:
					tone = sin(ph) + 0.35 * sin(ph * 2.0) + 0.15 * sin(ph * 3.0)

			var n_mix: float = float(ld.get("noise", 0.25))
			var raw_noise: float = randf() * 2.0 - 1.0
			var lp_alpha: float = clampf(float(ld.get("lp_cutoff", 2400.0)) / float(SAMPLE_RATE * 0.5), 0.02, 1.0)
			lp_states[l_idx] = lp_states[l_idx] + lp_alpha * (raw_noise - lp_states[l_idx])
			var filtered_noise: float = lp_states[l_idx]

			var sig: float = (tone * (1.0 - n_mix) + filtered_noise * n_mix) * env * float(ld.get("vol", 0.4))
			mixed += sig

		# Soft tanh saturation for warm analog gun/explosion compression
		var compressed: float = tanh(mixed * 1.35)
		var s16: int = clampi(int(compressed * 32760.0), -32768, 32767)
		pcm.encode_s16(i * 2, s16)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = pcm
	return wav

func _prebake_core_soundbank() -> void:
	# 1. Gunshots by Caliber & Weapon Class (4-layer physical modeling)
	wav_cache["gun_ar_light"] = _build_layered_wav(0.24, [
		{"f_start": 1650.0, "f_end": 420.0, "dur": 0.018, "decay": 12.0, "noise": 0.65, "lp_cutoff": 6500.0, "vol": 0.65, "wave": "saw"}, # Supersonic N-wave crack
		{"f_start": 240.0, "f_end": 58.0, "dur": 0.11, "decay": 6.5, "noise": 0.55, "lp_cutoff": 1800.0, "vol": 0.72, "wave": "saw"},      # Muzzle blast punch
		{"delay": 0.02, "f_start": 980.0, "f_end": 620.0, "dur": 0.04, "decay": 10.0, "noise": 0.20, "lp_cutoff": 3500.0, "vol": 0.35, "wave": "metallic"}, # Bolt carrier reciprocation
		{"delay": 0.03, "f_start": 140.0, "f_end": 42.0, "dur": 0.20, "decay": 4.2, "noise": 0.85, "lp_cutoff": 750.0, "vol": 0.32}        # Canyon reverb tail
	])
	wav_cache["gun_ar_heavy"] = _build_layered_wav(0.28, [
		{"f_start": 1250.0, "f_end": 280.0, "dur": 0.024, "decay": 10.0, "noise": 0.60, "lp_cutoff": 4800.0, "vol": 0.68, "wave": "saw"},
		{"f_start": 175.0, "f_end": 42.0, "dur": 0.15, "decay": 5.2, "noise": 0.52, "lp_cutoff": 1350.0, "vol": 0.85, "wave": "square"},
		{"delay": 0.025, "f_start": 740.0, "f_end": 410.0, "dur": 0.05, "decay": 9.0, "noise": 0.22, "lp_cutoff": 2800.0, "vol": 0.42, "wave": "metallic"},
		{"delay": 0.04, "f_start": 115.0, "f_end": 35.0, "dur": 0.23, "decay": 3.8, "noise": 0.88, "lp_cutoff": 620.0, "vol": 0.38}
	])
	wav_cache["gun_energy"] = _build_layered_wav(0.22, [
		{"f_start": 1880.0, "f_end": 340.0, "dur": 0.095, "decay": 6.8, "noise": 0.22, "lp_cutoff": 5500.0, "vol": 0.65, "wave": "saw", "mod_freq": 95.0, "mod_depth": 0.14},
		{"f_start": 280.0, "f_end": 75.0, "dur": 0.11, "decay": 6.0, "noise": 0.35, "lp_cutoff": 2200.0, "vol": 0.58, "wave": "tri"},
		{"delay": 0.015, "f_start": 2400.0, "f_end": 880.0, "dur": 0.08, "decay": 8.0, "noise": 0.15, "lp_cutoff": 6000.0, "vol": 0.35, "wave": "metallic"}
	])
	wav_cache["gun_smg"] = _build_layered_wav(0.16, [
		{"f_start": 1950.0, "f_end": 520.0, "dur": 0.014, "decay": 14.0, "noise": 0.65, "lp_cutoff": 7000.0, "vol": 0.58, "wave": "saw"},
		{"f_start": 290.0, "f_end": 82.0, "dur": 0.075, "decay": 7.5, "noise": 0.50, "lp_cutoff": 2100.0, "vol": 0.64, "wave": "saw"},
		{"delay": 0.015, "f_start": 1150.0, "f_end": 720.0, "dur": 0.03, "decay": 12.0, "noise": 0.25, "lp_cutoff": 4200.0, "vol": 0.32, "wave": "metallic"}
	])
	wav_cache["gun_shotgun"] = _build_layered_wav(0.38, [
		{"f_start": 980.0, "f_end": 180.0, "dur": 0.035, "decay": 9.0, "noise": 0.78, "lp_cutoff": 5200.0, "vol": 0.85, "wave": "square"},
		{"f_start": 145.0, "f_end": 30.0, "dur": 0.22, "decay": 4.5, "noise": 0.68, "lp_cutoff": 980.0, "vol": 0.92, "wave": "saw"},
		{"delay": 0.04, "f_start": 110.0, "f_end": 28.0, "dur": 0.32, "decay": 3.5, "noise": 0.90, "lp_cutoff": 540.0, "vol": 0.48}
	])
	wav_cache["gun_sniper"] = _build_layered_wav(0.52, [
		{"f_start": 2200.0, "f_end": 320.0, "dur": 0.032, "decay": 8.5, "noise": 0.70, "lp_cutoff": 7500.0, "vol": 0.88, "wave": "saw"},
		{"f_start": 135.0, "f_end": 24.0, "dur": 0.32, "decay": 3.8, "noise": 0.62, "lp_cutoff": 1100.0, "vol": 0.95, "wave": "saw"},
		{"delay": 0.03, "f_start": 880.0, "f_end": 290.0, "dur": 0.14, "decay": 6.0, "noise": 0.20, "lp_cutoff": 3400.0, "vol": 0.45, "wave": "metallic"},
		{"delay": 0.06, "f_start": 95.0, "f_end": 22.0, "dur": 0.45, "decay": 2.8, "noise": 0.92, "lp_cutoff": 480.0, "vol": 0.55}
	])
	wav_cache["gun_pistol"] = _build_layered_wav(0.20, [
		{"f_start": 1450.0, "f_end": 360.0, "dur": 0.018, "decay": 11.0, "noise": 0.58, "lp_cutoff": 5800.0, "vol": 0.62, "wave": "saw"},
		{"f_start": 230.0, "f_end": 68.0, "dur": 0.11, "decay": 6.2, "noise": 0.48, "lp_cutoff": 1650.0, "vol": 0.72, "wave": "tri"},
		{"delay": 0.02, "f_start": 1020.0, "f_end": 580.0, "dur": 0.04, "decay": 10.0, "noise": 0.18, "lp_cutoff": 3800.0, "vol": 0.35, "wave": "metallic"}
	])
	wav_cache["bow_release"] = _build_layered_wav(0.24, [
		{"f_start": 195.0, "f_end": 92.0, "dur": 0.18, "decay": 5.2, "noise": 0.08, "lp_cutoff": 1200.0, "vol": 0.65, "wave": "tri", "mod_freq": 38.0, "mod_depth": 0.18}, # Bowstring twang
		{"f_start": 1680.0, "f_end": 420.0, "dur": 0.09, "decay": 7.5, "noise": 0.78, "lp_cutoff": 4800.0, "vol": 0.52} # High-velocity arrow air whoosh
	])
	wav_cache["bow_draw"] = _build_layered_wav(0.18, [
		{"f_start": 280.0, "f_end": 540.0, "dur": 0.16, "decay": 4.0, "noise": 0.35, "lp_cutoff": 1800.0, "vol": 0.35, "wave": "tri"}
	])

	# 2. Reload & Mechanical Action Steps
	wav_cache["mag_out"] = _build_layered_wav(0.11, [
		{"f_start": 680.0, "f_end": 290.0, "dur": 0.08, "decay": 8.0, "noise": 0.35, "lp_cutoff": 3200.0, "vol": 0.48, "wave": "metallic"},
		{"delay": 0.04, "f_start": 1240.0, "f_end": 820.0, "dur": 0.05, "decay": 12.0, "noise": 0.20, "lp_cutoff": 4500.0, "vol": 0.36, "wave": "metallic"}
	])
	wav_cache["mag_in"] = _build_layered_wav(0.13, [
		{"f_start": 240.0, "f_end": 120.0, "dur": 0.05, "decay": 10.0, "noise": 0.45, "lp_cutoff": 1400.0, "vol": 0.55, "wave": "square"},
		{"delay": 0.035, "f_start": 920.0, "f_end": 1480.0, "dur": 0.07, "decay": 9.5, "noise": 0.22, "lp_cutoff": 5200.0, "vol": 0.58, "wave": "metallic"}
	])
	wav_cache["bolt_slap"] = _build_layered_wav(0.15, [
		{"f_start": 1180.0, "f_end": 440.0, "dur": 0.06, "decay": 9.0, "noise": 0.38, "lp_cutoff": 4800.0, "vol": 0.62, "wave": "metallic"},
		{"delay": 0.05, "f_start": 1620.0, "f_end": 680.0, "dur": 0.08, "decay": 8.5, "noise": 0.28, "lp_cutoff": 6000.0, "vol": 0.65, "wave": "metallic"}
	])
	wav_cache["lever_cock"] = _build_layered_wav(0.18, [
		{"f_start": 540.0, "f_end": 960.0, "dur": 0.07, "decay": 9.0, "noise": 0.28, "lp_cutoff": 4200.0, "vol": 0.48, "wave": "metallic"},
		{"delay": 0.075, "f_start": 1120.0, "f_end": 620.0, "dur": 0.08, "decay": 9.5, "noise": 0.25, "lp_cutoff": 4800.0, "vol": 0.52, "wave": "metallic"}
	])
	wav_cache["shell_insert"] = _build_layered_wav(0.10, [
		{"f_start": 480.0, "f_end": 880.0, "dur": 0.045, "decay": 11.0, "noise": 0.30, "lp_cutoff": 3800.0, "vol": 0.46, "wave": "tri"},
		{"delay": 0.035, "f_start": 1350.0, "f_end": 980.0, "dur": 0.045, "decay": 12.0, "noise": 0.18, "lp_cutoff": 5200.0, "vol": 0.42, "wave": "metallic"}
	])

	# 3. Armor Hit, Flesh Hit, Shield Crack & Knockdown
	wav_cache["armor_hit"] = _build_layered_wav(0.09, [
		{"f_start": 1240.0, "f_end": 1680.0, "dur": 0.075, "decay": 7.5, "noise": 0.12, "lp_cutoff": 6500.0, "vol": 0.58, "wave": "metallic"},
		{"f_start": 2480.0, "f_end": 3120.0, "dur": 0.055, "decay": 9.5, "noise": 0.18, "lp_cutoff": 8000.0, "vol": 0.42, "wave": "sine"}
	])
	wav_cache["flesh_hit"] = _build_layered_wav(0.10, [
		{"f_start": 225.0, "f_end": 58.0, "dur": 0.09, "decay": 6.8, "noise": 0.45, "lp_cutoff": 950.0, "vol": 0.68, "wave": "tri"},
		{"f_start": 620.0, "f_end": 180.0, "dur": 0.05, "decay": 10.0, "noise": 0.35, "lp_cutoff": 1800.0, "vol": 0.38}
	])
	wav_cache["shield_crack"] = _build_layered_wav(0.42, [
		{"f_start": 2850.0, "f_end": 1180.0, "dur": 0.16, "decay": 5.5, "noise": 0.65, "lp_cutoff": 8500.0, "vol": 0.85, "wave": "metallic", "mod_freq": 280.0, "mod_depth": 0.25},
		{"delay": 0.03, "f_start": 2150.0, "f_end": 240.0, "dur": 0.28, "decay": 4.2, "noise": 0.42, "lp_cutoff": 5200.0, "vol": 0.78, "wave": "saw", "mod_freq": 110.0, "mod_depth": 0.22},
		{"delay": 0.08, "f_start": 1680.0, "f_end": 620.0, "dur": 0.26, "decay": 4.8, "noise": 0.25, "lp_cutoff": 6200.0, "vol": 0.55, "wave": "metallic"}
	])
	wav_cache["kill_confirmed"] = _build_layered_wav(0.36, [
		{"f_start": 2450.0, "f_end": 3280.0, "dur": 0.10, "decay": 7.0, "noise": 0.06, "lp_cutoff": 8000.0, "vol": 0.65, "wave": "metallic"},
		{"delay": 0.04, "f_start": 1318.5, "f_end": 880.0, "dur": 0.26, "decay": 4.5, "noise": 0.05, "lp_cutoff": 5500.0, "vol": 0.58, "wave": "sine"},
		{"f_start": 165.0, "f_end": 42.0, "dur": 0.28, "decay": 4.2, "noise": 0.35, "lp_cutoff": 680.0, "vol": 0.68, "wave": "tri"}
	])

	# 4. Authentic Shield Battery & Medkit / Syringe Audio
	wav_cache["battery_start"] = _build_layered_wav(0.45, [
		{"f_start": 820.0, "f_end": 1340.0, "dur": 0.07, "decay": 9.0, "noise": 0.22, "lp_cutoff": 4800.0, "vol": 0.52, "wave": "metallic"}, # Twist cap latch
		{"delay": 0.08, "f_start": 320.0, "f_end": 980.0, "dur": 0.36, "decay": 2.2, "noise": 0.10, "lp_cutoff": 4200.0, "vol": 0.55, "wave": "saw", "mod_freq": 45.0, "mod_depth": 0.08} # Capacitor turbine spin-up
	])
	wav_cache["battery_complete"] = _build_layered_wav(0.38, [
		{"f_start": 1046.5, "f_end": 2093.0, "dur": 0.18, "decay": 5.0, "noise": 0.05, "lp_cutoff": 7500.0, "vol": 0.65, "wave": "sine"},
		{"delay": 0.06, "f_start": 1568.0, "f_end": 2637.0, "dur": 0.26, "decay": 4.2, "noise": 0.04, "lp_cutoff": 8000.0, "vol": 0.62, "wave": "metallic"}
	])
	wav_cache["syringe_start"] = _build_layered_wav(0.42, [
		{"f_start": 1420.0, "f_end": 780.0, "dur": 0.05, "decay": 11.0, "noise": 0.25, "lp_cutoff": 5500.0, "vol": 0.52, "wave": "metallic"}, # Spring auto-injector click
		{"delay": 0.06, "f_start": 1850.0, "f_end": 920.0, "dur": 0.32, "decay": 3.2, "noise": 0.82, "lp_cutoff": 3800.0, "vol": 0.48} # Pneumatic liquid injection hiss
	])
	wav_cache["medkit_complete"] = _build_layered_wav(0.34, [
		{"f_start": 880.0, "f_end": 880.0, "dur": 0.09, "decay": 6.0, "noise": 0.02, "lp_cutoff": 4500.0, "vol": 0.55, "wave": "sine"},
		{"delay": 0.11, "f_start": 1318.5, "f_end": 1760.0, "dur": 0.20, "decay": 4.8, "noise": 0.02, "lp_cutoff": 6000.0, "vol": 0.58, "wave": "sine"}
	])
	wav_cache["footstep"] = _build_layered_wav(0.085, [
		{"f_start": 165.0, "f_end": 52.0, "dur": 0.075, "decay": 9.5, "noise": 0.72, "lp_cutoff": 820.0, "vol": 0.34, "wave": "tri"}
	])
	wav_cache["supply_bin_open"] = _build_layered_wav(0.42, [
		{"f_start": 480.0, "f_end": 220.0, "dur": 0.09, "decay": 8.0, "noise": 0.35, "lp_cutoff": 2600.0, "vol": 0.58, "wave": "metallic"},
		{"delay": 0.06, "f_start": 1600.0, "f_end": 620.0, "dur": 0.34, "decay": 3.5, "noise": 0.85, "lp_cutoff": 3200.0, "vol": 0.46} # Hydraulic strut hiss
	])

func play_gunshot(cat: String, wid: String = "") -> void:
	if muted:
		return
	var s: AudioStream = get_sfx(wid)
	if s != null:
		var pitch: float = randf_range(0.97, 1.03)
		var vol: float = 0.0
		if cat == "SNIPER":
			vol = 2.0
		elif cat == "SHOTGUN":
			vol = 1.0
		elif cat == "SMG":
			vol = -1.0
		_play_stream(s, pitch, vol)
		return

	# Fallback to procedural acoustic synthesis if asset not mapped
	if wid == "bocek":
		_play_wav(wav_cache.get("bow_release"), randf_range(0.96, 1.04), -1.0)
		return
	if wid == "volt" or wid == "nemesis" or wid == "havoc" or wid == "devotion" or wid == "lstar" or wid == "tripletake":
		_play_wav(wav_cache.get("gun_energy"), randf_range(0.96, 1.04), -1.5)
		return
	if wid == "flatline" or wid == "hemlok" or wid == "rampage" or wid == "repeater3030":
		_play_wav(wav_cache.get("gun_ar_heavy"), randf_range(0.96, 1.04), -1.0)
		return
	match cat:
		"SNIPER":
			_play_wav(wav_cache.get("gun_sniper"), randf_range(0.95, 1.03), 0.0)
		"SHOTGUN":
			_play_wav(wav_cache.get("gun_shotgun"), randf_range(0.95, 1.04), 0.0)
		"SMG":
			_play_wav(wav_cache.get("gun_smg"), randf_range(0.97, 1.05), -2.5)
		"PISTOL":
			_play_wav(wav_cache.get("gun_pistol"), randf_range(0.96, 1.04), -1.5)
		"MELEE":
			play_melee_Whoosh(true)
		_:
			_play_wav(wav_cache.get("gun_ar_light"), randf_range(0.97, 1.04), -1.8)

func play_bow_draw() -> void:
	_play_wav(wav_cache.get("bow_draw"), 1.0, -3.0)

func play_charge_rifle_charge(progress: float) -> void:
	if muted:
		return
	var f: float = lerpf(380.0, 1520.0, clampf(progress, 0.0, 1.0))
	var stream := _build_layered_wav(0.065, [
		{"f_start": f, "f_end": f + 45.0, "dur": 0.06, "decay": 3.0, "noise": 0.14, "lp_cutoff": 5500.0, "vol": 0.42, "wave": "saw", "mod_freq": 60.0, "mod_depth": 0.15}
	])
	charge_channel.stream = stream
	charge_channel.play()

func play_charge_rifle_blast() -> void:
	var s: AudioStream = get_sfx("chargerifle")
	if s != null:
		_play_stream(s, 1.0, 1.2)
	else:
		_play_wav(wav_cache.get("gun_sniper"), 0.85, 1.0)
		_play_wav(wav_cache.get("shield_crack"), 0.90, -1.0)

func play_reload_step(step_name: String) -> void:
	match step_name:
		"mag_out":
			_play_wav(wav_cache.get("mag_out"), randf_range(0.97, 1.03), -2.0)
		"mag_in":
			_play_wav(wav_cache.get("mag_in"), randf_range(0.97, 1.03), -1.5)
		"bolt_slap":
			_play_wav(wav_cache.get("bolt_slap"), randf_range(0.97, 1.03), -1.0)
		"lever_cock", "pump_action":
			_play_wav(wav_cache.get("lever_cock"), randf_range(0.97, 1.03), -1.5)
		"shell_insert":
			_play_wav(wav_cache.get("shell_insert"), randf_range(0.96, 1.06), -2.0)

func play_heal_start(heal_id: String) -> void:
	if muted:
		return
	var is_shield: bool = (heal_id == "shield_battery" or heal_id == "shield_cell" or heal_id == "phoenix_kit")
	var stream: AudioStreamWAV = wav_cache.get("battery_start") if is_shield else wav_cache.get("syringe_start")
	if stream:
		heal_channel.stream = stream
		heal_channel.pitch_scale = 1.0
		heal_channel.play()

func play_heal_progress_pulse(heal_id: String, progress: float) -> void:
	if muted:
		return
	var is_shield: bool = (heal_id == "shield_battery" or heal_id == "shield_cell" or heal_id == "phoenix_kit")
	if is_shield:
		var f0: float = lerpf(440.0, 1680.0, clampf(progress, 0.0, 1.0))
		var pulse_wav := _build_layered_wav(0.18, [
			{"f_start": f0, "f_end": f0 + 95.0, "dur": 0.17, "decay": 3.5, "noise": 0.08, "lp_cutoff": 5800.0, "vol": 0.36, "wave": "saw", "mod_freq": 42.0, "mod_depth": 0.10},
			{"f_start": 980.0, "f_end": 1240.0, "dur": 0.04, "decay": 12.0, "noise": 0.15, "lp_cutoff": 4800.0, "vol": 0.25, "wave": "metallic"}
		])
		heal_channel.stream = pulse_wav
		heal_channel.play()
	else:
		var pulse_wav := _build_layered_wav(0.16, [
			{"f_start": 920.0, "f_end": 640.0, "dur": 0.14, "decay": 5.5, "noise": 0.65, "lp_cutoff": 2800.0, "vol": 0.32},
			{"f_start": 740.0 + progress * 420.0, "f_end": 740.0 + progress * 420.0, "dur": 0.06, "decay": 8.0, "noise": 0.02, "lp_cutoff": 4500.0, "vol": 0.28, "wave": "sine"}
		])
		heal_channel.stream = pulse_wav
		heal_channel.play()

func play_heal_complete(heal_id: String) -> void:
	if muted:
		return
	if heal_id == "shield_cell":
		var s: AudioStream = get_sfx("shield_cell")
		if s != null:
			_play_stream(s, 1.0, 0.0)
			return
	var is_shield: bool = (heal_id == "shield_battery" or heal_id == "shield_cell" or heal_id == "phoenix_kit")
	var stream: AudioStreamWAV = wav_cache.get("battery_complete") if is_shield else wav_cache.get("medkit_complete")
	_play_wav(stream, 1.0, -0.5)

func stop_heal_sound() -> void:
	if is_instance_valid(heal_channel) and heal_channel.playing:
		heal_channel.stop()

func play_footstep(is_sprinting: bool = false) -> void:
	_play_wav(wav_cache.get("footstep"), randf_range(0.92, 1.12) * (1.12 if is_sprinting else 1.0), -5.0 if not is_sprinting else -3.0)

func play_supply_bin_open() -> void:
	_play_wav(wav_cache.get("supply_bin_open"), 1.0, -1.0)

func play_melee_Whoosh(is_heavy: bool = false) -> void:
	var stream := _build_layered_wav(0.18 if is_heavy else 0.13, [
		{"f_start": 380.0 if is_heavy else 520.0, "f_end": 85.0, "dur": 0.16 if is_heavy else 0.12, "decay": 5.5, "noise": 0.55, "lp_cutoff": 1800.0, "vol": 0.52, "wave": "tri"}
	])
	_play_wav(stream, 1.0, -1.5)

func play_armor_hit(evo_level: int = 2, is_headshot: bool = false, combo_hits: int = 1) -> void:
	var p_scale: float = 1.0 + minf(0.35, float(combo_hits) * 0.03) + float(evo_level) * 0.04
	if is_headshot:
		p_scale *= 1.22
	_play_wav(wav_cache.get("armor_hit"), p_scale, -0.5 if is_headshot else -1.5)

func play_flesh_hit(is_headshot: bool = false) -> void:
	_play_wav(wav_cache.get("flesh_hit"), 1.18 if is_headshot else 1.0, 0.0 if is_headshot else -1.2)

func play_shield_crack() -> void:
	var s: AudioStream = get_sfx("shield_crack")
	if s != null:
		_play_stream(s, 1.0, 1.0)
	else:
		_play_wav(wav_cache.get("shield_crack"), 1.0, 0.5)

func play_knockdown() -> void:
	var s: AudioStream = get_sfx("knockdown")
	if s != null:
		_play_stream(s, 1.0, 1.2)
	else:
		_play_wav(wav_cache.get("kill_confirmed"), 0.92, 0.0)

func play_kill_confirmed() -> void:
	var s: AudioStream = get_sfx("knockdown")
	if s != null:
		_play_stream(s, 1.0, 1.0)
	else:
		_play_wav(wav_cache.get("kill_confirmed"), 1.0, 0.5)

func play_ping() -> void:
	var s: AudioStream = get_sfx("ping")
	if s != null:
		_play_stream(s, 1.0, 0.0)

func play_evo_level_up() -> void:
	var s: AudioStream = get_sfx("evo_shield")
	if s != null:
		_play_stream(s, 1.0, 0.0)
	else:
		_play_wav(wav_cache.get("battery_complete"), 1.05, -0.5)

func play_loot_tick_open() -> void:
	_play_wav(wav_cache.get("supply_bin_open"), 1.15, 0.0)
	_play_wav(wav_cache.get("battery_complete"), 1.12, 0.0)

func play_ability(kind: String) -> void:
	match kind:
		"void":
			var w := _build_layered_wav(0.34, [
				{"f_start": 380.0, "f_end": 78.0, "dur": 0.32, "decay": 4.2, "noise": 0.25, "lp_cutoff": 2200.0, "vol": 0.58, "wave": "saw", "mod_freq": 32.0, "mod_depth": 0.2}
			])
			_play_wav(w, 1.0, -1.0)
		"scan":
			var w := _build_layered_wav(0.36, [
				{"f_start": 210.0, "f_end": 940.0, "dur": 0.34, "decay": 3.8, "noise": 0.14, "lp_cutoff": 4800.0, "vol": 0.56, "wave": "metallic"}
			])
			_play_wav(w, 1.0, -1.0)
		"stim":
			_play_wav(wav_cache.get("syringe_start"), 1.18, -1.5)
		"grapple", "jumppad":
			var w := _build_layered_wav(0.24, [
				{"f_start": 220.0, "f_end": 820.0, "dur": 0.22, "decay": 4.5, "noise": 0.22, "lp_cutoff": 3800.0, "vol": 0.54, "wave": "tri"}
			])
			_play_wav(w, 1.0, -1.2)
		_:
			_play_wav(wav_cache.get("lever_cock"), 1.0, -1.5)

func play_bow_release(draw_ratio: float = 1.0) -> void:
	_play_wav(wav_cache.get("bow_release"), lerpf(0.85, 1.08, clampf(draw_ratio, 0.0, 1.0)), -0.5)

func play_shotgun_choke_step(progress: float = 0.5) -> void:
	if muted:
		return
	var f: float = lerpf(580.0, 1480.0, clampf(progress, 0.0, 1.0))
	var w := _build_layered_wav(0.08, [
		{"f_start": f, "f_end": f * 1.18, "dur": 0.075, "decay": 8.0, "noise": 0.06, "lp_cutoff": 6000.0, "vol": 0.38, "wave": "metallic"}
	])
	_play_wav(w, 1.0, -2.0)

func play_consumable_start(heal_id: String) -> void:
	play_heal_start(heal_id)

func play_consumable_progress(heal_id: String, progress: float) -> void:
	play_heal_progress_pulse(heal_id, progress)

func play_consumable_complete(heal_id: String) -> void:
	play_heal_complete(heal_id)

func play_announcer(event_name: String) -> void:
	if muted:
		return
	var key: String = "announcer_" + event_name
	var s: AudioStream = get_sfx(key)
	if s != null and is_instance_valid(announcer_channel):
		announcer_channel.stream = s
		announcer_channel.pitch_scale = 1.0
		announcer_channel.volume_db = 1.0
		announcer_channel.play()

func play_legend_voice(legend_id: String, variant: int = -1) -> void:
	if muted or not LEGEND_VOICES.has(legend_id):
		return
	var vlist: Array = LEGEND_VOICES[legend_id]
	if vlist.is_empty():
		return
	var idx: int = variant if (variant >= 0 and variant < vlist.size()) else randi() % vlist.size()
	var path: String = str(vlist[idx])
	if ResourceLoader.exists(path) and is_instance_valid(voice_channel):
		var s: AudioStream = load(path)
		if s != null:
			voice_channel.stream = s
			voice_channel.volume_db = 1.0
			voice_channel.pitch_scale = 1.0
			voice_channel.play()

func play_grenade(grenade_type: String, action: String) -> void:
	var key := "%s_%s" % [grenade_type, action]
	if GRENADE_SOUNDS.has(key):
		var p: String = GRENADE_SOUNDS[key]
		if ResourceLoader.exists(p):
			var s: AudioStream = load(p)
			if s != null:
				_play_stream(s, randf_range(0.96, 1.04), 0.0)

