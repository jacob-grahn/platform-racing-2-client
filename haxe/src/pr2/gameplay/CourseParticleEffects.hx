package pr2.gameplay;

import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import pr2.character.ArrowSparkleEmitter;
import pr2.character.Character;
import pr2.character.Character.DjinnEmitterRequest;
import pr2.character.Character.ParticleEmitterRequest;
import pr2.character.ParticleEmitter;
import pr2.character.PhysicsParticle.PhysicsParticleParams;
import pr2.character.PositionedParticleEmitter;
import pr2.character.RainbowStarEmitter;

/** Owns particle-emitter creation, replacement, and cleanup for a race. */
class CourseParticleEffects {
	private static inline var DJINN_EMITTER_INTERVAL_MS:Int = 75;
	private static inline var DJINN_EMITTER_DURATION_MS:Int = 999999999;

	private final effectLayer:Void->Null<DisplayObjectContainer>;
	private final activeEmitters:ObjectMap<Character, ParticleEmitter> = new ObjectMap();
	private final activeDjinnEmitters:ObjectMap<Character, StringMap<ParticleEmitter>> = new ObjectMap();

	public function new(effectLayer:Void->Null<DisplayObjectContainer>) {
		this.effectLayer = effectLayer;
	}

	public function install(character:Character):Void {
		character.onStartParticleEmitter = start;
		character.onClearParticleEmitter = function():Void clear(character);
		character.onStartDjinnEmitter = startDjinn;
		character.onClearDjinnEmitters = function():Void clearDjinn(character);
	}

	private function start(request:ParticleEmitterRequest):Void {
		clear(request.target);
		var layer = effectLayer();
		if (layer == null) return;
		var emitter:Null<ParticleEmitter> = switch (request.kind) {
			case "arrowSparkle": new ArrowSparkleEmitter(request.intervalMs, request.durationMs, request.target, layer);
			case "rainbowStar": new RainbowStarEmitter(request.intervalMs, request.durationMs, request.target, layer);
			case "sparkle": new ParticleEmitter(request.intervalMs, request.durationMs, request.target, layer);
			default: null;
		};
		if (emitter != null) activeEmitters.set(request.target, emitter);
	}

	public function clear(character:Character):Void {
		var emitter = activeEmitters.get(character);
		if (emitter == null) return;
		emitter.remove();
		activeEmitters.remove(character);
	}

	public function clearAll():Void {
		for (character in [for (character in activeEmitters.keys()) character]) clear(character);
		for (character in [for (character in activeDjinnEmitters.keys()) character]) clearDjinn(character);
	}

	private function startDjinn(request:DjinnEmitterRequest):Void {
		clearDjinnSlot(request.target, request.slot);
		var layer = effectLayer();
		if (layer == null) return;
		var part = djinnTargetPart(request);
		if (part == null) return;
		var emitter = new PositionedParticleEmitter(DJINN_EMITTER_INTERVAL_MS, DJINN_EMITTER_DURATION_MS, part, layer, djinnParams(request),
			request.offsetX, request.offsetY);
		var emitters = activeDjinnEmitters.get(request.target);
		if (emitters == null) {
			emitters = new StringMap();
			activeDjinnEmitters.set(request.target, emitters);
		}
		emitters.set(request.slot, emitter);
	}

	private function djinnTargetPart(request:DjinnEmitterRequest):Null<DisplayObject> {
		return request.target.display.effectTarget(switch (request.slot) {
			case "foot1": "frontFoot";
			case "foot2": "backFoot";
			default: request.slot;
		});
	}

	private function djinnParams(request:DjinnEmitterRequest):PhysicsParticleParams {
		return {
			graphic: request.graphic, colors: request.colors, life: request.life, startAlpha: request.startAlpha,
			minVelAlpha: request.minVelAlpha, maxVelAlpha: request.maxVelAlpha, minVelX: request.minVelX, maxVelX: request.maxVelX,
			minVelY: request.minVelY, maxVelY: request.maxVelY, velScaleX: request.velScaleX, velScaleY: request.velScaleY,
			fricX: request.fricX, fricY: request.fricY, minOffsetX: request.minOffsetX, maxOffsetX: request.maxOffsetX,
			minOffsetY: request.minOffsetY, maxOffsetY: request.maxOffsetY, minScale: request.minScale, maxScale: request.maxScale
		};
	}

	private function clearDjinnSlot(character:Character, slot:String):Void {
		var emitters = activeDjinnEmitters.get(character);
		if (emitters == null) return;
		var emitter = emitters.get(slot);
		if (emitter != null) {
			emitter.remove();
			emitters.remove(slot);
		}
		if (!emitters.keys().hasNext()) activeDjinnEmitters.remove(character);
	}

	public function clearDjinn(character:Character):Void {
		var emitters = activeDjinnEmitters.get(character);
		if (emitters == null) return;
		for (slot in [for (slot in emitters.keys()) slot]) {
			var emitter = emitters.get(slot);
			if (emitter != null) emitter.remove();
			emitters.remove(slot);
		}
		activeDjinnEmitters.remove(character);
	}

	public function activeEmitterCount():Int {
		var count = 0;
		for (_ in activeEmitters.keys()) count++;
		return count;
	}

	public function activeDjinnEmitterCount():Int {
		var count = 0;
		for (emitters in activeDjinnEmitters) for (_ in emitters.keys()) count++;
		return count;
	}
}
