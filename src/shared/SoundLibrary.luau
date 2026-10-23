--[[
	Toca sons do catálogo (SoundCatalog, gerado de assets/audio/catalog.json).

	Variação SEM novo upload: cada chamada pode modular velocidade, volume, pitch
	aleatório e efeitos (Equalizer, Reverb, Distortion, PitchShift, Echo, Chorus,
	Flange, Tremolo, Compressor). Prefira isto a subir um áudio novo.

	SoundLibrary.play("geppo", rootPart)
	SoundLibrary.play("geppo", rootPart, { playbackSpeed = 0.8, effects = { Reverb = { DecayTime = 1.5 } } })
	SoundLibrary.layer({ "explosao_grave", "vento_rajada" }, part) -- camadas simultâneas
]]

local Debris = game:GetService("Debris")

local SoundCatalog = require(script.Parent.SoundCatalog)

export type Options = {
	volume: number?,
	playbackSpeed: number?,
	pitchJitter: number?, -- ±fração aleatória na PlaybackSpeed (0.05 = ±5%)
	effects: { [string]: { [string]: any } }?,
	looped: boolean?,
}

local SoundLibrary = {}

local EFFECT_CLASSES = {
	Equalizer = "EqualizerSoundEffect",
	Reverb = "ReverbSoundEffect",
	Distortion = "DistortionSoundEffect",
	PitchShift = "PitchShiftSoundEffect",
	Echo = "EchoSoundEffect",
	Chorus = "ChorusSoundEffect",
	Flange = "FlangeSoundEffect",
	Tremolo = "TremoloSoundEffect",
	Compressor = "CompressorSoundEffect",
}

local rng = Random.new()

local function applyEffects(sound: Sound, effects: { [string]: { [string]: any } }?)
	if not effects then
		return
	end
	for kind, props in effects do
		local className = EFFECT_CLASSES[kind]
		assert(className, `SoundLibrary: efeito desconhecido "{kind}"`)
		local effect = Instance.new(className)
		for key, value in props do
			(effect :: any)[key] = value
		end
		effect.Parent = sound
	end
end

function SoundLibrary.get(name: string)
	local entry = SoundCatalog[name]
	assert(entry, `SoundLibrary: som "{name}" não está no catálogo`)
	return entry
end

function SoundLibrary.create(name: string, parent: Instance, opts: Options?): Sound
	local entry = SoundLibrary.get(name)
	local o: Options = opts or {}
	local jitter = o.pitchJitter or entry.pitchJitter or 0

	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = `rbxassetid://{entry.assetId}`
	sound.Volume = o.volume or entry.volume or 1
	sound.PlaybackSpeed = (o.playbackSpeed or entry.playbackSpeed or 1) * (1 + rng:NextNumber(-jitter, jitter))
	sound.Looped = o.looped or false
	applyEffects(sound, if o.effects ~= nil then o.effects else entry.effects)
	sound.Parent = parent
	return sound
end

function SoundLibrary.play(name: string, parent: Instance, opts: Options?): Sound
	local sound = SoundLibrary.create(name, parent, opts)
	sound:Play()
	if not sound.Looped then
		Debris:AddItem(sound, math.max(sound.TimeLength / sound.PlaybackSpeed, 0) + 2)
	end
	return sound
end

function SoundLibrary.layer(names: { string }, parent: Instance, opts: Options?): { Sound }
	local sounds = {}
	for _, name in names do
		table.insert(sounds, SoundLibrary.play(name, parent, opts))
	end
	return sounds
end

function SoundLibrary.byCategory(category: string): { string }
	local names = {}
	for name, entry in SoundCatalog do
		if entry.category == category then
			table.insert(names, name)
		end
	end
	table.sort(names)
	return names
end

return SoundLibrary
