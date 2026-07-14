package pr2.gameplay;

import haxe.ds.ObjectMap;
import openfl.media.SoundChannel;
import openfl.utils.Assets;
import pr2.audio.SoundEffects;
import pr2.character.Character;
import pr2.lobby.account.Settings;

typedef RaceCameraOffset = {
	var x:Float;
	var y:Float;
}

class RaceSounds {
	// JumpSound -> sound552 (AssetCatalog DOMSoundItem).
	public static inline var JUMP_SOUND:String = "assets/audio/sfx/jump.mp3";
	// SuperJumpSound -> sound913 (AssetCatalog DOMSoundItem).
	public static inline var SUPER_JUMP_SOUND:String = "assets/audio/sfx/super_jump.mp3";
	// ThumpSound -> sound448 (AssetCatalog DOMSoundItem), used by Block.hit.
	public static inline var BLOCK_BUMP_SOUND:String = "assets/audio/sfx/block_thump.mp3";
	// StarSound -> sound452 (AssetCatalog DOMSoundItem), used by ItemBlock.useSupply.
	public static inline var ITEM_BLOCK_SOUND:String = "assets/audio/sfx/star.mp3";
	// BumpHappySound -> sound473 (AssetCatalog DOMSoundItem), used by Character.gainHeart.
	public static inline var BUMP_HAPPY_SOUND:String = "assets/audio/sfx/bump_happy.mp3";
	// BumpSadSound -> sound460 (AssetCatalog DOMSoundItem), used by SadBlock.useSupply.
	public static inline var BUMP_SAD_SOUND:String = "assets/audio/sfx/bump_sad.mp3";
	// TickTockSound -> sound453 (AssetCatalog DOMSoundItem), used by TimeBlock.useSupply.
	public static inline var TICK_TOCK_SOUND:String = "assets/audio/sfx/tick_tock.mp3";
	// SquashSound -> sound912, used by the Jiggmin hat stomp.
	public static inline var SQUASH_SOUND:String = "assets/audio/sfx/squash.mp3";
	// VictorySound -> sound442, played whenever the local player finishes.
	public static inline var VICTORY_SOUND:String = "assets/audio/sfx/victory.mp3";
	// SpeedUpSound -> sound550; SlowDownSound -> sound551, used by Character sparkles.
	public static inline var SPEED_UP_SOUND:String = "assets/audio/sfx/speed_up.mp3";
	public static inline var SLOW_DOWN_SOUND:String = "assets/audio/sfx/slow_down.mp3";
	// YeahSound -> yeah, used by Artifact hat activation.
	public static inline var YEAH_SOUND:String = "assets/audio/sfx/artifact_yeah.wav";
	// EngineSound -> sound549, looped while Character.beginJet is active.
	public static inline var ENGINE_SOUND:String = "assets/audio/sfx/jet_engine.wav";

	private final cameraOffset:Void->RaceCameraOffset;
	private var activeJetSounds:ObjectMap<Character, Bool> = new ObjectMap();
	private var jetSoundChannels:ObjectMap<Character, SoundChannel> = new ObjectMap();

	public function new(cameraOffset:Void->RaceCameraOffset) {
		this.cameraOffset = cameraOffset;
	}

	public function playWorldJumpSound(worldX:Float, worldY:Float):Void {
		playSpatial(JUMP_SOUND, worldX, worldY, 0.75);
	}

	public function playCharacterSound(request:pr2.character.Character.CharacterSoundRequest):Void {
		var path = switch (request.kind) {
			case "bumpHappy": BUMP_HAPPY_SOUND;
			case "squash": SQUASH_SOUND;
			case "speedUp": SPEED_UP_SOUND;
			case "slowDown": SLOW_DOWN_SOUND;
			case "artifactYeah": YEAH_SOUND;
			default: null;
		}
		if (path != null) {
			playSpatial(path, request.x, request.y, request.volume);
		}
	}

	public function startJetSound(request:pr2.character.Character.CharacterSoundRequest):Void {
		stopJetSound(request.target);
		markJetSoundActive(request.target);
		if (Assets.exists(ENGINE_SOUND)) {
			var offset = cameraOffset();
			var channel = SoundEffects.playGameSound(Assets.getSound(ENGINE_SOUND), request.x, request.y, offset.x, offset.y, request.volume, 0, 999);
			if (channel != null) {
				jetSoundChannels.set(request.target, channel);
			}
		}
	}

	public function markJetSoundActive(character:Character):Void {
		activeJetSounds.set(character, true);
	}

	public function hasJetSound(character:Character):Bool {
		return activeJetSounds.exists(character) || jetSoundChannels.exists(character);
	}

	public function activeJetCharacters():Array<Character> {
		return [for (character in activeJetSounds.keys()) character];
	}

	public function stopJetSound(character:Character):Void {
		activeJetSounds.remove(character);
		var channel = jetSoundChannels.get(character);
		if (channel != null) {
			channel.stop();
			jetSoundChannels.remove(character);
		}
	}

	public function playSuperJumpSound():Void {
		playGlobal(SUPER_JUMP_SOUND, 1);
	}

	public function playBlockBumpSound(worldX:Float, worldY:Float):Void {
		playSpatial(BLOCK_BUMP_SOUND, worldX, worldY, 0.9);
	}

	public function playItemBlockSound():Void {
		playGlobal(ITEM_BLOCK_SOUND, 0.6);
	}

	public function playStatBlockSound(path:String):Void {
		playGlobal(path, 0.75);
	}

	public function playTimeBlockSound():Void {
		playGlobal(TICK_TOCK_SOUND, 1);
	}

	public function playVictorySound():Void {
		playGlobal(VICTORY_SOUND, 1);
	}

	private function playSpatial(path:String, worldX:Float, worldY:Float, volume:Float):Void {
		if (Assets.exists(path)) {
			var offset = cameraOffset();
			SoundEffects.playGameSound(Assets.getSound(path), worldX, worldY, offset.x, offset.y, volume);
		}
	}

	private function playGlobal(path:String, volume:Float):Void {
		if (Assets.exists(path)) {
			SoundEffects.playSound(Assets.getSound(path), volume * (Settings.soundLevel / 100));
		}
	}
}
