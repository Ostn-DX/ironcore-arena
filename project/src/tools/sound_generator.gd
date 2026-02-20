extends Node
class_name SoundGenerator
## SoundGenerator — generates placeholder sound effects using synthesis.
## Uses Godot's audio generation capabilities for MVP sounds.

const SAMPLE_RATE: int = 44100

# Waveform types
enum WaveType { SINE, SQUARE, SAW, TRIANGLE, NOISE }


func generate_click() -> AudioStreamWAV:
	## Generate a UI click sound
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	var data: PackedByteArray = PackedByteArray()
	
	var duration: float = 0.05
	var samples: int = int(duration * SAMPLE_RATE)
	
	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var freq: float = 2000.0 * (1.0 - t / duration)
		var sample: float = _generate_wave(freq, t, WaveType.SINE) * (1.0 - t / duration)
		data.append(_float_to_byte(sample * 0.5))
	
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	stream.mix_rate = SAMPLE_RATE
	
	return stream


func generate_hover() -> AudioStreamWAV:
	## Generate a UI hover sound
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	var data: PackedByteArray = PackedByteArray()
	
	var duration: float = 0.03
	var samples: int = int(duration * SAMPLE_RATE)
	
	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var freq: float = 800.0
		var sample: float = _generate_wave(freq, t, WaveType.SINE) * (1.0 - t / duration) * 0.3
		data.append(_float_to_byte(sample))
	
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	stream.mix_rate = SAMPLE_RATE
	
	return stream


func generate_confirm() -> AudioStreamWAV:
	## Generate a confirmation sound
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	var data: PackedByteArray = PackedByteArray()
	
	var duration: float = 0.15
	var samples: int = int(duration * SAMPLE_RATE)
	
	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var freq: float = 440.0 + 440.0 * (t / duration)  # Rising pitch
		var sample: float = _generate_wave(freq, t, WaveType.SINE) * (1.0 - t / duration) * 0.5
		data.append(_float_to_byte(sample))
	
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	stream.mix_rate = SAMPLE_RATE
	
	return stream


func generate_cancel() -> AudioStreamWAV:
	## Generate a cancel/error sound
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	var data: PackedByteArray = PackedByteArray()
	
	var duration: float = 0.15
	var samples: int = int(duration * SAMPLE_RATE)
	
	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var freq: float = 880.0 - 440.0 * (t / duration)  # Falling pitch
		var sample: float = _generate_wave(freq, t, WaveType.SQUARE) * (1.0 - t / duration) * 0.3
		data.append(_float_to_byte(sample))
	
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	stream.mix_rate = SAMPLE_RATE
	
	return stream


func generate_weapon_fire() -> AudioStreamWAV:
	## Generate weapon fire sound
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	var data: PackedByteArray = PackedByteArray()
	
	var duration: float = 0.1
	var samples: int = int(duration * SAMPLE_RATE)
	
	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var freq: float = 150.0 + randf() * 50.0  # Noisy burst
		var sample: float = _generate_wave(freq, t, WaveType.NOISE) * (1.0 - t / duration)
		data.append(_float_to_byte(sample * 0.6))
	
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	stream.mix_rate = SAMPLE_RATE
	
	return stream


func generate_explosion() -> AudioStreamWAV:
	## Generate explosion sound
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	var data: PackedByteArray = PackedByteArray()
	
	var duration: float = 0.3
	var samples: int = int(duration * SAMPLE_RATE)
	
	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var sample: float = _generate_wave(100.0, t, WaveType.NOISE) * (1.0 - t / duration) * 0.8
		# Low pass filter effect
		if i > 0:
			var prev: float = _byte_to_float(data[i - 1])
			sample = (sample + prev) * 0.5
		data.append(_float_to_byte(sample))
	
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	stream.mix_rate = SAMPLE_RATE
	
	return stream


func _generate_wave(freq: float, time: float, type: WaveType) -> float:
	## Generate a single sample of a waveform
	var phase: float = fmod(freq * time, 1.0)
	
	match type:
		WaveType.SINE:
			return sin(phase * TAU)
		WaveType.SQUARE:
			return 1.0 if phase < 0.5 else -1.0
		WaveType.SAW:
			return phase * 2.0 - 1.0
		WaveType.TRIANGLE:
			return 4.0 * abs(phase - 0.5) - 1.0
		WaveType.NOISE:
			return randf_range(-1.0, 1.0)
		_:
			return 0.0


func _float_to_byte(sample: float) -> int:
	## Convert float sample (-1 to 1) to byte (0 to 255)
	var clamped: float = clamp(sample, -1.0, 1.0)
	return int((clamped + 1.0) * 127.5)


func _byte_to_float(byte: int) -> float:
	## Convert byte to float sample
	return (float(byte) / 127.5) - 1.0


func save_sound(stream: AudioStreamWAV, path: String) -> void:
	## Save sound to file
	# Note: Godot doesn't have built-in WAV saving in release builds
	# This is a placeholder for the actual implementation
	print("SoundGenerator: Would save sound to ", path)


func generate_all_mvp_sounds() -> void:
	## Generate all MVP sounds
	print("SoundGenerator: Generating MVP sounds...")
	
	var sounds: Dictionary = {
		"ui_click": generate_click(),
		"ui_hover": generate_hover(),
		"ui_confirm": generate_confirm(),
		"ui_cancel": generate_cancel(),
		"weapon_fire": generate_weapon_fire(),
		"explosion_small": generate_explosion()
	}
	
	for name in sounds:
		print("SoundGenerator: Generated ", name)
	
	print("SoundGenerator: MVP sounds generated!")
	return sounds
