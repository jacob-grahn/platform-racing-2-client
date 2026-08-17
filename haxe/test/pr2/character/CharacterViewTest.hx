package pr2.character;

import openfl.events.Event;
import openfl.filters.BlurFilter;
import pr2.character.CharacterRig.RigSlot;
import pr2.page.CustomizeCharacterScreen;

class CharacterViewTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		pr2.DeterministicTestMode.runTest("CharacterViewTest.testGeneratedRigContract", testGeneratedRigContract);
		if (pr2.DeterministicTestMode.finishSmokeSuite("CharacterViewTest")) return;
		pr2.DeterministicTestMode.runTest("CharacterViewTest.testExplicitHierarchyAndColors", testExplicitHierarchyAndColors);
		pr2.DeterministicTestMode.runTest("CharacterViewTest.testPartRegistrationFollowsSlotRotation", testPartRegistrationFollowsSlotRotation);
		pr2.DeterministicTestMode.runTest("CharacterViewTest.testAppearanceSelectionAndPerPartColors", testAppearanceSelectionAndPerPartColors);
		pr2.DeterministicTestMode.runTest("CharacterViewTest.testStandardHatStack", testStandardHatStack);
		pr2.DeterministicTestMode.runTest("CharacterViewTest.testFredBodyHierarchy", testFredBodyHierarchy);
		pr2.DeterministicTestMode.runTest("CharacterViewTest.testStableEffectTargetsAndJetState", testStableEffectTargetsAndJetState);
		pr2.DeterministicTestMode.runTest("CharacterViewTest.testLaserUseAnimationStopsAfterOnePass", testLaserUseAnimationStopsAfterOnePass);
		pr2.DeterministicTestMode.runTest("CharacterViewTest.testDeterministicStandingLoop", testDeterministicStandingLoop);
		pr2.DeterministicTestMode.runTest("CharacterViewTest.testAllStateTimingAndEndBehavior", testAllStateTimingAndEndBehavior);
		pr2.DeterministicTestMode.runTest("CharacterViewTest.testSuperJumpChargeGlow", testSuperJumpChargeGlow);
		pr2.DeterministicTestMode.runTest("CharacterViewTest.testSuperJumpWobbleDoesNotLeakIntoDisplayScale", testSuperJumpWobbleDoesNotLeakIntoDisplayScale);
		pr2.DeterministicTestMode.runTest("CharacterViewTest.testExhaustiveStateTransitionMatrix", testExhaustiveStateTransitionMatrix);
		pr2.DeterministicTestMode.runTest("CharacterViewTest.testFrozenOverlayAndCompletion", testFrozenOverlayAndCompletion);
		trace('CharacterViewTest passed $assertions assertions');
	}

	private static function testGeneratedRigContract():Void {
		var rig = CharacterRig.loadClassic();
		assertEquals("pr2-character-rig", rig.format, "neutral rig format marker");
		assertEquals(9, rig.version, "neutral rig version");
		assertEquals("MovieClips/Character", rig.source, "rig records its archival root source");
		assertEquals(50, rig.parts.head.variants.length, "rig includes every standard head export");
		assertEquals(47, rig.parts.body.variants.length, "rig includes standard bodies plus Fred");
		assertEquals(45, rig.parts.feet.variants.length, "rig includes every authored feet export");
		assertEquals(16, rig.parts.hat.variants.length, "rig includes every standard hat export");
		assertEquals("33,44,47", rig.emptyPartIds.body.join(","), "rig records authored empty body frames");
		assertEquals("31,32,33,44,47", rig.emptyPartIds.feet.join(","), "rig records authored empty feet frames");
		assertEquals(50, rig.hatAttachments.length, "rig records hat placement for every standard head");
		assertClose(62.75, rig.parts.head.registration.x, "rig restores the authored headsMC channel registration x");
		assertClose(76.85, rig.parts.head.registration.y, "rig restores the authored headsMC channel registration y");
		assertClose(33.5, rig.parts.body.registration.x, "rig restores the body channel registration x");
		assertClose(72.6, rig.parts.body.registration.y, "rig restores the body channel registration y");
		assertClose(28.4, rig.parts.feet.registration.x, "rig restores the feet channel registration x");
		assertClose(10.7, rig.parts.feet.registration.y, "rig restores the feet channel registration y");
		assertClose(-10, rig.hatStackStep.x, "rig records horizontal multi-hat registration step");
		assertClose(-16, rig.hatStackStep.y, "rig records vertical multi-hat registration step");
		assertEquals(29, rig.fred.bodyId, "rig identifies Fred's body frame");
		assertEquals(3, rig.fred.hiddenSlots.length, "rig records Fred's hidden head and feet slots");
		assertEquals(4, rig.fred.hatAttachments.length, "rig records Fred's body-mounted hat slots");
		assertEquals(9, rig.items.length, "rig includes every authored held-item choice");
		assertEquals(16, CharacterRig.item(rig, "Laser").frames.length, "rig includes every gun recoil frame");
		assertEquals("hold", CharacterRig.item(rig, "Laser").actionEndBehavior, "laser recoil stops after one pass");
		assertEquals(14, CharacterRig.item(rig, "Sword").frames.length, "rig includes every sword swing frame");
		assertEquals("hold", CharacterRig.item(rig, "Sword").actionEndBehavior, "sword swing stops after one pass");
		assertEquals(2, CharacterRig.item(rig, "Jet Pack").frames.length, "rig includes jet-off and jet-on art");
		for (attachment in rig.hatAttachments) assertEquals(4, attachment.slots.length, 'head ${attachment.headId} has four authored hat slots');
		assertEquals(9, rig.animations.length, "rig includes every CharacterGraphic state");
		var expected = [
			{name: "stand", frames: 31, end: "loop"},
			{name: "run", frames: 7, end: "loop"},
			{name: "jump", frames: 50, end: "hold"},
			{name: "superJump", frames: 51, end: "hold"},
			{name: "bumped", frames: 56, end: "loop"},
			{name: "crouch", frames: 11, end: "loop"},
			{name: "crouchWalk", frames: 11, end: "loop"},
			{name: "swim", frames: 13, end: "loop"},
			{name: "frozen", frames: 48, end: "hold-complete"}
		];
		for (item in expected) {
			var animation = CharacterRig.animation(rig, item.name);
			assertEquals(item.frames, animation.frameCount, '${item.name} preserves its authored frame count');
			assertEquals(30, animation.frameRate, '${item.name} uses the port frame rate');
			assertEquals(item.end, animation.endBehavior, '${item.name} preserves its end behavior');
			assertTrue(animation.slots.length >= 5, '${item.name} exposes all body/item slots');
			for (slot in animation.slots) assertEquals(item.frames, slot.frames.length, '${item.name}.${slot.name} has one transform per frame');
		}
	}

	private static function testStableEffectTargetsAndJetState():Void {
		var view = new CharacterView();
		assertEquals(view.slot("head"), view.effectTarget("head"), "head effects use a stable native target");
		assertEquals(view.slot("body"), view.effectTarget("body"), "body effects use a stable native target");
		assertEquals(view.slot("frontFoot"), view.effectTarget("frontFoot"), "front-foot effects use a stable native target");
		view.setState("runAnim");
		assertEquals("run", view.currentState, "legacy state aliases normalize at the native boundary");
		view.setItemFrameName("Jet Pack");
		assertTrue(view.setJetActive(true), "jet item exposes its authored on state");
		assertEquals(true, view.jetActive, "jet active state is explicit");
		assertEquals(2, view.itemActionFrame, "jet-on selects the generated XFL on frame");
		view.setJetFlame(0.625, 0.875);
		assertClose(0.625, view.jetFireScale, "jet fire-one scale is explicit");
		assertClose(0.875, view.jetFireAlpha, "jet fire-two alpha is explicit");
		var jetHolder = Std.downcast(view.heldItemSocket.getChildByName("heldItemArtwork"), openfl.display.Sprite);
		var jetArtwork = Std.downcast(jetHolder.getChildByName("jetPackActiveArtwork"), openfl.display.Sprite);
		assertClose(0.625, jetArtwork.getChildByName("fire1").scaleY, "jet fire-one flicker updates the rendered thrust scale");
		assertClose(0.875, jetArtwork.getChildByName("fire2").alpha, "jet fire-two flicker updates the rendered thrust alpha");
		view.setJetActive(false);
		assertEquals(1, view.itemActionFrame, "jet-off restores the generated XFL off frame");
	}

	private static function testLaserUseAnimationStopsAfterOnePass():Void {
		var view = new CharacterView();
		view.setItemFrameName("Laser");
		assertEquals(true, view.playItemUseAnimation("Laser"), "laser starts its authored recoil");
		@:privateAccess view.itemActionFrame = 16;
		view.advanceOneFrame();
		assertEquals(16, view.itemActionFrame, "laser recoil finishes on its authored idle frame");
		assertEquals(false, view.itemActionPlaying, "laser recoil stops after one pass");
		view.advanceOneFrame();
		assertEquals(16, view.itemActionFrame, "stopped laser recoil does not loop back to its start");
	}

	private static function testFredBodyHierarchy():Void {
		var view = new CharacterView();
		view.setHatIds([6, 5, 13, 16]);
		view.setPartIds({head: 37, body: 29, feet: 40});
		assertEquals(29, view.partId("body"), "Fred selects authored body frame 29");
		assertEquals(false, view.slot("head").visible, "Fred hides the ordinary head slot");
		assertEquals(false, view.slot("frontFoot").visible, "Fred hides the front foot slot");
		assertEquals(false, view.slot("backFoot").visible, "Fred hides the back foot slot");
		assertEquals(view.slot("body"), view.hatSocket.parent, "Fred mounts hats in the body hierarchy");
		assertClose(14.8, view.hatSlot(0).transform.matrix.tx, "Fred first hat preserves its authored body attachment x");
		assertClose(-129.35, view.hatSlot(0).transform.matrix.ty, "Fred first hat preserves its authored body attachment y");
		assertClose(-4.7, view.hatSlot(3).transform.matrix.tx, "Fred fourth hat preserves its authored body attachment x");
		assertClose(-176.55, view.hatSlot(3).transform.matrix.ty, "Fred fourth hat preserves its authored body attachment y");

		view.setState("crouch");
		assertEquals(false, view.slot("head").visible, "Fred keeps the head hidden after a state change");
		assertEquals(false, view.slot("frontFoot").visible, "Fred keeps feet hidden after a state change");
		assertEquals(view.slot("body"), view.hatSocket.parent, "Fred hats keep following the body after a state change");

		view.setPartId("body", 28);
		assertEquals(true, view.slot("head").visible, "leaving Fred restores the head slot");
		assertEquals(true, view.slot("frontFoot").visible, "leaving Fred restores the front foot slot");
		assertEquals(true, view.slot("backFoot").visible, "leaving Fred restores the back foot slot");
		assertEquals(view.slot("head"), view.hatSocket.parent, "leaving Fred restores head-mounted hats");
	}

	private static function testStandardHatStack():Void {
		var view = new CharacterView();
		assertEquals(4, view.hatSlots.length, "native view exposes four stable hat slots");
		for (index in 0...4) {
			assertEquals('hat${index + 1}', view.hatSlot(index).name, 'hat slot ${index + 1} has an explicit name');
			assertEquals(index, view.hatSocket.getChildIndex(view.hatSlot(index)), 'hat slot ${index + 1} preserves archival stacking order');
			assertEquals(false, view.hatSlot(index).visible, 'empty hat slot ${index + 1} is hidden');
		}

		view.setHatIds([6, 5, 13, 16]);
		for (index in 0...4) {
			assertEquals([6, 5, 13, 16][index], view.hatId(index), 'hat slot ${index + 1} selects its authored id');
			assertTrue(view.hatSlot(index).visible, 'selected hat slot ${index + 1} is visible');
			assertTrue(view.hatSlot(index).getChildByName("artwork") != null, 'selected hat slot ${index + 1} owns native artwork');
		}

		view.setHatSlotColors([
			{primary: 0x112233, secondary: -1},
			{primary: 0x445566, secondary: 0x778899},
			{primary: 0xAABBCC, secondary: 0xDDEEFF},
			{primary: 0x123456, secondary: 0xABCDEF}
		]);
		assertHatChannelColor(view, 0, "primary", 0x112233, "first hat primary color is independent");
		assertEquals(false, hatChannel(view, 0, "secondary").visible, "first hat can omit its epic channel independently");
		assertHatChannelColor(view, 1, "secondary", 0x778899, "second hat epic color is independent");
		assertHatChannelColor(view, 3, "primary", 0x123456, "fourth hat primary color is independent");

		assertClose(45.2, view.hatSlot(0).transform.matrix.tx, "classic head uses the authored first-hat attachment");
		view.setPartId("head", 23);
		assertClose(53.3, view.hatSlot(0).transform.matrix.tx, "head 23 uses its authored shifted first-hat x");
		view.setState("run");
		assertClose(53.3, view.hatSlot(0).transform.matrix.tx, "hat attachment stays local while the state moves the head");

		var rejectedHat = false;
		try view.setHatIds([17, 1, 1, 1]) catch (_:Dynamic) rejectedHat = true;
		assertTrue(rejectedHat, "unknown hat ids are rejected instead of approximated");
		view.setHatIds([1, 1, 1, 1]);
		for (index in 0...4) assertEquals(false, view.hatSlot(index).visible, 'clearing hat slot ${index + 1} hides it');
	}

	private static function hatChannel(view:CharacterView, index:Int, channelName:String):openfl.display.DisplayObject {
		var artwork = cast(view.hatSlot(index).getChildByName("artwork"), openfl.display.Sprite);
		return artwork.getChildByName(channelName);
	}

	private static function assertHatChannelColor(view:CharacterView, index:Int, channelName:String, color:Int, message:String):Void {
		var transform = hatChannel(view, index, channelName).transform.colorTransform;
		assertEquals((color >> 16) & 0xFF, Std.int(transform.redOffset), '$message (red)');
		assertEquals((color >> 8) & 0xFF, Std.int(transform.greenOffset), '$message (green)');
		assertEquals(color & 0xFF, Std.int(transform.blueOffset), '$message (blue)');
	}

	private static function testAppearanceSelectionAndPerPartColors():Void {
		var view = new CharacterView();
		var originalHead = view.slot("head").getChildByName("artwork");
		view.setPartIds({head: 37, body: 28, feet: 40});
		assertEquals(37, view.partId("head"), "native view selects an authored head id");
		assertEquals(28, view.partId("body"), "native view selects an authored body id");
		assertEquals(40, view.partId("feet"), "native view selects an authored feet id");
		assertTrue(originalHead != view.slot("head").getChildByName("artwork"), "part selection replaces head artwork");
		assertEquals(view.slot("head"), view.hatSocket.parent, "part replacement preserves the stable hat socket");

		view.setPartColor("head", 0x112233, -1);
		view.setPartColor("body", 0x445566, 0x778899);
		view.setPartColor("feet", 0xAABBCC, 0xDDEEFF);
		assertChannelColor(view, "head", "primary", 0x112233, "head primary color is independent");
		assertEquals(false, partChannel(view, "head", "secondary").visible, "head can omit its epic channel independently");
		assertChannelColor(view, "body", "primary", 0x445566, "body primary color is independent");
		assertChannelColor(view, "body", "secondary", 0x778899, "body epic color is independent");
		assertChannelColor(view, "frontFoot", "primary", 0xAABBCC, "front foot uses the shared feet primary color");
		assertChannelColor(view, "backFoot", "secondary", 0xDDEEFF, "back foot uses the shared feet epic color");

		var rejectedBody = false;
		view.setPartId("body", 33);
		assertEquals(0, cast(view.slot("body").getChildByName("artwork"), openfl.display.Sprite).numChildren,
			"authored empty body frames remain valid blank parts");
		try view.setPartId("body", 51) catch (_:Dynamic) rejectedBody = true;
		assertTrue(rejectedBody, "unknown body ids are rejected instead of approximated");
	}

	private static function partChannel(view:CharacterView, slotName:String, channelName:String):openfl.display.DisplayObject {
		var artwork = cast(view.slot(slotName).getChildByName("artwork"), openfl.display.Sprite);
		return artwork.getChildByName(channelName);
	}

	private static function assertChannelColor(view:CharacterView, slotName:String, channelName:String, color:Int, message:String):Void {
		var transform = partChannel(view, slotName, channelName).transform.colorTransform;
		assertEquals((color >> 16) & 0xFF, Std.int(transform.redOffset), '$message (red)');
		assertEquals((color >> 8) & 0xFF, Std.int(transform.greenOffset), '$message (green)');
		assertEquals(color & 0xFF, Std.int(transform.blueOffset), '$message (blue)');
	}

	private static function testExplicitHierarchyAndColors():Void {
		var view = new CharacterView(0x123456, 0xABCDEF);
		assertEquals("rigRoot", view.getChildAt(0).name, "native rig root is explicit");
		assertClose(-0.35, view.getChildAt(0).transform.matrix.tx, "native root keeps the authored horizontal registration");
		assertClose(0.45, view.getChildAt(0).transform.matrix.ty, "native root keeps the authored vertical registration");
		assertEquals("heldItem", view.heldItemSocket.name, "held-item socket is explicit");
		assertEquals("hatSocket", view.hatSocket.name, "hat socket is explicit");
		assertEquals(view.slot("head"), view.hatSocket.parent, "hat socket follows the head slot");
		assertEquals(0x123456, view.primaryColor, "primary color is retained");
		assertEquals(0xABCDEF, view.secondaryColor, "secondary color is retained");
		var primary = cast(view.slot("head").getChildByName("artwork"), openfl.display.Sprite).getChildByName("primary");
		var transform = primary.transform.colorTransform;
		assertEquals(0x12, Std.int(transform.redOffset), "primary red channel uses a solid offset");
		assertEquals(0x34, Std.int(transform.greenOffset), "primary green channel uses a solid offset");
		assertEquals(0x56, Std.int(transform.blueOffset), "primary blue channel uses a solid offset");
		view.setColors(0x010203, -1);
		var bodyArtwork = cast(view.slot("body").getChildByName("artwork"), openfl.display.Sprite);
		assertEquals(false, bodyArtwork.getChildByName("secondary").visible, "negative epic color hides the secondary channel");
	}

	private static function testPartRegistrationFollowsSlotRotation():Void {
		var rig = CharacterRig.loadClassic();
		var view = new CharacterView();
		for (state in ["run", "jump"]) {
			view.setState(state);
			var animation = CharacterRig.animation(rig, state);
			var slot = [for (candidate in animation.slots) if (candidate.name == "frontFoot") candidate][0];
			for (frame in 1...animation.frameCount + 1) {
				var source = slot.frames[frame - 1];
				var registration = rig.parts.feet.registration;
				var actual = view.slot("frontFoot").transform.matrix;
				assertClose(source.tx + source.a * registration.x + source.c * registration.y, actual.tx,
					'$state frame $frame composes the foot registration through its rotated x basis');
				assertClose(source.ty + source.b * registration.x + source.d * registration.y, actual.ty,
					'$state frame $frame composes the foot registration through its rotated y basis');
				if (frame < animation.frameCount) {
					view.advanceOneFrame();
				}
			}
		}
	}

	private static function testDeterministicStandingLoop():Void {
		var view = new CharacterView();
		var head = view.slot("head");
		assertClose(-55.2, head.transform.matrix.tx, "first standing frame uses the authored head x");
		assertClose(-394.9, head.transform.matrix.ty, "first standing frame uses the authored head y");
		view.dispatchEvent(new Event(Event.ENTER_FRAME));
		assertEquals(1, view.currentFrame, "stage ENTER_FRAME does not advance the deterministic rig");
		view.advanceOneFrame();
		assertEquals(2, view.currentFrame, "gameplay-clock advancement selects frame two");
		assertClose(-54.85, head.transform.matrix.tx, "frame two applies the generated XFL matrix");
		view.gotoFrame(31);
		view.advanceOneFrame();
		assertEquals(1, view.currentFrame, "standing animation loops after frame 31");
	}

	private static function testAllStateTimingAndEndBehavior():Void {
		var view = new CharacterView();
		for (state in ["run", "crouch", "crouchWalk", "swim"]) {
			view.setState(state);
			view.gotoFrame(view.frameCount);
			view.advanceOneFrame();
			assertEquals(1, view.currentFrame, '$state loops after its authored final frame');
		}
		for (state in ["jump", "superJump"]) {
			view.setState(state);
			view.gotoFrame(view.frameCount);
			view.advanceOneFrame();
			assertEquals(view.frameCount, view.currentFrame, '$state holds its authored final frame');
		}
		view.setState("bumped");
		view.gotoFrame(view.frameCount - 1);
		view.advanceOneFrame();
		assertEquals("bumpedComplete", view.endSignal, "bumped sets its archival last-frame flag");
		view.advanceOneFrame();
		assertEquals(1, view.currentFrame, "bumped loops after setting its last-frame flag");
		view.setState("run");
		assertEquals(null, view.endSignal, "changing state clears the prior end signal");
		assertEquals(1, view.currentFrame, "changing state rewinds the new animation");
	}

	private static function testSuperJumpChargeGlow():Void {
		var view = new CharacterView();
		view.setState("superJump");
		var head = view.slot("head");
		var body = view.slot("body");
		var heldItem = view.slot("heldItem");
		var rigRoot = Std.downcast(view.getChildByName("rigRoot"), openfl.display.Sprite);
		assertEquals(head, view.hatSocket.parent, "super-jump keeps the equipped hat stack attached to the moving head");
		assertTrue(rigRoot.getChildIndex(head) > rigRoot.getChildIndex(body), "super-jump preserves Flash's head-and-hats layer above the body");
		view.gotoFrame(39);
		assertEquals(0, rigRoot.filters.length, "super-jump frame 39 has not started the authored charge glow");
		assertClose(0.25, rigRoot.transform.colorTransform.redMultiplier, "super-jump frame 39 keeps the authored pre-glow desaturation");
		assertClose(191, rigRoot.transform.colorTransform.redOffset, "super-jump frame 39 keeps the authored pre-glow brightness");
		assertClose(1, head.transform.colorTransform.redMultiplier, "super-jump effects are not applied separately to the head");
		assertClose(1, heldItem.transform.colorTransform.redMultiplier, "the held item inherits the shared character effect");

		view.gotoFrame(40);
		var blur = Std.downcast(rigRoot.filters[0], BlurFilter);
		assertTrue(blur != null, "super-jump frame 40 starts the authored horizontal blur");
		assertClose(25, blur.blurX, "super-jump frame 40 starts at the authored blur width");
		assertClose(0, blur.blurY, "super-jump charge glow remains horizontal");
		assertClose(0, rigRoot.transform.colorTransform.redMultiplier, "super-jump frame 40 replaces the original red channel");
		assertClose(255, rigRoot.transform.colorTransform.redOffset, "super-jump frame 40 starts fully yellow");
		assertClose(255, rigRoot.transform.colorTransform.greenOffset, "super-jump frame 40 starts fully yellow-green");
		assertClose(0, rigRoot.transform.colorTransform.blueOffset, "super-jump charge adds no blue offset");
		assertEquals(0, head.filters.length, "the head does not create its own filtered cache");
		assertEquals(0, heldItem.filters.length, "the held item does not create its own filtered cache");

		view.gotoFrame(46);
		blur = Std.downcast(rigRoot.filters[0], BlurFilter);
		assertClose(11.3636016845703, blur.blurX, "super-jump midpoint tapers the authored blur");
		assertClose(0.26953125, rigRoot.transform.colorTransform.redMultiplier, "super-jump midpoint restores the authored color fraction");
		assertClose(186, rigRoot.transform.colorTransform.redOffset, "super-jump midpoint tapers the yellow offset");

		view.gotoFrame(51);
		assertEquals(0, rigRoot.filters.length, "super-jump final frame finishes the horizontal blur");
		assertClose(0.5, rigRoot.transform.colorTransform.redMultiplier, "super-jump final frame keeps the authored yellow tint");
		assertClose(128, rigRoot.transform.colorTransform.redOffset, "super-jump final frame keeps the authored yellow offset");
		view.setState("stand");
		assertEquals(0, rigRoot.filters.length, "leaving super-jump clears its charge filter");
		assertClose(1, rigRoot.transform.colorTransform.redMultiplier, "leaving super-jump restores the normal character color transform");
	}

	private static function testSuperJumpWobbleDoesNotLeakIntoDisplayScale():Void {
		var view = new CharacterView();
		view.scaleY = 0.5;
		view.setSuperJumpWobbleRandomForTest(function():Float return 0);
		view.setState("superJump");
		var rigRoot = view.getChildByName("rigRoot");
		var stableRootD = rigRoot.transform.matrix.d;
		view.gotoFrame(50);
		view.advanceOneFrame();
		assertClose(0.8725, rigRoot.transform.matrix.d / stableRootD, "super-jump final-frame wobble keeps the authored random squash");
		assertClose(0.5, view.scaleY, "super-jump wobble does not overwrite the caller-owned display scale");

		view.setState("superJump");
		assertClose(1, rigRoot.transform.matrix.d / stableRootD, "restarting super-jump clears the prior random wobble scale");
		view.setState("stand");
		var stableStandD = rigRoot.transform.matrix.d;
		view.advanceOneFrame();
		assertClose(stableStandD, rigRoot.transform.matrix.d, "leaving super-jump restores a stable artwork scale");
		assertClose(0.5, view.scaleY, "leaving super-jump preserves the caller-owned display scale");
	}

	private static function testExhaustiveStateTransitionMatrix():Void {
		var rig = CharacterRig.loadClassic();
		var view = new CharacterView();
		for (source in CharacterView.STATE_NAMES) {
			for (target in CharacterView.STATE_NAMES) {
				view.setState(source);
				view.gotoFrame(Std.int((view.frameCount + 1) / 2));
				view.setItemFrameName("Sword");
				view.playItemUseAnimation("Sword");
				view.setState(target);
				var animation = CharacterRig.animation(rig, target);
				assertEquals(target, view.currentState, '$source to $target selects the requested authored state');
				assertEquals(1, view.currentFrame, '$source to $target restarts at frame one, including same-state replay');
				assertEquals(animation.frameCount, view.frameCount, '$source to $target installs the authored duration');
				assertEquals(animation.frameRate, view.frameRate, '$source to $target installs the authored clock rate');
				assertEquals(null, view.endSignal, '$source to $target clears interrupted completion state');
				assertEquals(1, view.itemActionFrame, '$source to $target resets interrupted held-item playback');
				assertEquals(false, view.itemActionPlaying, '$source to $target clears interrupted item playback state');
				var ordered = animation.slots.copy();
				ordered.sort(function(left:RigSlot, right:RigSlot):Int return left.drawOrder - right.drawOrder);
				var root = cast(view.getChildByName("rigRoot"), openfl.display.Sprite);
				for (index in 0...ordered.length) {
					assertEquals(ordered[index].name, root.getChildAt(index).name,
						'$source to $target preserves XFL layer order for ${ordered[index].name}');
				}
			}
		}
	}

	private static function testFrozenOverlayAndCompletion():Void {
		var view = new CharacterView(0x2E8BFF, 0xFFD24A, null, "frozen");
		var overlay = view.slot("frozenOverlay");
		assertTrue(overlay != null && overlay.visible, "frozen state exposes its native ice overlay");
		assertClose(1, overlay.alpha, "frozen overlay starts at its authored opacity");
		var completes = 0;
		view.addEventListener(Event.COMPLETE, function(_:Event):Void completes++);
		view.gotoFrame(view.frameCount - 1);
		view.advanceOneFrame();
		assertEquals("complete", view.endSignal, "frozen exposes its completion signal");
		assertClose(0.5, overlay.alpha, "frozen overlay fades to its authored final opacity");
		assertEquals(1, completes, "frozen dispatches completion on its final frame");
		view.advanceOneFrame();
		assertEquals(view.frameCount, view.currentFrame, "frozen holds its final frame");
		assertEquals(1, completes, "frozen completion dispatches only once");
		view.setState("stand");
		assertEquals(false, overlay.visible, "leaving frozen hides the ice overlay");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}

	private static function assertClose(expected:Float, actual:Float, message:String, tolerance:Float = 0.0001):Void {
		assertions++;
		if (Math.abs(expected - actual) > tolerance) throw '$message: expected $expected, got $actual';
	}

	private static function assertTrue(actual:Bool, message:String):Void {
		assertions++;
		if (!actual) throw '$message: expected true';
	}
}
