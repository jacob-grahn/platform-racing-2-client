package pr2.tools;

import sys.io.File;

class SourceClassCoverageInventoryTest {
	private static var assertions:Int = 0;

	private static final BACKGROUND_CLASSES:Array<String> = [
		"Background",
		"BlockBackground",
		"BlockGridLines",
		"DrawableBackground",
		"EffectBackground",
		"LevelBackground",
		"Map",
		"ObjectBackground"
	];

	private static final ITEM_CLASSES:Array<String> = [
		"IceWave",
		"Item",
		"Items",
		"JetPack",
		"LaserGun",
		"Lightning",
		"Mine",
		"SpeedBurst",
		"SuperJump",
		"Sword",
		"Teleport"
	];

	private static final BLOCK_CLASSES:Array<String> = [
		"ArrowBlock",
		"ArrowDownBlock",
		"ArrowLeftBlock",
		"ArrowRightBlock",
		"ArrowUpBlock",
		"BasicBlock",
		"Block",
		"Blocks",
		"BrickBlock",
		"CrumbleBlock",
		"CustomStatsBlock",
		"FinishBlock",
		"HappyBlock",
		"HeartBlock",
		"IceBlock",
		"InfItemBlock",
		"ItemBlock",
		"MineBlock",
		"MoveBlock",
		"PushBlock",
		"RotateBlock",
		"RotateLeftBlock",
		"RotateRightBlock",
		"SadBlock",
		"SafetyBlock",
		"StartBlock",
		"SupplyBlock",
		"TeleportBlock",
		"TimeBlock",
		"VanishBlock",
		"WaterBlock"
	];

	private static final BLOCK_OPTION_CLASSES:Array<String> = [
		"BlockOptions",
		"CustomStatsBlockOptions",
		"ItemBlockOptions",
		"StatBlockOptions",
		"TeleportBlockOptions"
	];

	private static final CHARACTER_CLASSES:Array<String> = [
		"ArrowSparkleEmitter",
		"Character",
		"DjinnEffects",
		"LocalCharacter",
		"ParticleEmitter",
		"PhysicsParticle",
		"PositionedParticleEmitter",
		"RainbowStarEmitter",
		"RemoteCharacter"
	];

	private static final EFFECT_CLASSES:Array<String> = [
		"ArrowEffect",
		"BlockPiece",
		"Effect",
		"Egg",
		"Hat",
		"IceWaveShot",
		"LaserShot",
		"MineAppear",
		"MineExplode",
		"PhysicsEffect",
		"ShotEffect",
		"Slash",
		"StarEffect",
		"Sting",
		"TeleportPop",
		"Zap"
	];

	private static final GAMEPLAY_CLASSES:Array<String> = [
		"CatCaptcha",
		"CatImage",
		"Course",
		"CourseTimer",
		"DrawingInfo",
		"ExpGain",
		"FinishedPage",
		"Game",
		"Hearts",
		"ItemDisplay",
		"LuxPopup",
		"MiniMap",
		"Modes",
		"MusicSelection",
		"PlaceArtifact",
		"PrizePopup",
		"QuitButton",
		"RaceChat",
		"SpecialEvent",
		"SpectatePicker",
		"StatsDisplay",
		"TestCourse"
	];

	private static final SOUND_CLASSES:Array<String> = [
		"NoodleTown",
		"SoundEffects"
	];

	public static function main():Void {
		var inventory = File.getContent("docs/source-class-coverage.md");
		for (name in BACKGROUND_CLASSES) {
			assertContains(inventory, '`flash/background/$name.as`', 'inventory lists flash/background/$name.as');
		}
		for (name in ITEM_CLASSES) {
			assertContains(inventory, '`flash/items/$name.as`', 'inventory lists flash/items/$name.as');
		}
		for (name in BLOCK_CLASSES) {
			assertContains(inventory, '`flash/blocks/$name.as`', 'inventory lists flash/blocks/$name.as');
		}
		for (name in BLOCK_OPTION_CLASSES) {
			assertContains(inventory, '`flash/blocks/options/$name.as`', 'inventory lists flash/blocks/options/$name.as');
		}
		for (name in CHARACTER_CLASSES) {
			assertContains(inventory, '`flash/character/$name.as`', 'inventory lists flash/character/$name.as');
		}
		for (name in EFFECT_CLASSES) {
			assertContains(inventory, '`flash/effects/$name.as`', 'inventory lists flash/effects/$name.as');
		}
		for (name in SOUND_CLASSES) {
			assertContains(inventory, '`flash/sounds/$name.as`', 'inventory lists flash/sounds/$name.as');
		}
		for (name in GAMEPLAY_CLASSES) {
			assertContains(inventory, '`flash/gameplay/$name.as`', 'inventory lists flash/gameplay/$name.as');
		}
		assertContains(inventory, "pr2.harness.LocalPlayerController", "inventory maps item behavior to the controller");
		assertContains(inventory, "pr2.gameplay.Items", "inventory maps Items.as to the item catalog");
		assertContains(inventory, "pr2.level.ServerLevelDecoder", "inventory maps background data decoding");
		assertContains(inventory, "pr2.level.BlockType", "inventory maps block classes to block types");
		assertContains(inventory, "pr2.level.ServerLevelRenderer", "inventory maps visual block behavior to the renderer");
		assertContains(inventory, "pr2.character.Character", "inventory maps character base behavior");
		assertContains(inventory, "pr2.character.RemoteCharacter", "inventory maps remote character behavior");
		assertContains(inventory, "pr2.effects.BlockPiece", "inventory maps block-piece effects");
		assertContains(inventory, "pr2.effects.MineExplosion", "inventory maps mine explosion effects");
		assertContains(inventory, "pr2.audio.SoundEffects", "inventory maps spatial sound playback");
		assertContains(inventory, "pr2.audio.MenuMusic", "inventory maps Noodle Town menu music");
		assertContains(inventory, "pr2.gameplay.GameCommandShell", "inventory maps live game command routing");
		assertContains(inventory, "pr2.page.GamePage", "inventory maps game page lifecycle");
		assertContains(inventory, "ported", "inventory records status");
		trace('SourceClassCoverageInventoryTest passed $assertions assertions');
	}

	private static function assertContains(haystack:String, needle:String, message:String):Void {
		assertions++;
		if (haystack.indexOf(needle) == -1) {
			throw message + ' (missing "$needle")';
		}
	}
}
