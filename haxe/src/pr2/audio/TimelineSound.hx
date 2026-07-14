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
	event sounds unless that library sound is already active. Authored repeat
	counts and continuous-loop mode map to OpenFL's additional-loop count. Stream
	sounds seek from their timeline-frame offset, continue across sequential
	frames, and stop when their owning timeline stops or is disposed.
**/
class TimelineSound {
	private static inline var SAMPLES_PER_MILLISECOND:Float = 44.1;
	private static inline var TIMELINE_FRAME_RATE:Float = 27;
	private static inline var MAX_ENVELOPE_LEVEL:Float = 32768;
	private static inline var CONTINUOUS_LOOPS:Int = 9999;
	private static var activeByPath:Map<String, Array<ActiveTimelineSound>> = new Map();
	private static var activeByOwner:ObjectMap<Dynamic, Array<ActiveTimelineSound>> = new ObjectMap();
	private static var streamByOwner:ObjectMap<Dynamic, ActiveTimelineSound> = new ObjectMap();

	public static function processFrame(
		frame:FrameDef,
		?owner:Dynamic,
		?timelineFrame:Int,
		sequential:Bool = false,
		streamEnabled:Bool = true
	):Void {
		if (frame.soundName == null) {
			return;
		}
		if (frame.soundSync == "stream") {
			if (streamEnabled) {
				playStreamFrame(frame, owner, timelineFrame == null ? 1 : timelineFrame, sequential);
			} else {
				stopStream(owner);
			}
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

	public static function playStreamFrame(frame:FrameDef, owner:Dynamic, timelineFrame:Int, sequential:Bool):Void {
		if (owner == null || frame.soundName == null) {
			return;
		}

		var path = assetPath(frame.soundName);
		var current = streamByOwner.get(owner);
		if (sequential && current != null && current.path == path && current.streamFrame == frame.index) {
			return;
		}
		stopStream(owner);
		if (Settings.soundLevel <= 0) {
			return;
		}

		var sound = Assets.getSound(path);
		if (sound == null) {
			return;
		}
		var startSample44 = streamSampleAt(frame, timelineFrame);
		if (frame.outPoint44 != null && startSample44 >= frame.outPoint44) {
			return;
		}
		var startTime = sample44ToMilliseconds(startSample44);
		var elapsedSample44 = startSample44 - valueOrZero(frame.inPoint44);
		var initialMix = envelopeMixAt(frame.soundEnvelope, elapsedSample44);
		var channel = sound.play(startTime, 0, soundTransform(initialMix.left, initialMix.right));
		if (channel == null) {
			return;
		}

		var stopMonitoring:Null<Void->Void> = null;
		var active = registerActive(path, channel.stop, owner, function():Void {
			if (stopMonitoring != null) {
				stopMonitoring();
			}
		});
		active.streamFrame = frame.index;
		streamByOwner.set(owner, active);
		channel.addEventListener(Event.SOUND_COMPLETE, function(_):Void unregisterActive(active));
		if (frame.outPoint44 != null || hasChangingEnvelope(frame.soundEnvelope)) {
			stopMonitoring = monitor(channel, frame, startTime, elapsedSample44, function():Void unregisterActive(active));
		}
	}

	public static function stopStream(owner:Dynamic):Void {
		if (owner == null) {
			return;
		}
		var active = streamByOwner.get(owner);
		if (active == null) {
			return;
		}
		unregisterActive(active);
		active.stop();
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
			var channel = sound.play(startTime, playbackLoops(frame), soundTransform(initialMix.left, initialMix.right));
			if (channel != null) {
				var stopMonitoring:Null<Void->Void> = null;
				var active = registerActive(path, channel.stop, owner, function():Void {
					if (stopMonitoring != null) {
						stopMonitoring();
					}
				});
				channel.addEventListener(Event.SOUND_COMPLETE, function(_):Void unregisterActive(active));
				if (frame.outPoint44 != null || hasChangingEnvelope(frame.soundEnvelope)) {
					stopMonitoring = monitor(channel, frame, startTime, 0, function():Void unregisterActive(active));
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
	public static function registerActive(
		libraryNameOrPath:String,
		stop:Void->Void,
		?owner:Dynamic,
		?cleanup:Void->Void
	):ActiveTimelineSound {
		var path = StringTools.startsWith(libraryNameOrPath, "assets/")
			? libraryNameOrPath
			: assetPath(libraryNameOrPath);
		var active = {
			path: path,
			stop: function():Void {
				stop();
				if (cleanup != null) {
					cleanup();
				}
			},
			owner: owner
		};
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

	public static function streamSampleAt(frame:FrameDef, timelineFrame:Int):Int {
		var keyframe = frame.index == null ? 0 : frame.index;
		var elapsedFrames = Math.max(0, timelineFrame - 1 - keyframe);
		return valueOrZero(frame.inPoint44)
			+ Std.int(Math.round(elapsedFrames * SAMPLES_PER_MILLISECOND * 1000 / TIMELINE_FRAME_RATE));
	}

	public static function playbackLoops(frame:FrameDef):Int {
		if (frame.soundLoopMode == "loop") {
			return CONTINUOUS_LOOPS;
		}
		return frame.soundLoop == null ? 0 : Std.int(Math.max(0, frame.soundLoop - 1));
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
		var runtimeFileName = switch (fileName) {
			case "sound57.mp3": "intro_timeline_sound_01.mp3";
			case "sound58.mp3": "intro_timeline_sound_02.mp3";
			case "sound62.mp3": "intro_timeline_sound_03.mp3";
			case "sound63.mp3": "intro_timeline_sound_04.mp3";
			case "sound64.mp3": "intro_timeline_sound_05.mp3";
			case "sound67.mp3": "intro_timeline_sound_06.mp3";
			case "sound68.mp3": "intro_timeline_sound_07.mp3";
			case "sound81.mp3": "logo_theme.mp3";
			default: fileName;
		}
		return "assets/audio/sfx/" + runtimeFileName;
	}

	private static function monitor(
		channel:SoundChannel,
		frame:FrameDef,
		startTime:Float,
		initialElapsedSample44:Int = 0,
		onStop:Void->Void
	):Void->Void {
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
			var mark44 = initialElapsedSample44 + Std.int(Math.round(elapsedMilliseconds * SAMPLES_PER_MILLISECOND));
			var mix = envelopeMixAt(frame.soundEnvelope, mark44);
			channel.soundTransform = soundTransform(mix.left, mix.right);
		};
		return stopMonitoring;
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
			if (streamByOwner.get(active.owner) == active) {
				streamByOwner.remove(active.owner);
			}
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
	@:optional var streamFrame:Int;
}
