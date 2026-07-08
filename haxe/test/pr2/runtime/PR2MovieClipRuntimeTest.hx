package pr2.runtime;

import openfl.display.BlendMode;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.filters.BlurFilter;
import openfl.filters.DropShadowFilter;
import openfl.filters.GlowFilter;
import openfl.geom.Point;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.text.TextFormatAlign;
import pr2.character.CharacterAppearance;
import pr2.generated.assets.AssetCatalog;
import pr2.generated.assets.AssetTypes.FrameDef;
import pr2.generated.assets.AssetTypes.SymbolAssetDef;
import pr2.page.LoginFlashPopup;

class PR2MovieClipRuntimeTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testTimelineControls();
		testAuthoredSymbolFailuresAreExplicit();
		testFrameScriptHooks();
		testNamedChildAccessAndElementProperties();
		testSourceLayerOrderRendersTopLayersAboveBottomLayers();
		testMaskLayersClipMaskedLayers();
		testGeneratedRatingStarsMask();
		testColorTransforms();
		testBlendModes();
		testFilters();
		testScale9Grids();
		testAlphaOnlySolidFills();
		testGeneratedSoundFrameMetadata();
		testTimelineEventSounds();
		testLeafVectorShapes();
		testGeneratedSiteLogoFrameScripts();
		testGeneratedCharacterStateFrameScripts();
		testGeneratedCharacterNestedStopFrameScripts();
		testGeneratedQuitGlowFrameScripts();
		testGeneratedJumpStateStopFrameScripts();
		testGeneratedIntroLogoFrameScripts();
		testGeneratedPlayersTabListConstructorStop();
		testGeneratedShortEffectStopFrameScripts();
		testDisposeStopsClipsNestedInGroups();
		testPrimitiveDrawingObjects();
		testGeneratedStaticTextAndComponents();
		testLoginPopupUsesAuthoredComponentsOnly();
		testStaticTextHonorsAuthoredAttributes();
		testGeneratedIntroTimelines();
		testGeneratedCharacterNamedChildren();
		testTimelineCompositionPreservesPartSelection();
		testGeneratedCharacterPartIdSelection();
		testGeneratedRunAnimationPartPlacement();
		trace('PR2MovieClipRuntimeTest passed $assertions assertions');
	}

	private static function testAuthoredSymbolFailuresAreExplicit():Void {
		assertThrows(
			function() new PR2MovieClip(makeUnresolvedChildSymbol()),
			"unresolved authored symbols are rejected instead of drawn as placeholders"
		);
		assertThrows(
			function() PR2MovieClip.fromLinkage("LobbyGraphic", {maxNestedDepth: 0}),
			"authored symbols beyond the configured nesting limit are rejected instead of drawn as placeholders"
		);
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

	private static function testGeneratedSiteLogoFrameScripts():Void {
		var armor = PR2MovieClip.fromLinkage("PR2_Graphics_1_Apr_2014_fla.ag_intro_mc_247", {maxNestedDepth: 6});
		assertEquals(2, armor.currentFrame, "ArmorGames intro constructor jumps from frame 1 to frame 2");
		armor.gotoAndPlay(218);
		armor.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(219, armor.currentFrame, "ArmorGames intro reaches its authored stop frame");
		armor.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(219, armor.currentFrame, "ArmorGames intro stop frame prevents looping");

		assertLoopsFromFrame21("PR2_Graphics_1_Apr_2014_fla.bubbleSpin_12", "BubbleBox bubble spin");
		assertLoopsFromFrame21("PR2_Graphics_1_Apr_2014_fla.bubbleShineSpin_17", "BubbleBox shine spin");

		var logo = PR2MovieClip.fromLinkage("PR2_Graphics_1_Apr_2014_fla.bubblebox_logo_ro_254", {maxNestedDepth: 6});
		logo.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(1, logo.currentFrame, "BubbleBox rollover logo stays stopped on frame 1");

		var latest = PR2MovieClip.fromLinkage("PR2_Graphics_1_Apr_2014_fla.bubblxbox_play_latest_text_252", {maxNestedDepth: 6});
		latest.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(1, latest.currentFrame, "BubbleBox latest text stays stopped on frame 1");
		latest.gotoAndPlay(9);
		latest.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(10, latest.currentFrame, "BubbleBox latest text reaches frame 10");
		latest.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(10, latest.currentFrame, "BubbleBox latest text stops on frame 10");
	}

	private static function testGeneratedCharacterStateFrameScripts():Void {
		var bumped = PR2MovieClip.fromLinkage("PR2_Graphics_1_Apr_2014_fla.bumpedAnim_59", {maxNestedDepth: 6});
		assertEquals(null, bumped.var_652, "bumped animation starts without its completion flag");
		bumped.gotoAndStop(55);
		assertEquals(null, bumped.var_652, "bumped animation does not complete before frame 56");
		bumped.gotoAndStop(56);
		assertEquals(true, bumped.var_652, "bumped animation sets its frame-56 completion flag");

		var frozen = PR2MovieClip.fromLinkage("PR2_Graphics_1_Apr_2014_fla.frozenSolidAnim_65", {maxNestedDepth: 6});
		var completed = 0;
		frozen.addEventListener(Event.COMPLETE, function(_:Event):Void completed++);
		frozen.gotoAndPlay(47);
		frozen.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(48, frozen.currentFrame, "frozen-solid animation reaches its authored completion frame");
		assertEquals(1, completed, "frozen-solid animation dispatches COMPLETE on frame 48");
		frozen.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(48, frozen.currentFrame, "frozen-solid animation stops on frame 48");
		assertEquals(1, completed, "frozen-solid completion dispatches once");
	}

	private static function testGeneratedCharacterNestedStopFrameScripts():Void {
		for (linkage in [
			"PR2_Graphics_1_Apr_2014_fla.gunFireAnim_40",
			"PR2_Graphics_1_Apr_2014_fla.iceWaveFireAnim_55",
			"PR2_Graphics_1_Apr_2014_fla.jetPackStates_47",
			"PR2_Graphics_1_Apr_2014_fla.swordAnim_53",
			"PR2_Graphics_1_Apr_2014_fla.hatColor_24",
			"PR2_Graphics_1_Apr_2014_fla.hatColor2_25"
		]) {
			var clip = PR2MovieClip.fromLinkage(linkage, {maxNestedDepth: 6});
			clip.dispatchEvent(new Event(Event.ENTER_FRAME));
			assertEquals(1, clip.currentFrame, '$linkage constructor stop script holds frame 1');
		}
	}

	private static function testGeneratedQuitGlowFrameScripts():Void {
		var glow = PR2MovieClip.fromLinkage("PR2_Graphics_1_Apr_2014_fla.buttonGlowAnim_182", {maxNestedDepth: 6});
		assertEquals(2, labelFrame(glow, "off"), "quit glow off label frame");
		assertEquals(11, labelFrame(glow, "on"), "quit glow on label frame");
		glow.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(2, glow.currentFrame, "quit glow reaches off frame on first tick");
		glow.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(2, glow.currentFrame, "quit glow off frame stops");
		glow.gotoAndPlay("on");
		assertEquals(11, glow.currentFrame, "quit glow starts at authored on label");
		glow.gotoAndPlay(36);
		glow.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(11, glow.currentFrame, "quit glow frame 37 loops back to on label");
		glow.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(12, glow.currentFrame, "quit glow continues playing after loop");
	}

	private static function testGeneratedJumpStateStopFrameScripts():Void {
		assertStopsOnNextFrame("PR2_Graphics_1_Apr_2014_fla.jumpAnim_61", 49, 50, "jump animation");
		assertStopsOnNextFrame("PR2_Graphics_1_Apr_2014_fla.superJumpAnim_60", 50, 51, "super-jump animation");
	}

	private static function testGeneratedIntroLogoFrameScripts():Void {
		var logo = PR2MovieClip.fromLinkage("PR2_Graphics_1_Apr_2014_fla.logoAnim_258", {maxNestedDepth: 6});
		assertEquals(false, logo.mouseEnabled, "Jiggmin intro logo disables mouse input on frame 1");
		assertEquals(false, logo.mouseChildren, "Jiggmin intro logo disables child mouse input on frame 1");
		logo.gotoAndPlay(logo.totalFrames - 1);
		logo.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(logo.totalFrames, logo.currentFrame, "Jiggmin intro logo reaches final generated frame");
		logo.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(logo.totalFrames, logo.currentFrame, "Jiggmin intro logo stops on final generated frame");
	}

	private static function testGeneratedPlayersTabListConstructorStop():Void {
		var list = PR2MovieClip.fromLinkage("PlayersTabListGraphic", {maxNestedDepth: 6});
		assertEquals(1, labelFrame(list, "players"), "players list default label frame");
		assertEquals(6, labelFrame(list, "guilds"), "players list guilds label frame");
		assertEquals(1, list.currentFrame, "players list starts on the normal players frame");
		list.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(1, list.currentFrame, "players list constructor stop prevents auto-playing to guild headers");
		list.gotoAndStop("guilds");
		assertEquals(6, list.currentFrame, "players list can still explicitly enter the guilds frame");
	}

	private static function testGeneratedShortEffectStopFrameScripts():Void {
		assertStopsOnNextFrame("PointyStar", 15, 16, "pointy star effect");
		assertStopsOnNextFrame("TeleportAnimation", 15, 16, "teleport effect");
		assertStopsOnNextFrame("SlashAnimation", 5, 6, "slash effect");
	}

	private static function assertLoopsFromFrame21(linkage:String, label:String):Void {
		var clip = PR2MovieClip.fromLinkage(linkage, {maxNestedDepth: 6});
		clip.gotoAndPlay(20);
		clip.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(1, clip.currentFrame, '$label loops frame 21 back to frame 1');
		clip.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(2, clip.currentFrame, '$label continues playing after its authored loop');
	}

	private static function assertStopsOnNextFrame(linkage:String, startFrame:Int, stopFrame:Int, label:String):Void {
		var clip = PR2MovieClip.fromLinkage(linkage, {maxNestedDepth: 6});
		clip.gotoAndPlay(startFrame);
		clip.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(stopFrame, clip.currentFrame, '$label reaches authored stop frame');
		clip.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(stopFrame, clip.currentFrame, '$label stays stopped on authored stop frame');
	}

	private static function labelFrame(clip:PR2MovieClip, name:String):Int {
		for (label in clip.currentLabels) {
			if (label.name == name) return label.frame;
		}
		throw '${clip.symbol.name} missing label $name';
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

	private static function testSourceLayerOrderRendersTopLayersAboveBottomLayers():Void {
		var clip = new PR2MovieClip(makeLayeredSymbol());

		assertEquals(3, clip.numChildren, "layered symbol renders one child per layer");
		assertEquals("bottom", clip.getChildAt(0).name, "last source layer renders at the bottom");
		assertEquals("middle", clip.getChildAt(1).name, "middle source layer renders in the middle");
		assertEquals("top", clip.getChildAt(2).name, "first source layer renders at the top");
	}


	private static function testMaskLayersClipMaskedLayers():Void {
		var clip = new PR2MovieClip(makeMaskedSymbol());

		// background + bar share a masked content holder; the star mask sits in a
		// second holder; the overlay layer (no parent) stays a direct child.
		assertEquals(3, clip.numChildren, "masked symbol groups masked layers into holders");

		var content = Std.downcast(clip.getChildAt(0), Sprite);
		assertNotNull(content, "masked layers are wrapped in a content holder sprite");
		assertNotNull(content.mask, "masked content holder has a mask assigned");
		assertEquals(2, content.numChildren, "both masked layers share one content holder");

		var maskHolder = Std.downcast(clip.getChildAt(1), Sprite);
		assertNotNull(maskHolder, "the mask layer is wrapped in its own holder sprite");
		assertEquals(maskHolder, content.mask, "content holder is clipped by the mask holder");
		assertEquals(1, maskHolder.numChildren, "mask holder contains the mask layer's shapes");

		// Masked children remain addressable through the synthetic holders.
		var bar = clip.getChildByTimelineName("bar");
		assertNotNull(bar, "masked child stays addressable by timeline name");
		assertEquals(content, bar.parent, "masked child lives inside the content holder");

		var background = clip.getChildByTimelineName("background");
		assertNotNull(background, "second masked child stays addressable");
		assertEquals(content, background.parent, "second masked child lives inside the content holder");

		var overlay = clip.getChildByTimelineName("overlay");
		assertNotNull(overlay, "unmasked top layer stays a direct child");
		assertEquals(clip, overlay.parent, "unmasked layer is not wrapped in a holder");

		var starMask = clip.getChildByTimelineName("starMask");
		assertNotNull(starMask, "mask shape stays addressable by timeline name");
		assertEquals(maskHolder, starMask.parent, "mask shape lives inside the mask holder");
	}

	private static function testGeneratedRatingStarsMask():Void {
		// The real catalog symbol the in-game vote widget uses: a green bar plus a
		// gradient background, both clipped to five star shapes (parentLayerIndex).
		var stars = PR2MovieClip.fromLinkage("RatingSelectGraphic", {maxNestedDepth: 4});

		var maskedContent:Sprite = null;
		for (i in 0...stars.numChildren) {
			var sprite = Std.downcast(stars.getChildAt(i), Sprite);
			if (sprite != null && sprite.mask != null) {
				maskedContent = sprite;
				break;
			}
		}
		assertNotNull(maskedContent, "RatingStars masks its bar/background to the star shapes");

		var bar = stars.getChildByTimelineName("bar");
		assertNotNull(bar, "RatingStars exposes the masked bar by name");
		assertEquals(maskedContent, bar.parent, "the bar is clipped by the star mask");
	}

	private static function makeMaskedSymbol():SymbolAssetDef {
		return {
			href: "MaskedSymbol.xml",
			type: "movie clip",
			name: "MaskedSymbol",
			linkageClassName: "MaskedSymbol",
			linkageIdentifier: "MaskedSymbol",
			timelines: [{
				name: "MaskedSymbol",
				layerCount: 4,
				frameCount: 1,
				labels: [],
				// Mirrors UI/Global/RatingStars: a top overlay, a mask layer, then
				// two layers (bar over background) clipped by that mask.
				layers: [
					makeSingleShapeLayer(0, "Overlay", "overlay"),
					makeMaskShapeLayer(1, "Mask", "starMask"),
					makeMaskedShapeLayer(2, 1, "Bar", "bar"),
					makeMaskedShapeLayer(3, 1, "Background", "background")
				]
			}]
		};
	}

	private static function makeMaskShapeLayer(index:Int, layerName:String, childName:String):Dynamic {
		var layer = makeSingleShapeLayer(index, layerName, childName);
		layer.layerType = "mask";
		return layer;
	}

	private static function makeMaskedShapeLayer(index:Int, parentLayerIndex:Int, layerName:String, childName:String):Dynamic {
		var layer = makeSingleShapeLayer(index, layerName, childName);
		layer.parentLayerIndex = parentLayerIndex;
		return layer;
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

	private static function testBlendModes():Void {
		var clip = new PR2MovieClip(makeBlendModeSymbol());

		assertEquals(BlendMode.MULTIPLY, requireChild(clip, "multiply").blendMode, "multiply blend mode is applied");
		assertEquals(BlendMode.SCREEN, requireChild(clip, "screen").blendMode, "screen blend mode is applied");
		assertEquals(BlendMode.LAYER, requireChild(clip, "layer").blendMode, "layer blend mode is applied");
		assertEquals(BlendMode.NORMAL, requireChild(clip, "normal").blendMode, "missing blend mode defaults to normal");
	}

	private static function testFilters():Void {
		var clip = new PR2MovieClip(makeFilterSymbol());
		var filtered = requireChild(clip, "filtered");

		assertEquals(3, filtered.filters.length, "authored filters retain their source order");

		var blur = Std.downcast(filtered.filters[0], BlurFilter);
		assertNotNull(blur, "BlurFilter is created");
		assertClose(7, blur.blurX, "BlurFilter blurX");
		assertClose(9, blur.blurY, "BlurFilter blurY");
		assertEquals(2, blur.quality, "BlurFilter quality");

		var glow = Std.downcast(filtered.filters[1], GlowFilter);
		assertNotNull(glow, "GlowFilter is created");
		assertEquals(0x123456, glow.color, "GlowFilter color");
		assertClose(0.4, glow.alpha, "GlowFilter alpha");
		assertClose(8, glow.blurX, "GlowFilter blurX");
		assertClose(10, glow.blurY, "GlowFilter blurY");
		assertClose(3, glow.strength, "GlowFilter strength");
		assertEquals(2, glow.quality, "GlowFilter quality");
		assertEquals(true, glow.inner, "GlowFilter inner");
		assertEquals(true, glow.knockout, "GlowFilter knockout");

		var shadow = Std.downcast(filtered.filters[2], DropShadowFilter);
		assertNotNull(shadow, "DropShadowFilter is created");
		assertClose(6, shadow.distance, "DropShadowFilter distance");
		assertClose(30, shadow.angle, "DropShadowFilter angle");
		assertEquals(0x654321, shadow.color, "DropShadowFilter color");
		assertClose(0.6, shadow.alpha, "DropShadowFilter alpha");
		assertClose(11, shadow.blurX, "DropShadowFilter blurX");
		assertClose(13, shadow.blurY, "DropShadowFilter blurY");
		assertClose(1.5, shadow.strength, "DropShadowFilter strength");
		assertEquals(3, shadow.quality, "DropShadowFilter quality");
		assertEquals(true, shadow.inner, "DropShadowFilter inner");
		assertEquals(true, shadow.knockout, "DropShadowFilter knockout");
		assertEquals(true, shadow.hideObject, "DropShadowFilter hideObject");

		var defaults = requireChild(clip, "defaults");
		var defaultBlur = Std.downcast(defaults.filters[0], BlurFilter);
		var defaultGlow = Std.downcast(defaults.filters[1], GlowFilter);
		var defaultShadow = Std.downcast(defaults.filters[2], DropShadowFilter);
		assertClose(4, defaultBlur.blurX, "BlurFilter uses Flash default blurX");
		assertClose(6, defaultGlow.blurX, "GlowFilter uses Flash default blurX");
		assertClose(4, defaultShadow.distance, "DropShadowFilter uses Flash default distance");

		clip.gotoAndStop(2);
		assertEquals(0, requireChild(clip, "filtered").filters.length, "filters are removed on an unfiltered keyframe");
	}

	private static function testScale9Grids():Void {
		assertEquals(true, NineSliceSymbol.hasGrid(makeScale9GridSymbol()), "authored scale grid is recognized");
		assertEquals(false, NineSliceSymbol.hasGrid(makeVectorSymbol()), "a symbol without a scale grid is not nine-sliced");

		// 100x100 content (origin at 0,0) with 10px margins on every side, scaled to
		// 3x wide and 2x tall: corners stay 10px, edges/center absorb the rest.
		var cells = NineSliceSymbol.computeCells(0, 0, 100, 100, 10, 10, 10, 10, 3, 2);
		var tl = cells[0];
		var center = cells[4];
		var br = cells[8];

		assertClose(10, tl.width, "top-left corner keeps its natural width");
		assertClose(10, tl.height, "top-left corner keeps its natural height");
		assertClose(0, tl.x, "top-left corner sits at the box origin");

		assertClose(280, center.width, "center stretches to fill the horizontal slack (300 - 2x10)");
		assertClose(180, center.height, "center stretches to fill the vertical slack (200 - 2x10)");
		assertClose(10, center.x, "center starts after the left corner");

		assertClose(290, br.x, "bottom-right corner is flush to the scaled right edge (300 - 10)");
		assertClose(190, br.y, "bottom-right corner is flush to the scaled bottom edge (200 - 10)");

		// The full box matches what a uniform scale would have covered, so the
		// panel is not "too small": right edge at boundsWidth*scaleX.
		assertClose(300, br.x + br.width, "sliced box spans the full scaled width");
		assertClose(200, br.y + br.height, "sliced box spans the full scaled height");

		// A panel squashed below its fixed margins clamps the corners proportionally
		// rather than overflowing (center collapses to zero).
		var squashed = NineSliceSymbol.computeCells(0, 0, 100, 100, 10, 10, 10, 10, 0.1, 0.1);
		assertClose(0, squashed[4].width, "over-squashed center collapses to zero width");
		assertClose(10, squashed[8].x + squashed[8].width, "squashed slices still fit the 10px box");
	}

	private static function testAlphaOnlySolidFills():Void {
		var solid = @:privateAccess VectorShapeRenderer.colorForStyle({type: "SolidColor", alpha: 0.25});
		assertEquals(0, solid.color, "alpha-only solid fill defaults to black");
		assertClose(0.25, solid.alpha, "alpha-only solid fill preserves authored opacity");
	}

	private static function testGeneratedSoundFrameMetadata():Void {
		var symbol = null;
		for (candidate in AssetCatalog.symbols()) {
			if (candidate.href == "MovieClips/PR2_Graphics_1_Apr_2014_fla/Symbol 69.xml") {
				symbol = candidate;
				break;
			}
		}
		assertNotNull(symbol, "generated catalog retains the authored sound-frame symbol");

		var seekFrame = symbol.timelines[0].layers[14].frames[1];
		assertEquals("Sounds/sound57.mp3", seekFrame.soundName, "sound frame retains its library name");
		assertEquals("custom", seekFrame.soundEffect, "sound frame retains its authored effect");
		assertEquals(4500, seekFrame.inPoint44, "sound frame retains its 44 kHz in point");
		assertEquals(13000, seekFrame.outPoint44, "sound frame retains its 44 kHz out point");

		var envelope = symbol.timelines[0].layers[10].frames[1].soundEnvelope;
		assertEquals(2, envelope.length, "sound frame retains every envelope point");
		assertEquals(14900, envelope[1].mark44, "sound envelope retains its sample marker");
		assertEquals(32768, envelope[1].level0, "sound envelope retains its left level");
		assertEquals(32768, envelope[1].level1, "sound envelope retains its right level");
	}

	private static function testTimelineEventSounds():Void {
		var played:Array<String> = [];
		var clip = new PR2MovieClip(makeSoundSymbol(), {
			soundFrameHandler: function(frame:FrameDef) played.push(frame.soundName)
		});

		assertEquals("Sounds/first.mp3", played.join(","), "frame-one sound plays when the clip is created");
		clip.advanceOneFrame();
		assertEquals("Sounds/first.mp3", played.join(","), "held sound keyframe does not retrigger");
		clip.advanceOneFrame();
		assertEquals(
			"Sounds/first.mp3,Sounds/second.mp3",
			played.join(","),
			"sound plays once when its later keyframe is entered"
		);
		clip.gotoAndStop(3);
		assertEquals(
			"Sounds/first.mp3,Sounds/second.mp3,Sounds/second.mp3",
			played.join(","),
			"explicitly re-entering a sound keyframe retriggers its event sound"
		);
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

	private static function testDisposeStopsClipsNestedInGroups():Void {
		var clip = new PR2MovieClip(makeNestedAnimatedGroupSymbol());
		var group = Std.downcast(clip.getChildByTimelineName("group"), Sprite);
		assertNotNull(group, "nested animated group renders");
		var nested = Std.downcast(group.getChildAt(0), PR2MovieClip);
		assertNotNull(nested, "group contains the animated child clip");

		var startingFrame = nested.currentFrame;
		nested.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(startingFrame + 1, nested.currentFrame, "nested child plays before disposal");

		clip.dispose();
		var disposedFrame = nested.currentFrame;
		nested.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(disposedFrame, nested.currentFrame, "disposing the owner stops clips nested inside groups");
	}

	private static function testGeneratedCharacterNamedChildren():Void {
		var character = PR2MovieClip.fromLinkage("CharacterGraphic", {maxNestedDepth: 12});

		// frozenSolidAnim sits on an eye-hidden source layer, but Flash's published
		// SWF renders every layer regardless of its authoring visibility, so it is
		// exposed as a movie clip alongside the other states (setState toggles which
		// one is visible). Without it the character vanishes while frozen.
		for (childName in ["runAnim", "standAnim", "jumpAnim", "superJumpAnim", "bumpedAnim", "crouchAnim", "crouchWalkAnim", "swimAnim", "frozenSolidAnim"]) {
			var child = Std.downcast(character.getChildByTimelineName(childName), PR2MovieClip);
			assertNotNull(child, 'CharacterGraphic exposes $childName as a movie clip');
			assertAtLeast(1, child.totalFrames, '$childName has timeline frames');
		}
		assertHiddenTimelineChild(
			AssetLibrary.requireSymbolByLinkage("CharacterGraphic"),
			"frozenSolidAnim",
			"MovieClips/PR2_Graphics_1_Apr_2014_fla/Symbol 896",
			"CharacterGraphic keeps frozenSolidAnim on an eye-hidden source layer yet still renders it"
		);

		for (linkage in [
			"PR2_Graphics_1_Apr_2014_fla.frozenSolidAnim_65",
			"PR2_Graphics_1_Apr_2014_fla.jumpAnim_61",
			"PR2_Graphics_1_Apr_2014_fla.superJumpAnim_60",
			"PR2_Graphics_1_Apr_2014_fla.bumpedAnim_59"
		]) {
			var animation = PR2MovieClip.fromLinkage(linkage, {maxNestedDepth: 12});
			assertNamedChildren(animation, ["weapon", "head", "body", "foot1", "foot2"], '$linkage exposes character part children');
		}

		var headSelector = PR2MovieClip.fromSymbolName("Parts/Heads/headsMC", {maxNestedDepth: 12});
		headSelector.gotoAndStop("gladiator");
		assertNestedNamedChildren(headSelector, ["colorMC", "colorMC2"], "headsMC gladiator frame exposes color layers");

		var bodySelector = PR2MovieClip.fromSymbolName("Parts/Bodies/bodyMC", {maxNestedDepth: 12});
		assertEquals(69, bodySelector.totalFrames, "bodyMC exposes all generated body frames");
		bodySelector.gotoAndStop("gladiator");
		assertNestedNamedChildren(bodySelector, ["colorMC", "colorMC2"], "bodyMC gladiator frame exposes color layers");

		var footSelector = PR2MovieClip.fromSymbolName("Parts/Feet/footMC", {maxNestedDepth: 12});
		assertEquals(101, footSelector.totalFrames, "footMC exposes all generated foot frames");
		footSelector.gotoAndStop("gladiator");
		assertNestedNamedChildren(footSelector, ["colorMC"], "footMC gladiator frame exposes color layer");

		var hatSelector = PR2MovieClip.fromLinkage("HatGraphic", {maxNestedDepth: 12});
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

	private static function testGeneratedStaticTextAndComponents():Void {
		var popup = PR2MovieClip.fromLinkage("LoginPopupGraphic", {maxNestedDepth: 12});

		assertNotNull(findTextDescendant(popup, "-- Login --"), "LoginPopupGraphic renders DOMStaticText title");
		assertNotNull(findTextDescendant(popup, "name:"), "LoginPopupGraphic renders DOMStaticText field labels");
		var loginButton = popup.getChildByTimelineName("login_bt");
		assertNotNull(loginButton, "LoginPopupGraphic renders named Button component");
		assertClose(1, loginButton.transform.matrix.a, "Button instance width does not horizontally scale its label");
		assertNotNull(popup.getChildByTimelineName("rememberMe_chk"), "LoginPopupGraphic renders named CheckBox component");

		var nameBox = Std.downcast(popup.getChildByTimelineName("nameBox"), FlTextInput);
		assertNotNull(nameBox, "LoginPopupGraphic renders named TextInput component as FlTextInput");
		assertEquals(true, nameBox.editable, "TextInput component is editable");
		assertClose(1, nameBox.transform.matrix.a, "TextInput width does not horizontally scale its text");

		var serverDropdown = Std.downcast(popup.getChildByTimelineName("dropdown"), FlComboBox);
		assertNotNull(serverDropdown, "LoginPopupGraphic renders server dropdown as FlComboBox");
		assertClose(1, serverDropdown.transform.matrix.a, "ComboBox width does not horizontally scale its caption");

		var passBox = Std.downcast(popup.getChildByTimelineName("passBox"), FlTextInput);
		assertNotNull(passBox, "LoginPopupGraphic renders password TextInput component as FlTextInput");
		assertEquals(true, passBox.displayAsPassword, "password TextInput preserves displayAsPassword");
	}

	private static function testLoginPopupUsesAuthoredComponentsOnly():Void {
		var popup = new LoginFlashPopup("LoginPopupGraphic");
		assertEquals(1, popup.numChildren, "login popup contains only its authored graphic");
		assertNotNull(popup.checkBox("rememberMe_chk"), "login popup exposes the authored checkbox state");
		popup.setMessage("synthetic status must not be added");
		assertEquals(1, popup.numChildren, "status updates do not add a synthetic text overlay");
		popup.remove();
	}

	private static function testStaticTextHonorsAuthoredAttributes():Void {
		var clip = new PR2MovieClip(makeStaticTextSymbol());

		// Authored attribute element: fillColor #254489 (the credits' blue),
		// negative letterSpacing, and non-zero line leading all carried in textAttrs.
		var styled = Std.downcast(clip.getChildByTimelineName("styled"), TextField);
		assertNotNull(styled, "DOMStaticText renders as a TextField");
		assertEquals("Credits", styled.text, "DOMStaticText keeps its authored text");
		var format = styled.defaultTextFormat;
		assertEquals(0x254489, format.color, "fillColor hex is honored instead of hardcoded black");
		assertClose(-0.05, format.letterSpacing, "authored letterSpacing is applied");
		assertClose(2.0, format.leading, "authored lineSpacing maps to TextFormat leading");
		assertEquals(TextFormatAlign.RIGHT, format.align, "authored alignment is applied");
		var styledMatrix = styled.transform.matrix;
		assertClose(22, styledMatrix.tx, "static-text left is composed with matrix scale into tx");
		assertClose(23, styledMatrix.ty, "static-text left is composed with matrix skew into ty");

		// Element with no fillColor/letterSpacing must keep Animate's defaults:
		// black text and unset (null) letterSpacing rather than a parsed value.
		var plain = Std.downcast(clip.getChildByTimelineName("plain"), TextField);
		assertNotNull(plain, "second DOMStaticText renders as a TextField");
		assertEquals(0x000000, plain.defaultTextFormat.color, "missing fillColor defaults to black");
		assertClose(0, plain.defaultTextFormat.letterSpacing, "missing letterSpacing keeps the default 0 spacing");
	}

	private static function makeStaticTextSymbol():SymbolAssetDef {
		return {
			href: "StaticTextSymbol.xml",
			type: "movie clip",
			name: "StaticTextSymbol",
			linkageClassName: "StaticTextSymbol",
			linkageIdentifier: "StaticTextSymbol",
			timelines: [{
				name: "StaticTextSymbol",
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
						elementTypes: ["DOMStaticText", "DOMStaticText"],
						elements: [
							{
								type: "DOMStaticText",
								name: "styled",
								text: "Credits",
								left: 6,
								width: 80,
								height: 16,
								matrix: {a: 2, b: 0.5, tx: 10, ty: 20},
								textAttrs: {
									face: "Verdana",
									size: 9.0,
									alignment: "right",
									fillColor: "#254489",
									letterSpacing: -0.05,
									lineSpacing: 2.0
								}
							},
							{
								type: "DOMStaticText",
								name: "plain",
								text: "by",
								left: 0,
								width: 40,
								height: 16,
								textAttrs: {face: "Verdana", size: 9.0}
							}
						]
					}]
				}]
			}]
		};
	}

	private static function testGeneratedIntroTimelines():Void {
		var page = PR2MovieClip.fromLinkage("IntroPageGraphic");
		var skipPrompt = findTextDescendant(page, "Click anywhere to skip");
		assertNotNull(skipPrompt, "IntroPageGraphic renders its skip prompt");
		assertClose(12, skipPrompt.defaultTextFormat.size, "skip prompt infers its 12px font from bitmapSize");
		assertEquals(true, skipPrompt.textWidth <= skipPrompt.width, "skip prompt fits its authored text field");

		assertIntroTimeline("JiggminIntroGraphic", 249);
		assertIntroTimeline("KongregateIntroGraphic", 153);
		assertIntroTimeline("ArmorIntroGraphic", 218);
		assertIntroTimeline("BubbleBoxIntroGraphic", 117);
	}

	private static function testTimelineCompositionPreservesPartSelection():Void {
		var runAnim = PR2MovieClip.fromLinkage("PR2_Graphics_1_Apr_2014_fla.jumpAnim_61", {maxNestedDepth: 12});
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

	private static function testGeneratedRunAnimationPartPlacement():Void {
		var character = PR2MovieClip.fromLinkage("CharacterGraphic", {maxNestedDepth: 12});
		CharacterAppearance.applyPartIds(character, {hat: 1, head: 1, body: 1, feet: 1});

		var runAnim = requireClipChild(character, "runAnim");
		var firstHeadY = Math.NaN;
		var firstFoot1X = Math.NaN;
		var firstFoot1Center:Point = null;
		var firstFoot2Center:Point = null;
		var sawHeadMotion = false;
		var sawFootMotion = false;
		var sawFoot1BoundsMotion = false;
		var sawFoot2BoundsMotion = false;

		for (frame in 1...runAnim.totalFrames + 1) {
			runAnim.gotoAndStop(frame);
			var head = requireClipChild(runAnim, "head");
			var body = requireClipChild(runAnim, "body");
			var foot1 = requireClipChild(runAnim, "foot1");
			var foot2 = requireClipChild(runAnim, "foot2");
			var hat1 = requireClipChild(head, "hat1");

			assertAbove(head, body, 'run frame $frame head is above body');
			assertAbove(body, foot1, 'run frame $frame body is above foot1');
			assertAbove(body, foot2, 'run frame $frame body is above foot2');
			assertNotOrigin(head, 'run frame $frame head transform is not origin');
			assertNotOrigin(body, 'run frame $frame body transform is not origin');
			assertNotOrigin(foot1, 'run frame $frame foot1 transform is not origin');
			assertNotOrigin(foot2, 'run frame $frame foot2 transform is not origin');
			assertNotOrigin(hat1, 'run frame $frame hat1 transform is not origin inside head');

			if (frame == 1) {
				firstHeadY = head.transform.matrix.ty;
				firstFoot1X = foot1.transform.matrix.tx;
				firstFoot1Center = boundsCenter(foot1, character);
				firstFoot2Center = boundsCenter(foot2, character);
			} else {
				sawHeadMotion = sawHeadMotion || Math.abs(head.transform.matrix.ty - firstHeadY) > 0.0001;
				sawFootMotion = sawFootMotion || Math.abs(foot1.transform.matrix.tx - firstFoot1X) > 0.0001;
				sawFoot1BoundsMotion = sawFoot1BoundsMotion || centerMoved(firstFoot1Center, boundsCenter(foot1, character), 0.5);
				sawFoot2BoundsMotion = sawFoot2BoundsMotion || centerMoved(firstFoot2Center, boundsCenter(foot2, character), 0.5);
			}
		}

		assertEquals(true, sawHeadMotion, "run animation moves head y across frames");
		assertEquals(true, sawFootMotion, "run animation moves foot1 x across frames");
		assertEquals(true, sawFoot1BoundsMotion, "run animation moves rendered foot1 bounds across frames");
		assertEquals(true, sawFoot2BoundsMotion, "run animation moves rendered foot2 bounds across frames");
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
		var clip = PR2MovieClip.fromLinkage(linkage, {maxNestedDepth: 12});
		assertEquals(totalFrames, clip.totalFrames, '$linkage totalFrames');
		assertHasLabel(clip, labelName, labelFrame);
		clip.gotoAndStop(labelName);
		assertEquals(labelFrame, clip.currentFrame, '$linkage gotoAndStop resolves $labelName');
		return clip;
	}

	private static function assertIntroTimeline(linkage:String, totalFrames:Int):Void {
		var intro = PR2MovieClip.fromLinkage(linkage, {maxNestedDepth: 4});
		assertEquals(totalFrames, intro.totalFrames, '$linkage totalFrames');
		assertAtLeast(1, intro.numChildren, '$linkage renders first frame children');
		assertAtLeast(1, intro.width, '$linkage renders non-empty first frame width');
		assertAtLeast(1, intro.height, '$linkage renders non-empty first frame height');
		intro.gotoAndStop(totalFrames);
		assertEquals(totalFrames, intro.currentFrame, '$linkage can seek to final frame');
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
							assertNotNull(PR2MovieClip.fromSymbolName(libraryItemName, {maxNestedDepth: 12}), '$message symbol can instantiate directly');
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

	private static function findTextDescendant(container:DisplayObjectContainer, text:String):Null<TextField> {
		for (i in 0...container.numChildren) {
			var child = container.getChildAt(i);
			var textField = Std.downcast(child, TextField);
			if (textField != null && textField.text == text) {
				return textField;
			}

			var childContainer = Std.downcast(child, DisplayObjectContainer);
			if (childContainer != null) {
				var found = findTextDescendant(childContainer, text);
				if (found != null) {
					return found;
				}
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

	private static function assertAbove(upper:DisplayObject, lower:DisplayObject, message:String):Void {
		assertions++;
		var upperY = upper.transform.concatenatedMatrix.ty;
		var lowerY = lower.transform.concatenatedMatrix.ty;
		if (upperY >= lowerY) {
			throw '$message: expected ${upper.name}.globalTy $upperY < ${lower.name}.globalTy $lowerY';
		}
	}

	private static function assertNotOrigin(child:DisplayObject, message:String):Void {
		assertions++;
		var matrix = child.transform.matrix;
		if (Math.abs(matrix.tx) <= 0.0001 && Math.abs(matrix.ty) <= 0.0001) {
			throw '$message: ${child.name} matrix tx/ty are both zero';
		}
	}

	private static function boundsCenter(child:DisplayObject, coordinateSpace:DisplayObject):Point {
		var bounds = child.getBounds(coordinateSpace);
		return new Point(bounds.x + bounds.width / 2, bounds.y + bounds.height / 2);
	}

	private static function centerMoved(first:Point, current:Point, minimumDelta:Float):Bool {
		return Math.abs(current.x - first.x) > minimumDelta || Math.abs(current.y - first.y) > minimumDelta;
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

	private static function makeSoundSymbol():SymbolAssetDef {
		return {
			href: "SoundSymbol.xml",
			type: "movie clip",
			name: "SoundSymbol",
			linkageClassName: "SoundSymbol",
			linkageIdentifier: "SoundSymbol",
			timelines: [{
				name: "SoundSymbol",
				layerCount: 1,
				frameCount: 3,
				labels: [],
				layers: [{
					index: 0,
					name: "Sound",
					visible: true,
					locked: false,
					layerType: "normal",
					frameCount: 2,
					frames: [
						{
							index: 0,
							duration: 2,
							soundName: "Sounds/first.mp3",
							elementCount: 0,
							elementTypes: []
						},
						{
							index: 2,
							duration: 1,
							soundName: "Sounds/second.mp3",
							elementCount: 0,
							elementTypes: []
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

	private static function makeLayeredSymbol():SymbolAssetDef {
		return {
			href: "LayeredSymbol.xml",
			type: "movie clip",
			name: "LayeredSymbol",
			linkageClassName: "LayeredSymbol",
			linkageIdentifier: "LayeredSymbol",
			timelines: [{
				name: "LayeredSymbol",
				layerCount: 3,
				frameCount: 1,
				labels: [],
				layers: [
					makeSingleShapeLayer(0, "Top Layer", "top"),
					makeSingleShapeLayer(1, "Middle Layer", "middle"),
					makeSingleShapeLayer(2, "Bottom Layer", "bottom")
				]
			}]
		};
	}

	private static function makeSingleShapeLayer(index:Int, layerName:String, childName:String):Dynamic {
		return {
			index: index,
			name: layerName,
			visible: true,
			locked: false,
			layerType: "normal",
			frameCount: 1,
			frames: [{
				index: 0,
				duration: 1,
				elementCount: 1,
				elementTypes: ["DOMShape"],
				elements: [{
					type: "DOMShape",
					name: childName,
					bounds: {left: 0, top: 0, right: 10, bottom: 10}
				}]
			}]
		};
	}

	private static function testPrimitiveDrawingObjects():Void {
		var clip = new PR2MovieClip(makePrimitiveSymbol());

		// DOMRectangleObject geometry is drawn from its objectWidth/objectHeight,
		// not from `edges`, so the placeholder crosshair (~8px) should not appear.
		// (the stroke weight widens the measured bounds by half a pixel per side).
		var rect = requireChild(clip, "rect");
		assertAtLeast(120, rect.width, "DOMRectangleObject renders its objectWidth");
		assertAtLeast(80, rect.height, "DOMRectangleObject renders its objectHeight");

		// DOMOvalObject renders as an unstroked ellipse of objectWidth x objectHeight.
		var oval = requireChild(clip, "oval");
		assertClose(60, oval.width, "DOMOvalObject renders its objectWidth");
		assertClose(40, oval.height, "DOMOvalObject renders its objectHeight");

		var hairline = requireChild(clip, "hairline");
		assertClose(40, hairline.width, "Flash hairline stroke does not inflate authoring-space bounds");
	}

	private static function makePrimitiveSymbol():SymbolAssetDef {
		return {
			href: "PrimitiveSymbol.xml",
			type: "movie clip",
			name: "PrimitiveSymbol",
			linkageClassName: "PrimitiveSymbol",
			linkageIdentifier: "PrimitiveSymbol",
			timelines: [{
				name: "PrimitiveSymbol",
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
						elementCount: 3,
						elementTypes: ["DOMRectangleObject", "DOMOvalObject", "DOMRectangleObject"],
						elements: [
							{
								type: "DOMRectangleObject",
								name: "rect",
								x: 0,
								y: 0,
								objectWidth: 120,
								objectHeight: 80,
								topLeftRadius: 10,
								topRightRadius: 10,
								bottomLeftRadius: 10,
								bottomRightRadius: 10,
								fill: {
									type: "LinearGradient",
									matrix: {a: 0.06, d: 0.06, tx: 60, ty: 40},
									entries: [
										{ratio: 0, color: "#9D9D9D", alpha: 0.4},
										{ratio: 1, color: "#FFFFFF", alpha: 0.65}
									]
								},
								stroke: {
									type: "SolidStroke",
									weight: 1,
									fill: {type: "SolidColor", color: "#333333"}
								}
							},
							{
								type: "DOMOvalObject",
								name: "oval",
								x: 0,
								y: 0,
								objectWidth: 60,
								objectHeight: 40,
								fill: {type: "SolidColor", color: "#00FF00"}
							},
							{
								type: "DOMRectangleObject",
								name: "hairline",
								x: 0,
								y: 0,
								objectWidth: 40,
								objectHeight: 30,
								stroke: {
									type: "SolidStroke",
									weight: 0.05,
									solidStyle: "hairline",
									fill: {type: "SolidColor", color: "#333333"}
								}
							}
						]
					}]
				}]
			}]
		};
	}

	private static function makeBlendModeSymbol():SymbolAssetDef {
		return {
			href: "BlendModeSymbol.xml",
			type: "movie clip",
			name: "BlendModeSymbol",
			linkageClassName: "BlendModeSymbol",
			linkageIdentifier: "BlendModeSymbol",
			timelines: [{
				name: "BlendModeSymbol",
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
						elementCount: 4,
						elementTypes: ["DOMShape", "DOMShape", "DOMShape", "DOMShape"],
						elements: [
							{
								type: "DOMShape",
								name: "multiply",
								blendMode: "multiply",
								bounds: {left: 0, top: 0, right: 10, bottom: 10}
							},
							{
								type: "DOMShape",
								name: "screen",
								blendMode: "screen",
								bounds: {left: 0, top: 0, right: 10, bottom: 10}
							},
							{
								type: "DOMShape",
								name: "layer",
								blendMode: "layer",
								bounds: {left: 0, top: 0, right: 10, bottom: 10}
							},
							{
								type: "DOMShape",
								name: "normal",
								bounds: {left: 0, top: 0, right: 10, bottom: 10}
							}
						]
					}]
				}]
			}]
		};
	}

	private static function makeScale9GridSymbol():SymbolAssetDef {
		return {
			href: "Scale9GridSymbol.xml",
			type: "movie clip",
			name: "Scale9GridSymbol",
			linkageClassName: "Scale9GridSymbol",
			linkageIdentifier: "Scale9GridSymbol",
			scaleGridLeft: 4.5,
			scaleGridRight: 95.5,
			scaleGridTop: 6.5,
			scaleGridBottom: 95,
			timelines: [{
				name: "Scale9GridSymbol",
				layerCount: 0,
				frameCount: 1,
				labels: [],
				layers: []
			}]
		};
	}

	private static function makeFilterSymbol():SymbolAssetDef {
		return {
			href: "FilterSymbol.xml",
			type: "movie clip",
			name: "FilterSymbol",
			linkageClassName: "FilterSymbol",
			linkageIdentifier: "FilterSymbol",
			timelines: [{
				name: "FilterSymbol",
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
							elementCount: 2,
							elementTypes: ["DOMShape", "DOMShape"],
							elements: [
								{
									type: "DOMShape",
									name: "filtered",
									bounds: {left: 0, top: 0, right: 10, bottom: 10},
									filters: [
										{type: "BlurFilter", blurX: 7, blurY: 9, quality: 2},
										{
											type: "GlowFilter",
											color: 0x123456,
											alpha: 0.4,
											blurX: 8,
											blurY: 10,
											strength: 3,
											quality: 2,
											inner: true,
											knockout: true
										},
										{
											type: "DropShadowFilter",
											distance: 6,
											angle: 30,
											color: 0x654321,
											alpha: 0.6,
											blurX: 11,
											blurY: 13,
											strength: 1.5,
											quality: 3,
											inner: true,
											knockout: true,
											hideObject: true
										}
									]
								},
								{
									type: "DOMShape",
									name: "defaults",
									bounds: {left: 0, top: 0, right: 10, bottom: 10},
									filters: [
										{type: "BlurFilter"},
										{type: "GlowFilter"},
										{type: "DropShadowFilter"}
									]
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
								name: "filtered",
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
								edges: [{fillStyle1: 1, edges: "!0 0|400 0!400 0|400 400!400 400|0 400!0 400|0 0"}]
							},
							{
								type: "DOMGroup",
								name: "group",
								children: [{
									type: "DOMShape",
									fills: [{index: 1, value: {type: "SolidColor", color: "#00FF00"}}],
									edges: [{fillStyle0: 1, edges: "!0 0[200 0 200 200!200 200|0 200!0 200|0 0"}]
								}]
							}
						]
					}]
				}]
			}]
		};
	}

	private static function makeNestedAnimatedGroupSymbol():SymbolAssetDef {
		return {
			href: "NestedAnimatedGroupSymbol.xml",
			type: "movie clip",
			name: "NestedAnimatedGroupSymbol",
			linkageClassName: "NestedAnimatedGroupSymbol",
			linkageIdentifier: "NestedAnimatedGroupSymbol",
			timelines: [{
				name: "NestedAnimatedGroupSymbol",
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
						elementCount: 1,
						elementTypes: ["DOMGroup"],
						elements: [{
							type: "DOMGroup",
							name: "group",
							children: [{
								type: "DOMSymbolInstance",
								libraryItemName: "Parts/Heads/headsMC"
							}]
						}]
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

	private static function makeUnresolvedChildSymbol():SymbolAssetDef {
		return {
			href: "UnresolvedChild.xml",
			type: "movie clip",
			name: "UnresolvedChild",
			timelines: [{
				name: "UnresolvedChild",
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
						elementCount: 1,
						elementTypes: ["DOMSymbolInstance"],
						elements: [{
							type: "DOMSymbolInstance",
							libraryItemName: "Missing/AuthoredSymbol"
						}]
					}]
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
