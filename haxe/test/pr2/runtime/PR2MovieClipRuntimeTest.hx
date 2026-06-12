package pr2.runtime;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import pr2.character.CharacterAppearance;
import pr2.generated.assets.AssetTypes.SymbolAssetDef;

class PR2MovieClipRuntimeTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testTimelineControls();
		testFrameScriptHooks();
		testNamedChildAccessAndElementProperties();
		testColorTransforms();
		testLeafVectorShapes();
		testGeneratedCharacterNamedChildren();
		testTimelineCompositionPreservesPartSelection();
		testGeneratedCharacterPartIdSelection();
		trace('PR2MovieClipRuntimeTest passed $assertions assertions');
	}

	private static function testTimelineControls():Void {
		var clip = new PR2MovieClip(makeSymbol());

		assertEquals(1, clip.currentFrame, "constructor starts on frame 1");
		assertEquals(4, clip.totalFrames, "totalFrames expands layer frame durations");
		assertEquals(2, clip.currentLabels.length, "currentLabels exposes timeline labels");
		assertEquals("intro", clip.currentLabels[0].name, "first label name");
		assertEquals(1, clip.currentLabels[0].frame, "first label frame is one-based");
		assertEquals("middle", clip.currentLabels[1].name, "second label name");
		assertEquals(3, clip.currentLabels[1].frame, "second label frame is one-based");

		clip.gotoAndStop(3);
		assertEquals(3, clip.currentFrame, "gotoAndStop accepts numeric frames");
		clip.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(3, clip.currentFrame, "stop prevents enter-frame advancement");

		clip.gotoAndStop("intro");
		assertEquals(1, clip.currentFrame, "gotoAndStop resolves labels");

		clip.gotoAndPlay("middle");
		assertEquals(3, clip.currentFrame, "gotoAndPlay resolves labels before playing");
		clip.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(4, clip.currentFrame, "play advances on enter-frame");
		clip.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(1, clip.currentFrame, "play wraps after the final frame");

		assertThrows(function() clip.gotoAndStop(0), "frame 0 is rejected");
		assertThrows(function() clip.gotoAndStop(5), "frame past totalFrames is rejected");
		assertThrows(function() clip.gotoAndStop("missing"), "unknown labels are rejected");
	}

	private static function testFrameScriptHooks():Void {
		var clip = new PR2MovieClip(makeSymbol());
		var hits:Array<Int> = [];

		clip.setFrameScript(2, function() hits.push(clip.currentFrame));
		clip.gotoAndStop(3);
		assertEquals("3", hits.join(","), "frame scripts run after gotoAndStop renders target frame");

		clip.gotoAndPlay(2);
		clip.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals("3,3", hits.join(","), "frame scripts run during playback");

		clip.setFrameScript(2, null);
		clip.gotoAndStop(3);
		assertEquals("3,3", hits.join(","), "null frame script clears hook");

		assertThrows(function() clip.setFrameScript(-1, function() {}), "negative frame-script indexes are rejected");
		assertThrows(function() clip.setFrameScript(4, function() {}), "frame-script indexes past totalFrames are rejected");
	}

	private static function testNamedChildAccessAndElementProperties():Void {
		var clip = new PR2MovieClip(makeSymbol());

		assertEquals(2, clip.numChildren, "frame 1 renders visible timeline elements");

		var marker = clip.getChildByTimelineName("marker");
		assertNotNull(marker, "named children can be found");
		assertEquals("marker", marker.name, "timeline child name is applied");
		assertClose(12, marker.transform.matrix.tx, "matrix tx is applied");
		assertClose(34, marker.transform.matrix.ty, "matrix ty is applied");
		assertClose(0.5, marker.transform.colorTransform.alphaMultiplier, "color transform is applied");

		var hidden = clip.getChildByTimelineName("hidden");
		assertNotNull(hidden, "invisible named children are still addressable");
		assertEquals(false, hidden.visible, "visible=false is applied");

		clip.gotoAndStop(3);
		assertEquals(null, clip.getChildByTimelineName("marker"), "old frame children are removed");
		assertNotNull(clip.getChildByTimelineName("middleMarker"), "new frame children are rendered");
	}

	private static function testColorTransforms():Void {
		var clip = new PR2MovieClip(makeColorSymbol());

		assertColorTransform(requireChild(clip, "primaryColor"), 0.25, 0.5, 0.75, 1, 12, 34, 56, 0, "primary color layer transform");
		assertColorTransform(requireChild(clip, "secondaryColor"), 1, 0.8, 0.6, 0.4, 0, 8, 16, 24, "secondary color layer transform");
		assertColorTransform(requireChild(clip, "transparent"), 1, 1, 1, 0, 0, 0, 0, 0, "alpha-zero transform");

		var hiddenTint = requireChild(clip, "hiddenTint");
		assertEquals(false, hiddenTint.visible, "hidden color layer visibility is applied");
		assertColorTransform(hiddenTint, 0, 0, 0, 0.5, 4, 3, 2, 1, "hidden color layer keeps its transform");

		clip.gotoAndStop(2);
		assertEquals(null, clip.getChildByTimelineName("primaryColor"), "color children are replaced on frame changes");
		assertColorTransform(requireChild(clip, "identityColor"), 1, 1, 1, 1, 0, 0, 0, 0, "missing color transform defaults to identity");
	}

	private static function testLeafVectorShapes():Void {
		var clip = new PR2MovieClip(makeVectorSymbol());

		var vectorShape = requireChild(clip, "vectorShape");
		assertAtLeast(19, vectorShape.width, "DOMShape edge data renders vector width instead of placeholder");
		assertAtLeast(19, vectorShape.height, "DOMShape edge data renders vector height instead of placeholder");

		var group = Std.downcast(requireChild(clip, "group"), Sprite);
		assertNotNull(group, "DOMGroup renders as a sprite");
		assertEquals(1, group.numChildren, "DOMGroup renders member shapes");
		assertAtLeast(9, group.getChildAt(0).width, "DOMGroup member shape renders vector width");
	}

	private static function testGeneratedCharacterNamedChildren():Void {
		var character = PR2MovieClip.fromLinkage("CharacterGraphic", {maxNestedDepth: 2});

		for (childName in ["runAnim", "standAnim", "jumpAnim", "superJumpAnim", "bumpedAnim", "crouchAnim", "crouchWalkAnim", "swimAnim"]) {
			var child = Std.downcast(character.getChildByTimelineName(childName), PR2MovieClip);
			assertNotNull(child, 'CharacterGraphic exposes $childName as a movie clip');
			assertAtLeast(1, child.totalFrames, '$childName has timeline frames');
		}
		assertEquals(null, character.getChildByTimelineName("frozenSolidAnim"), "invisible CharacterGraphic layers are not rendered");
		assertHiddenTimelineChild(
			AssetLibrary.requireSymbolByLinkage("CharacterGraphic"),
			"frozenSolidAnim",
			"MovieClips/PR2_Graphics_1_Apr_2014_fla/Symbol 896",
			"CharacterGraphic keeps frozenSolidAnim on an invisible source layer"
		);

		for (linkage in [
			"PR2_Graphics_1_Apr_2014_fla.frozenSolidAnim_65",
			"PR2_Graphics_1_Apr_2014_fla.jumpAnim_61",
			"PR2_Graphics_1_Apr_2014_fla.superJumpAnim_60",
			"PR2_Graphics_1_Apr_2014_fla.bumpedAnim_59"
		]) {
			var animation = PR2MovieClip.fromLinkage(linkage, {maxNestedDepth: 1});
			assertNamedChildren(animation, ["weapon", "head", "body", "foot1", "foot2"], '$linkage exposes character part children');
		}

		var headSelector = PR2MovieClip.fromSymbolName("Parts/Heads/headsMC", {maxNestedDepth: 2});
		headSelector.gotoAndStop("gladiator");
		assertNestedNamedChildren(headSelector, ["colorMC", "colorMC2"], "headsMC gladiator frame exposes color layers");

		var bodySelector = PR2MovieClip.fromSymbolName("Parts/Bodies/bodyMC", {maxNestedDepth: 2});
		assertEquals(69, bodySelector.totalFrames, "bodyMC exposes all generated body frames");
		bodySelector.gotoAndStop("gladiator");
		assertNestedNamedChildren(bodySelector, ["colorMC", "colorMC2"], "bodyMC gladiator frame exposes color layers");

		var footSelector = PR2MovieClip.fromSymbolName("Parts/Feet/footMC", {maxNestedDepth: 2});
		assertEquals(101, footSelector.totalFrames, "footMC exposes all generated foot frames");
		footSelector.gotoAndStop("gladiator");
		assertNestedNamedChildren(footSelector, ["colorMC"], "footMC gladiator frame exposes color layer");

		var hatSelector = PR2MovieClip.fromLinkage("HatGraphic", {maxNestedDepth: 2});
		assertEquals(62, hatSelector.totalFrames, "hatsMC exposes all generated hat frames");
		hatSelector.gotoAndStop(24);
		assertNestedNamedChildren(hatSelector, ["colorMC"], "hatsMC colorable frame exposes color layer");

		headSelector.gotoAndStop(1);
		assertNamedChildren(headSelector, ["hat1"], "headsMC frame 1 exposes hat children");

		bodySelector.gotoAndStop(29);
		assertNamedChildren(bodySelector, ["hat1", "hat2", "hat3", "hat4"], "bodyMC frame 29 exposes hat children");

		assertLinkedClip("PR2_Graphics_1_Apr_2014_fla.gunFireAnim_40", 16, "shoot", 2);
		assertLinkedClip("PR2_Graphics_1_Apr_2014_fla.swordAnim_53", 14, "swing", 2);
		assertLinkedClip("PR2_Graphics_1_Apr_2014_fla.iceWaveFireAnim_55", 51, "fire", 2);

		var jetPack = assertLinkedClip("PR2_Graphics_1_Apr_2014_fla.jetPackStates_47", 11, "off", 1);
		assertHasLabel(jetPack, "on", 6);
		jetPack.gotoAndStop("off");
		assertNotNull(jetPack.getChildByTimelineName("anim"), "jetPackStates off frame exposes anim child");
		jetPack.gotoAndStop("on");
		assertNotNull(jetPack.getChildByTimelineName("anim"), "jetPackStates on frame exposes anim child");
	}

	private static function testTimelineCompositionPreservesPartSelection():Void {
		var runAnim = PR2MovieClip.fromLinkage("PR2_Graphics_1_Apr_2014_fla.jumpAnim_61", {maxNestedDepth: 2});
		var head = requireClipChild(runAnim, "head");
		var body = requireClipChild(runAnim, "body");

		head.gotoAndStop("gladiator");
		body.gotoAndStop("gladiator");
		var selectedHeadFrame = head.currentFrame;
		var selectedBodyFrame = body.currentFrame;

		runAnim.dispatchEvent(new Event(Event.ENTER_FRAME));
		var advancedHead = requireClipChild(runAnim, "head");
		var advancedBody = requireClipChild(runAnim, "body");

		assertEquals(2, runAnim.currentFrame, "generated animation advances parent timeline");
		assertEquals(selectedHeadFrame, advancedHead.currentFrame, "head part frame survives parent timeline advance");
		assertEquals(selectedBodyFrame, advancedBody.currentFrame, "body part frame survives parent timeline advance");
		assertNotNull(findDescendantByTimelineName(advancedHead, "colorMC"), "selected head color layer remains addressable after advance");
		assertNotNull(findDescendantByTimelineName(advancedBody, "colorMC2"), "selected body color layer remains addressable after advance");

		var clip = new PR2MovieClip(makeSingleFrameChildParentSymbol());
		var selector = requireClipChild(clip, "selector");
		selector.gotoAndStop(3);
		clip.gotoAndStop(2);
		assertEquals(2, requireClipChild(clip, "selector").currentFrame, "single-frame child instances follow parent firstFrame");
	}

	private static function testGeneratedCharacterPartIdSelection():Void {
		var character = PR2MovieClip.fromLinkage("CharacterGraphic", {maxNestedDepth: 12});
		CharacterAppearance.applyPartIds(character, {hat: 1, head: 1, body: 1, feet: 1});

		var runAnim = requireClipChild(character, "runAnim");
		assertEquals(1, requireClipChild(runAnim, "head").currentFrame, "head id 1 selects head frame 1");
		assertEquals(1, requireClipChild(runAnim, "body").currentFrame, "body id 1 selects body frame 1");
		assertEquals(1, requireClipChild(runAnim, "foot1").currentFrame, "feet id 1 selects foot1 frame 1");
		assertEquals(1, requireClipChild(runAnim, "foot2").currentFrame, "feet id 1 selects foot2 frame 1");
		assertEquals(1, requireClipChild(requireClipChild(runAnim, "head"), "hat1").currentFrame, "hat id 1 selects head hat1 frame 1");

		runAnim.advanceOneFrame();
		var advancedHead = requireClipChild(runAnim, "head");
		assertEquals(1, advancedHead.currentFrame, "head id 1 survives run timeline advance");
		assertEquals(1, requireClipChild(runAnim, "body").currentFrame, "body id 1 survives run timeline advance");
		assertEquals(1, requireClipChild(runAnim, "foot1").currentFrame, "feet id 1 survives run timeline advance");
		assertEquals(1, requireClipChild(advancedHead, "hat1").currentFrame, "hat id 1 survives run timeline advance");
	}

	private static function assertNamedChildren(clip:PR2MovieClip, childNames:Array<String>, message:String):Void {
		for (childName in childNames) {
			assertNotNull(clip.getChildByTimelineName(childName), '$message: missing $childName');
		}
	}

	private static function assertNestedNamedChildren(clip:PR2MovieClip, childNames:Array<String>, message:String):Void {
		for (childName in childNames) {
			assertNotNull(findDescendantByTimelineName(clip, childName), '$message: missing $childName');
		}
	}

	private static function assertLinkedClip(linkage:String, totalFrames:Int, labelName:String, labelFrame:Int):PR2MovieClip {
		var clip = PR2MovieClip.fromLinkage(linkage, {maxNestedDepth: 1});
		assertEquals(totalFrames, clip.totalFrames, '$linkage totalFrames');
		assertHasLabel(clip, labelName, labelFrame);
		clip.gotoAndStop(labelName);
		assertEquals(labelFrame, clip.currentFrame, '$linkage gotoAndStop resolves $labelName');
		return clip;
	}

	private static function assertHasLabel(clip:PR2MovieClip, labelName:String, labelFrame:Int):Void {
		for (label in clip.currentLabels) {
			if (label.name == labelName) {
				assertEquals(labelFrame, label.frame, '${clip.symbol.name} label $labelName frame');
				return;
			}
		}
		throw '${clip.symbol.name} missing label $labelName';
	}

	private static function assertHiddenTimelineChild(symbol:SymbolAssetDef, childName:String, libraryItemName:String, message:String):Void {
		for (timeline in symbol.timelines) {
			for (layer in timeline.layers) {
				for (frame in layer.frames) {
					var elements = frame.elements == null ? [] : frame.elements;
					for (element in elements) {
						if (element.name == childName) {
							assertEquals(false, layer.visible, '$message layer visibility');
							assertEquals(libraryItemName, element.libraryItemName, '$message library item');
							assertNotNull(PR2MovieClip.fromSymbolName(libraryItemName, {maxNestedDepth: 1}), '$message symbol can instantiate directly');
							return;
						}
					}
				}
			}
		}
		throw '$message missing source child $childName';
	}

	private static function findDescendantByTimelineName(clip:PR2MovieClip, name:String):Null<DisplayObject> {
		var direct = clip.getChildByTimelineName(name);
		if (direct != null) {
			return direct;
		}

		for (i in 0...clip.numChildren) {
			var childClip = Std.downcast(clip.getChildAt(i), PR2MovieClip);
			if (childClip == null) {
				continue;
			}

			var descendant = findDescendantByTimelineName(childClip, name);
			if (descendant != null) {
				return descendant;
			}
		}

		return null;
	}

	private static function requireChild(clip:PR2MovieClip, name:String):DisplayObject {
		var child = clip.getChildByTimelineName(name);
		assertNotNull(child, 'missing child $name');
		return child;
	}

	private static function requireClipChild(clip:PR2MovieClip, name:String):PR2MovieClip {
		var child = Std.downcast(requireChild(clip, name), PR2MovieClip);
		assertNotNull(child, 'child $name is not a PR2MovieClip');
		return child;
	}

	private static function makeSymbol():SymbolAssetDef {
		return {
			href: "TestSymbol.xml",
			type: "movie clip",
			name: "TestSymbol",
			linkageClassName: "TestSymbol",
			linkageIdentifier: "TestSymbol",
			timelines: [{
				name: "TestSymbol",
				layerCount: 1,
				frameCount: 4,
				labels: [
					{name: "intro", frame: 0, layer: 0},
					{name: "middle", frame: 2, layer: 0}
				],
				layers: [{
					index: 0,
					name: "Layer 1",
					visible: true,
					locked: false,
					layerType: "normal",
					frameCount: 2,
					frames: [
						{
							index: 0,
							duration: 2,
							elementCount: 2,
							elementTypes: ["DOMShape", "DOMShape"],
							elements: [
								{
									type: "DOMShape",
									name: "marker",
									bounds: {left: 0, top: 0, right: 10, bottom: 10},
									matrix: {tx: 12, ty: 34},
									color: {alphaMultiplier: 0.5}
								},
								{
									type: "DOMShape",
									name: "hidden",
									visible: false,
									bounds: {left: 0, top: 0, right: 5, bottom: 5}
								}
							]
						},
						{
							index: 2,
							duration: 2,
							elementCount: 1,
							elementTypes: ["DOMShape"],
							elements: [{
								type: "DOMShape",
								name: "middleMarker",
								bounds: {left: 0, top: 0, right: 20, bottom: 20}
							}]
						}
					]
				}]
			}]
		};
	}

	private static function makeColorSymbol():SymbolAssetDef {
		return {
			href: "ColorSymbol.xml",
			type: "movie clip",
			name: "ColorSymbol",
			linkageClassName: "ColorSymbol",
			linkageIdentifier: "ColorSymbol",
			timelines: [{
				name: "ColorSymbol",
				layerCount: 1,
				frameCount: 2,
				labels: [],
				layers: [{
					index: 0,
					name: "Layer 1",
					visible: true,
					locked: false,
					layerType: "normal",
					frameCount: 2,
					frames: [
						{
							index: 0,
							duration: 1,
							elementCount: 4,
							elementTypes: ["DOMShape", "DOMShape", "DOMShape", "DOMShape"],
							elements: [
								{
									type: "DOMShape",
									name: "primaryColor",
									bounds: {left: 0, top: 0, right: 10, bottom: 10},
									color: {
										redMultiplier: 0.25,
										greenMultiplier: 0.5,
										blueMultiplier: 0.75,
										redOffset: 12,
										greenOffset: 34,
										blueOffset: 56
									}
								},
								{
									type: "DOMShape",
									name: "secondaryColor",
									bounds: {left: 0, top: 0, right: 10, bottom: 10},
									color: {
										alphaMultiplier: 0.4,
										greenMultiplier: 0.8,
										blueMultiplier: 0.6,
										greenOffset: 8,
										blueOffset: 16,
										alphaOffset: 24
									}
								},
								{
									type: "DOMShape",
									name: "transparent",
									bounds: {left: 0, top: 0, right: 10, bottom: 10},
									color: {alphaMultiplier: 0}
								},
								{
									type: "DOMShape",
									name: "hiddenTint",
									visible: false,
									bounds: {left: 0, top: 0, right: 10, bottom: 10},
									color: {
										alphaMultiplier: 0.5,
										redMultiplier: 0,
										greenMultiplier: 0,
										blueMultiplier: 0,
										alphaOffset: 1,
										redOffset: 4,
										greenOffset: 3,
										blueOffset: 2
									}
								}
							]
						},
						{
							index: 1,
							duration: 1,
							elementCount: 1,
							elementTypes: ["DOMShape"],
							elements: [{
								type: "DOMShape",
								name: "identityColor",
								bounds: {left: 0, top: 0, right: 10, bottom: 10}
							}]
						}
					]
				}]
			}]
		};
	}

	private static function makeVectorSymbol():SymbolAssetDef {
		return {
			href: "VectorSymbol.xml",
			type: "movie clip",
			name: "VectorSymbol",
			linkageClassName: "VectorSymbol",
			linkageIdentifier: "VectorSymbol",
			timelines: [{
				name: "VectorSymbol",
				layerCount: 1,
				frameCount: 1,
				labels: [],
				layers: [{
					index: 0,
					name: "Layer 1",
					visible: true,
					locked: false,
					layerType: "normal",
					frameCount: 1,
					frames: [{
						index: 0,
						duration: 1,
						elementCount: 2,
						elementTypes: ["DOMGroup", "DOMShape"],
						elements: [
							{
								type: "DOMShape",
								name: "vectorShape",
								fills: [{index: 1, value: {type: "SolidColor", color: "#FF0000"}}],
								edges: [{fillStyle1: 1, edges: "!0 0|20 0!20 0|20 20!20 20|0 20!0 20|0 0"}]
							},
							{
								type: "DOMGroup",
								name: "group",
								children: [{
									type: "DOMShape",
									fills: [{index: 1, value: {type: "SolidColor", color: "#00FF00"}}],
									edges: [{fillStyle0: 1, edges: "!0 0[10 0 10 10!10 10|0 10!0 10|0 0"}]
								}]
							}
						]
					}]
				}]
			}]
		};
	}

	private static function makeSingleFrameChildParentSymbol():SymbolAssetDef {
		return {
			href: "SingleFrameChildParent.xml",
			type: "movie clip",
			name: "SingleFrameChildParent",
			linkageClassName: "SingleFrameChildParent",
			linkageIdentifier: "SingleFrameChildParent",
			timelines: [{
				name: "SingleFrameChildParent",
				layerCount: 1,
				frameCount: 2,
				labels: [],
				layers: [{
					index: 0,
					name: "Layer 1",
					visible: true,
					locked: false,
					layerType: "normal",
					frameCount: 2,
					frames: [
						{
							index: 0,
							duration: 1,
							elementCount: 1,
							elementTypes: ["DOMSymbolInstance"],
							elements: [{
								type: "DOMSymbolInstance",
								name: "selector",
								libraryItemName: "Parts/Heads/headsMC",
								loop: "single frame",
								firstFrame: 0
							}]
						},
						{
							index: 1,
							duration: 1,
							elementCount: 1,
							elementTypes: ["DOMSymbolInstance"],
							elements: [{
								type: "DOMSymbolInstance",
								name: "selector",
								libraryItemName: "Parts/Heads/headsMC",
								loop: "single frame",
								firstFrame: 1
							}]
						}
					]
				}]
			}]
		};
	}

	private static function assertNotNull(value:Dynamic, message:String):Void {
		assertions++;
		if (value == null) {
			throw message;
		}
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertAtLeast(minimum:Float, actual:Float, message:String):Void {
		assertions++;
		if (actual < minimum) {
			throw '$message: expected at least $minimum, got $actual';
		}
	}

	private static function assertClose(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.0001) {
			throw '$message: expected $expected, got $actual';
		}
	}

	private static function assertColorTransform(
		child:DisplayObject,
		redMultiplier:Float,
		greenMultiplier:Float,
		blueMultiplier:Float,
		alphaMultiplier:Float,
		redOffset:Float,
		greenOffset:Float,
		blueOffset:Float,
		alphaOffset:Float,
		message:String
	):Void {
		var color = child.transform.colorTransform;
		assertClose(redMultiplier, color.redMultiplier, '$message redMultiplier');
		assertClose(greenMultiplier, color.greenMultiplier, '$message greenMultiplier');
		assertClose(blueMultiplier, color.blueMultiplier, '$message blueMultiplier');
		assertClose(alphaMultiplier, color.alphaMultiplier, '$message alphaMultiplier');
		assertClose(redOffset, color.redOffset, '$message redOffset');
		assertClose(greenOffset, color.greenOffset, '$message greenOffset');
		assertClose(blueOffset, color.blueOffset, '$message blueOffset');
		assertClose(alphaOffset, color.alphaOffset, '$message alphaOffset');
	}

	private static function assertThrows(action:Void->Void, message:String):Void {
		assertions++;
		try {
			action();
		} catch (_:Dynamic) {
			return;
		}
		throw message;
	}
}
