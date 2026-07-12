package pr2;

import pr2.character.CharacterBaseTest;
import pr2.character.CharacterDisplayTest;
import pr2.character.CharacterStateTest;
import pr2.character.LocalCharacterEmitTest;
import pr2.character.LocalCharacterTest;
import pr2.character.ParticleEmitterTest;
import pr2.character.RemoteCharacterConsumeTest;
import pr2.gameplay.CharacterLifecycleTest;
import pr2.gameplay.MultiplayerRaceStageTest;

class DeterministicShard2 {
	public static function main():Void {
		CharacterBaseTest.main();
		CharacterDisplayTest.main();
		CharacterStateTest.main();
		LocalCharacterTest.main();
		LocalCharacterEmitTest.main();
		ParticleEmitterTest.main();
		RemoteCharacterConsumeTest.main();
		CharacterLifecycleTest.main();
		MultiplayerRaceStageTest.main();
		trace("DeterministicShard2 passed");
		Sys.exit(0);
	}
}
