package pr2.character;

import haxe.Json;
import openfl.utils.Assets;

typedef RigMatrix = {
	var a:Float;
	var b:Float;
	var c:Float;
	var d:Float;
	var tx:Float;
	var ty:Float;
	var alpha:Float;
}

typedef RigPartChannels = {
	var id:Int;
	var name:String;
	var fixed:String;
	var primary:String;
	var secondary:String;
	@:optional var channelAnimations:Array<RigPartChannelAnimation>;
}

typedef RigPartChannelAnimation = {
	var channel:String;
	var frameRate:Int;
	var endBehavior:String;
	var frames:Array<String>;
}

typedef RigPartKind = {
	var registration:RigPoint;
	var variants:Array<RigPartChannels>;
}

typedef RigPoint = {
	var x:Float;
	var y:Float;
}

typedef RigParts = {
	var head:RigPartKind;
	var body:RigPartKind;
	var feet:RigPartKind;
	var hat:RigPartKind;
}

typedef RigEmptyPartIds = {
	var head:Array<Int>;
	var body:Array<Int>;
	var feet:Array<Int>;
}

typedef RigHatAttachmentSlot = {
	var name:String;
	var matrix:RigMatrix;
}

typedef RigHatAttachment = {
	var headId:Int;
	var slots:Array<RigHatAttachmentSlot>;
}

typedef RigFredDefinition = {
	var bodyId:Int;
	var hiddenSlots:Array<String>;
	var hatAttachments:Array<RigHatAttachmentSlot>;
}

typedef RigHeldItem = {
	var name:String;
	var matrix:RigMatrix;
	var frames:Array<String>;
	var actionStartFrame:Int;
	var actionEndBehavior:String;
}

typedef RigSlot = {
	var name:String;
	var parent:String;
	var partKind:Null<String>;
	var asset:Null<String>;
	var drawOrder:Int;
	var frames:Array<RigMatrix>;
}

typedef RigAnimation = {
	var name:String;
	var frameRate:Int;
	var frameCount:Int;
	var endBehavior:String;
	var endSignal:Null<String>;
	var root:RigMatrix;
	var slots:Array<RigSlot>;
}

typedef CharacterRigDefinition = {
	var format:String;
	var version:Int;
	var source:String;
	var parts:RigParts;
	var emptyPartIds:RigEmptyPartIds;
	var hatAttachments:Array<RigHatAttachment>;
	var hatStackStep:RigPoint;
	var fred:RigFredDefinition;
	var items:Array<RigHeldItem>;
	var animations:Array<RigAnimation>;
}

/** Loader and validation boundary for neutral, generated character-rig data. */
class CharacterRig {
	public static inline var CLASSIC_ASSET:String = "assets/rigs/classic-standing.json";

	public static function loadClassic():CharacterRigDefinition {
		var content = Assets.getText(CLASSIC_ASSET);
		#if sys
		if (content == null) content = sys.io.File.getContent("art/rigs/classic-standing.json");
		#end
		if (content == null) throw 'Missing character rig $CLASSIC_ASSET';
		return parse(content);
	}

	public static function parse(content:String):CharacterRigDefinition {
		var rig:CharacterRigDefinition = cast Json.parse(content);
		if (rig.format != "pr2-character-rig" || rig.version != 7) {
			throw 'Unsupported character rig ${rig.format} v${rig.version}';
		}
		if (rig.animations == null || rig.animations.length == 0) {
			throw "Character rig has no renderable animation";
		}
		for (kind in [rig.parts.head, rig.parts.body, rig.parts.feet, rig.parts.hat]) {
			if (kind.variants == null || kind.variants.length == 0) throw "Character rig has an empty part kind";
			for (variant in kind.variants) {
				if (variant.channelAnimations == null) continue;
				for (channel in variant.channelAnimations) {
					if (["primary", "static", "secondary"].indexOf(channel.channel) == -1) throw 'Character rig part ${variant.name} has an invalid animated channel';
					if (channel.frameRate <= 0 || channel.frames == null || channel.frames.length == 0 || channel.endBehavior != "loop") {
						throw 'Character rig part ${variant.name} has invalid channel animation data';
					}
				}
			}
		}
		if (rig.emptyPartIds == null) throw "Character rig has no authored empty-part records";
		if (rig.hatAttachments == null || rig.hatAttachments.length != rig.parts.head.variants.length) {
			throw "Character rig has invalid standard-head hat attachments";
		}
		for (attachment in rig.hatAttachments) {
			if (attachment.slots == null || attachment.slots.length != 4) throw 'Head ${attachment.headId} has invalid hat slots';
		}
		if (rig.fred == null || rig.fred.bodyId != 29 || rig.fred.hatAttachments == null || rig.fred.hatAttachments.length != 4) {
			throw "Character rig has invalid Fred hierarchy data";
		}
		if (rig.items == null || rig.items.length != 9) throw "Character rig has invalid held-item data";
		for (item in rig.items) {
			if (item.frames == null || item.frames.length == 0) throw 'Character rig item ${item.name} has no frames';
			if (item.actionStartFrame < 1 || item.actionStartFrame > item.frames.length) throw 'Character rig item ${item.name} has an invalid action start';
			if (["hold", "loop"].indexOf(item.actionEndBehavior) == -1) throw 'Character rig item ${item.name} has invalid end behavior';
		}
		for (animation in rig.animations) {
			if (["loop", "hold", "hold-complete"].indexOf(animation.endBehavior) == -1) {
				throw 'Character rig animation ${animation.name} has invalid end behavior ${animation.endBehavior}';
			}
			if (animation.frameCount <= 0 || animation.slots == null || animation.slots.length == 0) {
				throw 'Character rig animation ${animation.name} is empty';
			}
			for (slot in animation.slots) {
				if (slot.frames == null || slot.frames.length != animation.frameCount) {
					throw 'Character rig slot ${slot.name} has invalid frame count';
				}
			}
		}
		return rig;
	}

	public static function animation(rig:CharacterRigDefinition, name:String):RigAnimation {
		for (candidate in rig.animations) if (candidate.name == name) return candidate;
		throw 'Character rig has no animation $name';
	}

	public static function hatAttachment(rig:CharacterRigDefinition, headId:Int):RigHatAttachment {
		for (attachment in rig.hatAttachments) if (attachment.headId == headId) return attachment;
		throw 'Character rig has no standard hat attachment for head $headId';
	}

	public static function item(rig:CharacterRigDefinition, name:String):RigHeldItem {
		for (candidate in rig.items) if (candidate.name == name) return candidate;
		throw 'Character rig has no held item $name';
	}

	private function new() {}
}
