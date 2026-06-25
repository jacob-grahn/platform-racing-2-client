package pr2.audio;

import haxe.Timer;
import haxe.ds.ObjectMap;
import openfl.events.Event;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import openfl.utils.Assets;
import pr2.generated.assets.AssetTypes.FrameDef;
import pr2.generated.assets.AssetTypes.SoundEnvelopePointDef;
import pr2.lobby.account.Settings;

/**
	Playback for Flash timeline event sounds.

	Event/default-sync sounds start once when their keyframe is entered and then
	run independently of the timeline. Authored in/out points and volume
	envelopes use Animate's 44.1 kHz sample units. Stop-sync frames terminate all
	active instances of their named library sound. Start-sync frames behave like
	event sounds unless that library sound is already active. Stream sync,
	looping are handled by later runtime parity work. Playback started by a
	PR2MovieClip is owned by that timeline and stopped when the clip is disposed.
**/
class TimelineSound {
	private static inline var SAMPLES_PER_MILLISECOND:Float = 44.1;
	private static inline var MAX_ENVELOPE_LEVEL:Float = 32768;
	private static var activeByPath:Map<String, Array<ActiveTimelineSound>> = new Map();
	private static var activeByOwner:ObjectMap<Dynamic, Array<ActiveTimelineSound>> = new ObjectMap();

	public static function processFrame(frame:FrameDef, ?owner:Dynamic):Void {
		if (frame.soundName == null) {
			return;
		}
		if (frame.soundSync == "stop") {
			stopLibrarySound(frame.soundName);
			return;
		}
		if (frame.soundSync == "start" && isLibrarySoundActive(frame.soundName)) {
			return;
		}
		playEventFrame(frame, owner);
	}

	public static function playEventFrame(frame:FrameDef, ?owner:Dynamic):Void {
		if (frame.soundName == null || Settings.soundLevel <= 0) {
			return;
		}

		var path = assetPath(frame.soundName);
		var sound = Assets.getSound(path);
		if (sound != null) {
			var startTime = sample44ToMilliseconds(valueOrZero(frame.inPoint44));
			var initialMix = envelopeMixAt(frame.soundEnvelope, 0);
			var channel = sound.play(startTime, 0, soundTransform(initialMix.left, initialMix.right));
			if (channel != null) {
				var active = registerActive(path, channel.stop, owner);
				channel.addEventListener(Event.SOUND_COMPLETE, function(_):Void unregisterActive(active));
				if (frame.outPoint44 != null || hasChangingEnvelope(frame.soundEnvelope)) {
					monitor(channel, frame, startTime, function():Void unregisterActive(active));
				}
			}
		}
	}

	public static function stopLibrarySound(libraryName:String):Void {
		var path = assetPath(libraryName);
		var active = activeByPath.get(path);
		if (active == null) {
			return;
		}
		for (instance in active.copy()) {
			unregisterActive(instance);
			instance.stop();
		}
	}

	public static function stopOwner(owner:Dynamic):Void {
		if (owner == null) {
			return;
		}
		var active = activeByOwner.get(owner);
		if (active == null) {
			return;
		}
		for (instance in active.copy()) {
			unregisterActive(instance);
			instance.stop();
		}
	}

	public static function isLibrarySoundActive(libraryName:String):Bool {
		var active = activeByPath.get(assetPath(libraryName));
		return active != null && active.length > 0;
	}

	/**
		Register timeline-owned playback. Public so deterministic tests and future
		sync-mode backends can use the same stop registry without loading audio.
	**/
	public static function registerActive(libraryNameOrPath:String, stop:Void->Void, ?owner:Dynamic):ActiveTimelineSound {
		var path = StringTools.startsWith(libraryNameOrPath, "assets/")
			? libraryNameOrPath
			: assetPath(libraryNameOrPath);
		var active = {path: path, stop: stop, owner: owner};
		var instances = activeByPath.get(path);
		if (instances == null) {
			instances = [];
			activeByPath.set(path, instances);
		}
		instances.push(active);
		if (owner != null) {
			var owned = activeByOwner.get(owner);
			if (owned == null) {
				owned = [];
				activeByOwner.set(owner, owned);
			}
			owned.push(active);
		}
		return active;
	}

	public static inline function sample44ToMilliseconds(sample44:Int):Float {
		return sample44 / SAMPLES_PER_MILLISECOND;
	}

	public static function envelopeMixAt(envelope:Array<SoundEnvelopePointDef>, mark44:Int):{left:Float, right:Float} {
		if (envelope == null || envelope.length == 0) {
			return {left: 1, right: 1};
		}

		var first = envelope[0];
		var firstMark = valueOrZero(first.mark44);
		if (mark44 <= firstMark || envelope.length == 1) {
			return pointMix(first);
		}

		for (index in 1...envelope.length) {
			var previous = envelope[index - 1];
			var next = envelope[index];
			var previousMark = valueOrZero(previous.mark44);
			var nextMark = valueOrZero(next.mark44);
			if (mark44 <= nextMark) {
				if (nextMark <= previousMark) {
					return pointMix(next);
				}
				var ratio = (mark44 - previousMark) / (nextMark - previousMark);
				var previousMix = pointMix(previous);
				var nextMix = pointMix(next);
				return {
					left: previousMix.left + (nextMix.left - previousMix.left) * ratio,
					right: previousMix.right + (nextMix.right - previousMix.right) * ratio
				};
			}
		}

		return pointMix(envelope[envelope.length - 1]);
	}

	public static function assetPath(libraryName:String):String {
		var slash = libraryName.lastIndexOf("/");
		var fileName = slash < 0 ? libraryName : libraryName.substr(slash + 1);
		return "assets/audio/sfx/" + fileName;
	}

	private static function monitor(channel:SoundChannel, frame:FrameDef, startTime:Float, onStop:Void->Void):Void {
		var timer = new Timer(15);
		var stopMonitoring = function():Void timer.stop();
		channel.addEventListener(Event.SOUND_COMPLETE, function(_):Void stopMonitoring());
		timer.run = function():Void {
			if (frame.outPoint44 != null && channel.position >= sample44ToMilliseconds(frame.outPoint44)) {
				channel.stop();
				onStop();
				stopMonitoring();
				return;
			}

			var elapsedMilliseconds = Math.max(0, channel.position - startTime);
			var mark44 = Std.int(Math.round(elapsedMilliseconds * SAMPLES_PER_MILLISECOND));
			var mix = envelopeMixAt(frame.soundEnvelope, mark44);
			channel.soundTransform = soundTransform(mix.left, mix.right);
		};
	}

	private static function unregisterActive(active:ActiveTimelineSound):Void {
		var instances = activeByPath.get(active.path);
		if (instances == null) {
			return;
		}
		instances.remove(active);
		if (instances.length == 0) {
			activeByPath.remove(active.path);
		}
		if (active.owner != null) {
			var owned = activeByOwner.get(active.owner);
			if (owned != null) {
				owned.remove(active);
				if (owned.length == 0) {
					activeByOwner.remove(active.owner);
				}
			}
		}
	}

	private static function soundTransform(left:Float, right:Float):SoundTransform {
		var setting = Settings.soundLevel / 100;
		var strongest = Math.max(left, right);
		var volume = setting * strongest;
		var pan = strongest <= 0 ? 0 : (right - left) / strongest;
		return new SoundTransform(volume, pan);
	}

	private static function hasChangingEnvelope(envelope:Array<SoundEnvelopePointDef>):Bool {
		return envelope != null && envelope.length > 1;
	}

	private static function pointMix(point:SoundEnvelopePointDef):{left:Float, right:Float} {
		return {
			left: clampLevel(valueOrZero(point.level0) / MAX_ENVELOPE_LEVEL),
			right: clampLevel(valueOrZero(point.level1) / MAX_ENVELOPE_LEVEL)
		};
	}

	private static inline function clampLevel(value:Float):Float {
		return Math.max(0, Math.min(1, value));
	}

	private static inline function valueOrZero(value:Null<Int>):Int {
		return value == null ? 0 : value;
	}

	private function new() {}
}

typedef ActiveTimelineSound = {
	var path:String;
	var stop:Void->Void;
	var owner:Dynamic;
}
