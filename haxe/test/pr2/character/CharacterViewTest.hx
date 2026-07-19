package pr2.character;

import openfl.events.Event;
import openfl.filters.BlurFilter;
import pr2.character.CharacterRig.RigSlot;
import pr2.page.CustomizeCharacterScreen;
import pr2.runtime.PR2MovieClip;

class CharacterViewTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testGeneratedRigContract();
		if (pr2.DeterministicTestMode.finishSmokeSuite("CharacterViewTest")) return;
		testExplicitHierarchyAndColors();
		testPartRegistrationFollowsSlotRotation();
		testLegacyRootRegistration();
		testAppearanceSelectionAndPerPartColors();
		testBubbleBodyNestedLoops();
		testStandardHatStack();
		testExhaustiveHatAttachmentMatrix();
		testHatPositionParityAcrossEveryAnimationFrame();
		testFredBodyHierarchy();
		testHeldItemsAndWeaponActions();
		testStableEffectTargetsAndJetState();
		testDeterministicStandingLoop();
		testAllStateTimingAndEndBehavior();
		testSuperJumpChargeGlow();
		testExhaustiveStateTransitionMatrix();
		testFrozenOverlayAndCompletion();
		testMaintainableParityMatrices();
		trace('CharacterViewTest passed $assertions assertions');
	}

	private static function testBubbleBodyNestedLoops():Void {
		var rig = CharacterRig.loadClassic();
		var bubble = [for (variant in rig.parts.body.variants) if (variant.id == 21) variant][0];
		assertEquals(2, bubble.channelAnimations.length, "Bubble body retains both nested XFL loops");
		assertEquals(21, bubble.channelAnimations[0].frames.length, "Bubble primary loop retains all 21 authored frames");
		assertEquals("assets/svg/character/body/021_bubble/primary_frames/frame_001.svg", bubble.channelAnimations[0].frames[0],
			"Bubble primary loop starts on the source frame");
		assertEquals("assets/svg/character/body/021_bubble/static_frames/frame_021.svg", bubble.channelAnimations[1].frames[20],
			"Bubble shine loop retains its terminal source frame");

		var view = new CharacterView(0x123456, 0xABCDEF);
		view.setPartIds({head: 1, body: 21, feet: 1});
		var artwork = cast(view.slot("body").getChildByName("artwork"), openfl.display.Sprite);
		var firstPrimary = artwork.getChildByName("primary");
		assertEquals(1, view.bodyChannelAnimationFrame, "Bubble loops begin at Flash frame one");
		view.advanceOneFrame();
		assertEquals(2, view.bodyChannelAnimationFrame, "Bubble loops advance once per deterministic character tick");
		assertTrue(firstPrimary != artwork.getChildByName("primary"), "advancing replaces the rendered primary bubble frame");
		assertEquals(0x12, Std.int(artwork.getChildByName("primary").transform.colorTransform.redOffset),
			"animated Bubble primary frames retain the selected tint");
		for (_ in 0...20) view.advanceOneFrame();
		assertEquals(1, view.bodyChannelAnimationFrame, "Bubble frame 21 loops to frame one like gotoAndPlay(1)");
		var removedArtwork = artwork;
		view.setPartIds({head: 1, body: 1, feet: 1});
		assertEquals(1, view.bodyChannelAnimationFrame, "changing bodies resets the detached nested loops");
		assertEquals(null, removedArtwork.parent, "changing bodies detaches all Bubble animation artwork");
		view.advanceOneFrame();
		assertEquals(1, view.bodyChannelAnimationFrame, "non-animated bodies do not keep Bubble loops ticking");
		view.setPartIds({head: 1, body: 33, feet: 1});
		view.advanceOneFrame();
		assertEquals(1, view.bodyChannelAnimationFrame, "authored empty body frames remain valid after nested-animation support");
	}

	private static function testGeneratedRigContract():Void {
		var rig = CharacterRig.loadClassic();
		assertEquals("pr2-character-rig", rig.format, "neutral rig format marker");
		assertEquals(8, rig.version, "neutral rig version");
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
		assertEquals(14, CharacterRig.item(rig, "Sword").frames.length, "rig includes every sword swing frame");
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
			assertEquals(27, animation.frameRate, '${item.name} preserves the Flash frame rate');
			assertEquals(item.end, animation.endBehavior, '${item.name} preserves its end behavior');
			assertTrue(animation.slots.length >= 5, '${item.name} exposes all body/item slots');
			for (slot in animation.slots) assertEquals(item.frames, slot.frames.length, '${item.name}.${slot.name} has one transform per frame');
		}
	}

	private static function testHeldItemsAndWeaponActions():Void {
		var rig = CharacterRig.loadClassic();
		var view = new CharacterView();
		for (state in CharacterView.STATE_NAMES) {
			view.setState(state);
			var animation = CharacterRig.animation(rig, state);
			var heldSlot = [for (slot in animation.slots) if (slot.name == "heldItem") slot][0];
			var held = heldSlot.frames[0];
			var root = animation.root;
			var expectedY = root.b * held.tx + root.d * held.ty + root.ty;
			assertClose(expectedY, view.heldItemSocket.transform.concatenatedMatrix.ty,
				'$state held-item socket cancels the character-art root offset');
		}
		view.setState("stand");
		assertEquals(0, view.heldItemSocket.numChildren, "empty item leaves the stable held-item socket clear");
		for (name in ["Laser", "Mine", "Lightning", "Teleport", "Super Jump", "Jet Pack", "Speed Burst", "Sword", "Ice Wave", "Snake"]) {
			view.setItemFrameName(name);
			assertEquals(name, view.itemFrameName, '$name is selected by its protocol frame name');
			assertEquals(1, view.heldItemSocket.numChildren, '$name renders through the stable held-item socket');
		}
		view.setItemFrameName("Laser");
		assertTrue(view.playItemUseAnimation("Laser"), "laser starts its authored recoil");
		assertEquals(2, view.itemActionFrame, "laser starts at the XFL shoot label");
		view.advanceOneFrame();
		assertEquals(3, view.itemActionFrame, "laser recoil advances with the deterministic character clock");
		view.gotoFrame(view.frameCount);
		for (_ in 0...14) view.advanceOneFrame();
		assertEquals(1, view.itemActionFrame, "laser timeline loops to its idle frame after the final recoil frame");
		view.setItemFrameName("Sword");
		assertTrue(view.playItemUseAnimation("Sword"), "sword starts its authored swing");
		assertEquals(2, view.itemActionFrame, "sword starts at the XFL swing label");
		view.gotoItemActionFrame(7);
		assertEquals(7, view.itemActionFrame, "weapon actions can seek a generated parity frame deterministically");
		view.setState("run");
		assertEquals(1, view.itemActionFrame, "changing state resets an unfinished weapon action");
		assertEquals(false, view.itemActionPlaying, "state changes do not preserve a half-finished action");
		view.setItemFrameName("Mine");
		assertEquals(false, view.playItemUseAnimation("Laser"), "a non-laser held item cannot start the gun action");
		view.setItemFrameName("None");
		assertEquals(0, view.heldItemSocket.numChildren, "None clears held-item artwork");
	}

	private static function testMaintainableParityMatrices():Void {
		var defaults = new CustomizeCharacterScreen("default");
		assertEquals(9, defaults.parityCount(), "default screenshot matrix has nine deterministic poses");
		assertEquals("stand", defaults.parityView(0).currentState, "default matrix begins with standing reference");
		assertEquals(24, defaults.parityView(3).currentFrame, "default matrix includes a late standing transition frame");
		assertEquals("frozen", defaults.parityView(8).currentState, "default matrix includes frozen completion art");

		var colors = new CustomizeCharacterScreen("colors");
		assertEquals(9, colors.parityCount(), "color screenshot matrix has nine deterministic palettes");
		assertEquals(6, colors.parityView(1).hatId(0), "color matrix includes an authored visible hat");
		assertEquals(true, colors.parityView(1).hatSlot(0).visible, "color matrix renders its hat channel");

		var mixed = new CustomizeCharacterScreen("mixed-parts");
		assertEquals(9, mixed.parityCount(), "mixed screenshot matrix covers all nine states");
		for (index in 0...CharacterView.STATE_NAMES.length) {
			assertEquals(CharacterView.STATE_NAMES[index], mixed.parityView(index).currentState,
				'mixed matrix cell ${index + 1} covers ${CharacterView.STATE_NAMES[index]}');
		}
		assertEquals("Laser", mixed.parityView(1).itemFrameName, "mixed matrix includes weapon recoil art");
		assertEquals(7, mixed.parityView(1).itemActionFrame, "mixed matrix pins an authored laser action frame");
		assertEquals(true, mixed.parityView(6).jetActive, "mixed matrix includes the authored active jet frame");

		var tricky = new CustomizeCharacterScreen("tricky-parts");
		assertEquals(9, tricky.parityCount(), "tricky screenshot matrix has nine edge cases");
		assertEquals(29, tricky.parityView(0).partId("body"), "tricky matrix includes Fred body 29");
		assertEquals(tricky.parityView(1).slot("body"), tricky.parityView(1).hatSocket.parent,
			"tricky Fred case mounts four hats on the authored body hierarchy");
		assertEquals(4, tricky.parityView(1).hatSlots.filter(function(slot) return slot.visible).length,
			"tricky Fred case renders all four hat slots");
		assertEquals("Sword", tricky.parityView(7).itemFrameName, "tricky matrix includes sword action art");
		assertEquals(7, tricky.parityView(7).itemActionFrame, "tricky matrix pins sword swing frame seven");
		for (slot in ["head", "body", "frontFoot", "backFoot", "heldItem"]) {
			assertTrue(tricky.parityView(8).effectTarget(slot).getChildByName("attachmentMarker") != null,
				'tricky matrix visualizes the $slot attachment socket');
		}

		var hats = new CustomizeCharacterScreen("all-hats");
		assertEquals(9, hats.parityCount(), "hat screenshot matrix includes every authored hat plus shifted head 23");
		var seenHats:Array<Int> = [];
		for (index in 0...8) for (slot in 0...2) {
			var id = hats.parityView(index).hatId(slot);
			if (id > 1 && seenHats.indexOf(id) < 0) seenHats.push(id);
		}
		seenHats.sort(function(left, right) return left - right);
		assertEquals("2,3,4,5,6,7,8,9,10,11,12,13,14,15,16", seenHats.join(","), "hat matrix renders all fifteen non-empty hat ids");

		var fredStates = new CustomizeCharacterScreen("fred-states");
		assertEquals(9, fredStates.parityCount(), "Fred screenshot matrix covers all nine states");
		for (index in 0...CharacterView.STATE_NAMES.length) {
			assertEquals(CharacterView.STATE_NAMES[index], fredStates.parityView(index).currentState,
				'Fred matrix covers ${CharacterView.STATE_NAMES[index]}');
			assertEquals(29, fredStates.parityView(index).partId("body"), '${CharacterView.STATE_NAMES[index]} keeps Fred body 29');
			assertEquals(fredStates.parityView(index).slot("body"), fredStates.parityView(index).hatSocket.parent,
				'${CharacterView.STATE_NAMES[index]} keeps Fred hats on the body');
		}

		var attachments = new CustomizeCharacterScreen("attachments");
		assertEquals(9, attachments.parityCount(), "attachment screenshot matrix covers all nine states");
		for (index in 0...CharacterView.STATE_NAMES.length) {
			for (slot in ["head", "body", "frontFoot", "backFoot", "heldItem"]) {
				assertTrue(attachments.parityView(index).effectTarget(slot).getChildByName("attachmentMarker") != null,
					'${CharacterView.STATE_NAMES[index]} matrix visualizes $slot');
			}
		}

		var djinn = new CustomizeCharacterScreen("djinn-ice");
		assertEquals(9, djinn.parityCount(), "Djinn screenshot matrix covers all nine states");
		var bodyParticles = 0;
		var feetParticles = 0;
		for (index in 0...djinn.numChildren) {
			var child = djinn.getChildAt(index);
			if (child.name == "djinnBodyParticle") bodyParticles++;
			if (child.name == "djinnFeetParticle") feetParticles++;
		}
		assertEquals(18, bodyParticles, "Djinn matrix renders both body tint choices with negative particle scale in every state");
		assertEquals(36, feetParticles, "Djinn matrix renders both tint choices at both feet in every state");

		var specs:Array<{kind:String, id:Int}> = [];
		for (kind in ["head", "body", "feet"]) {
			var values = Parts.getPartArray(kind.toUpperCase());
			if (values != null) for (id in values) if (!(kind == "body" && id == 29)) specs.push({kind: kind, id: id});
		}
		assertEquals(141, specs.length, "paged parity matrices inventory all standard parts");
		for (page in 0...16) {
			var matrix = new CustomizeCharacterScreen('parts-$page');
			var expectedCount = Std.int(Math.min(9, specs.length - page * 9));
			assertEquals(expectedCount, matrix.parityCount(), 'part matrix page $page has no gaps or duplicates');
			for (index in 0...matrix.parityCount()) {
				var spec = specs[page * 9 + index];
				assertEquals(spec.id, matrix.parityView(index).partId(spec.kind), 'part matrix renders ${spec.kind} ${spec.id}');
				assertEquals(CharacterView.STATE_NAMES[(page * 9 + index) % CharacterView.STATE_NAMES.length], matrix.parityView(index).currentState,
					'${spec.kind} ${spec.id} retains its representative state pose');
			}
		}

		var itemSpecs:Array<{name:String, frame:Int}> = [];
		var rig = CharacterRig.loadClassic();
		for (name in ["Speed Burst", "Laser", "Mine", "Lightning", "Teleport", "Super Jump", "Jet Pack", "Sword", "Ice Wave"]) {
			var item = CharacterRig.item(rig, name);
			for (frame in 1...item.frames.length + 1) itemSpecs.push({name: name, frame: frame});
		}
		assertEquals(38, itemSpecs.length, "paged item matrices inventory every generated held-item frame");
		for (page in 0...5) {
			var matrix = new CustomizeCharacterScreen('items-$page');
			var expectedCount = Std.int(Math.min(9, itemSpecs.length - page * 9));
			assertEquals(expectedCount, matrix.parityCount(), 'item matrix page $page has no gaps or duplicates');
			for (index in 0...matrix.parityCount()) {
				var spec = itemSpecs[page * 9 + index];
				assertEquals(spec.name, matrix.parityView(index).itemFrameName, 'item matrix renders ${spec.name}');
				assertEquals(spec.frame, matrix.parityView(index).itemActionFrame, '${spec.name} renders authored frame ${spec.frame}');
			}
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

	private static function testExhaustiveHatAttachmentMatrix():Void {
		var rig = CharacterRig.loadClassic();
		var view = new CharacterView();
		for (hat in rig.parts.hat.variants) {
			view.setHatIds([hat.id, hat.id, hat.id, hat.id]);
			for (index in 0...4) {
				var expectedVisible = hat.id > 1;
				assertEquals(expectedVisible, view.hatSlot(index).visible,
					'hat ${hat.id} slot ${index + 1} preserves its authored empty/visible state');
				if (expectedVisible) {
					assertTrue(view.hatSlot(index).getChildByName("artwork") != null,
						'hat ${hat.id} slot ${index + 1} mounts its authored artwork');
				}
			}
			for (attachment in rig.hatAttachments) {
				view.setPartId("head", attachment.headId);
				for (index in 0...4) {
					var expected = attachment.slots[index].matrix;
					var actual = view.hatSlot(index).transform.matrix;
					assertClose(expected.a, actual.a, 'head ${attachment.headId}/hat ${hat.id}/slot ${index + 1} preserves matrix a');
					assertClose(expected.b, actual.b, 'head ${attachment.headId}/hat ${hat.id}/slot ${index + 1} preserves matrix b');
					assertClose(expected.c, actual.c, 'head ${attachment.headId}/hat ${hat.id}/slot ${index + 1} preserves matrix c');
					assertClose(expected.d, actual.d, 'head ${attachment.headId}/hat ${hat.id}/slot ${index + 1} preserves matrix d');
					assertClose(expected.tx, actual.tx,
						'head ${attachment.headId}/hat ${hat.id}/slot ${index + 1} preserves authored x attachment');
					assertClose(expected.ty, actual.ty,
						'head ${attachment.headId}/hat ${hat.id}/slot ${index + 1} preserves authored y attachment');
					assertClose(expected.alpha, view.hatSlot(index).alpha,
						'head ${attachment.headId}/hat ${hat.id}/slot ${index + 1} preserves authored alpha');
				}
			}
		}
		view.setPartId("head", 23);
		for (state in CharacterView.STATE_NAMES) {
			view.setState(state);
			assertEquals(view.slot("head"), view.hatSocket.parent, '$state keeps standard hats attached to the moving head');
			for (index in 0...4) assertEquals(index, view.hatSocket.getChildIndex(view.hatSlot(index)),
				'$state preserves the authored four-hat stacking order');
		}
	}

	private static function testHatPositionParityAcrossEveryAnimationFrame():Void {
		var hats = [6, 5, 13, 16];
		var ids = {hat: hats[0], hats: hats, head: 23, body: 28, feet: 40};
		var legacy = new CharacterDisplay(ids, null, false);
		var native = new CharacterView(0x2E8BFF, 0xFFD24A, null, "stand", {head: 23, body: 28, feet: 40}, hats);
		for (state in CharacterView.STATE_NAMES) {
			var legacyStateName = switch (state) {
				case "stand": "standAnim";
				case "run": "runAnim";
				case "jump": "jumpAnim";
				case "superJump": "superJumpAnim";
				case "bumped": "bumpedAnim";
				case "crouch": "crouchAnim";
				case "crouchWalk": "crouchWalkAnim";
				case "swim": "swimAnim";
				case "frozen": "frozenSolidAnim";
				default: throw 'Unknown character state $state';
			}
			legacy.setState(legacyStateName);
			native.setState(state);
			var legacyHead = Std.downcast(legacy.getStateClip(legacyStateName).getChildByTimelineName("head"), PR2MovieClip);
			for (frame in 1...native.frameCount + 1) {
				var legacyHatSlots = [for (index in 0...4) legacyHead.getChildByTimelineName('hat${index + 1}')];
				var legacyHatIndices = [for (slot in legacyHatSlots) legacyHead.getChildIndex(slot)];
				for (slot in legacyHatSlots) legacyHead.removeChild(slot);
				var legacyHeadBounds = legacyHead.getBounds(legacy);
				var nativeHeadBounds = native.slot("head").getChildByName("artwork").getBounds(native);
				for (index in 0...legacyHatSlots.length) legacyHead.addChildAt(legacyHatSlots[index], legacyHatIndices[index]);
				assertClose(legacyHeadBounds.x, nativeHeadBounds.x, '$state frame $frame head matches original x', 0.01);
				assertClose(legacyHeadBounds.y, nativeHeadBounds.y, '$state frame $frame head matches original y', 0.01);
				for (index in 0...4) {
					var legacyBounds = legacyHatSlots[index].getBounds(legacy);
					var nativeBounds = native.hatSlot(index).getBounds(native);
					assertClose(legacyBounds.x, nativeBounds.x, '$state frame $frame hat ${index + 1} matches original x', 0.001);
					assertClose(legacyBounds.y, nativeBounds.y, '$state frame $frame hat ${index + 1} matches original y', 0.001);
				}
				if (frame < native.frameCount) {
					legacy.advanceOneFrame();
					native.advanceOneFrame();
				}
			}
		}
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

	private static function testLegacyRootRegistration():Void {
		var legacy = new CharacterDisplay(null, null, false);
		legacy.setState("standAnim");
		var legacyState = legacy.getStateClip("standAnim");
		var nativeView = new CharacterView(0x2E8BFF, 0xFFD24A, null, "stand");
		for (pair in [
			{legacy: "head", nativeSlot: "head"},
			{legacy: "body", nativeSlot: "body"},
			{legacy: "foot1", nativeSlot: "frontFoot"},
			{legacy: "foot2", nativeSlot: "backFoot"}
		]) {
			var legacyX = legacyState.getChildByTimelineName(pair.legacy).getBounds(legacy).x;
			var nativeX = nativeView.slot(pair.nativeSlot).getBounds(nativeView).x;
			// The asymmetric classic-head silhouette is not the character's physical
			// axis; body and both feet establish the shared registration point.
			if (pair.nativeSlot != "head") {
				assertTrue(Math.abs(legacyX - nativeX) < 0.02, '${pair.nativeSlot} matches the legacy shared-root horizontal registration');
			}
			var legacyY = legacyState.getChildByTimelineName(pair.legacy).getBounds(legacy).y;
			var nativeY = nativeView.slot(pair.nativeSlot).getBounds(nativeView).y;
			assertClose(legacyY, nativeY, '${pair.nativeSlot} matches the legacy shared-root vertical registration', 0.02);
		}
		var hats = [6, 5, 13, 16];
		var legacyWithHats = new CharacterDisplay({hat: hats[0], hats: hats, head: 1, body: 1, feet: 1}, null, false);
		legacyWithHats.setState("standAnim");
		var legacyHead = Std.downcast(legacyWithHats.getStateClip("standAnim").getChildByTimelineName("head"), PR2MovieClip);
		var nativeWithHats = new CharacterView(0x2E8BFF, 0xFFD24A, null, "stand", {head: 1, body: 1, feet: 1}, hats);
		for (index in 0...4) {
			var legacyHat = legacyHead.getChildByTimelineName('hat${index + 1}');
			var legacyBounds = legacyHat.getBounds(legacyWithHats);
			var nativeBounds = nativeWithHats.hatSlot(index).getBounds(nativeWithHats);
			assertClose(legacyBounds.x, nativeBounds.x, 'hat slot ${index + 1} matches the original game horizontal position');
			assertClose(legacyBounds.y, nativeBounds.y, 'hat slot ${index + 1} matches the original game vertical position');
		}
	}

	private static function testPartRegistrationFollowsSlotRotation():Void {
		var rig = CharacterRig.loadClassic();
		var view = new CharacterView();
		for (state in ["run", "jump"]) {
			var legacyStateName = state + "Anim";
			var legacy = new CharacterDisplay(null, null, false);
			legacy.setState(legacyStateName);
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
				var legacyState = legacy.getStateClip(legacyStateName);
				for (pair in [
					{legacy: "body", nativeSlot: "body"},
					{legacy: "foot1", nativeSlot: "frontFoot"},
					{legacy: "foot2", nativeSlot: "backFoot"}
				]) {
					var legacyBounds = legacyState.getChildByTimelineName(pair.legacy).getBounds(legacy);
					var nativeBounds = view.slot(pair.nativeSlot).getBounds(view);
					assertClose(legacyBounds.x, nativeBounds.x, '$state frame $frame ${pair.nativeSlot} keeps the Flash pivot x', 0.02);
					assertClose(legacyBounds.y, nativeBounds.y, '$state frame $frame ${pair.nativeSlot} keeps the Flash pivot y', 0.02);
				}
				if (frame < animation.frameCount) {
					legacy.advanceOneFrame();
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
		view.gotoFrame(39);
		assertEquals(0, head.filters.length, "super-jump frame 39 has not started the authored charge glow");
		assertClose(0.25, head.transform.colorTransform.redMultiplier, "super-jump frame 39 keeps the authored pre-glow desaturation");
		assertClose(191, head.transform.colorTransform.redOffset, "super-jump frame 39 keeps the authored pre-glow brightness");

		view.gotoFrame(40);
		var blur = Std.downcast(head.filters[0], BlurFilter);
		assertTrue(blur != null, "super-jump frame 40 starts the authored horizontal blur");
		assertClose(25, blur.blurX, "super-jump frame 40 starts at the authored blur width");
		assertClose(0, blur.blurY, "super-jump charge glow remains horizontal");
		assertClose(0, head.transform.colorTransform.redMultiplier, "super-jump frame 40 replaces the original red channel");
		assertClose(255, head.transform.colorTransform.redOffset, "super-jump frame 40 starts fully yellow");
		assertClose(255, head.transform.colorTransform.greenOffset, "super-jump frame 40 starts fully yellow-green");
		assertClose(0, head.transform.colorTransform.blueOffset, "super-jump charge adds no blue offset");

		view.gotoFrame(46);
		blur = Std.downcast(head.filters[0], BlurFilter);
		assertClose(11.3636016845703, blur.blurX, "super-jump midpoint tapers the authored blur");
		assertClose(0.26953125, head.transform.colorTransform.redMultiplier, "super-jump midpoint restores the authored color fraction");
		assertClose(186, head.transform.colorTransform.redOffset, "super-jump midpoint tapers the yellow offset");

		view.gotoFrame(51);
		assertEquals(0, head.filters.length, "super-jump final frame finishes the horizontal blur");
		assertClose(0.5, head.transform.colorTransform.redMultiplier, "super-jump final frame keeps the authored yellow tint");
		assertClose(128, head.transform.colorTransform.redOffset, "super-jump final frame keeps the authored yellow offset");
		view.setState("stand");
		assertEquals(0, head.filters.length, "leaving super-jump clears its charge filter");
		assertClose(1, head.transform.colorTransform.redMultiplier, "leaving super-jump restores the normal character color transform");
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
