package pr2;

import pr2.character.CharacterAtlasTest;
import pr2.crypto.PR2EncryptorTest;
import pr2.effects.PixelEffect1Test;
import pr2.harness.FixtureLevelRendererTest;
import pr2.harness.GameplayHarnessOptionsTest;
import pr2.harness.LocalPlayerControllerTest;
import pr2.level.LevelFixtureParserTest;
import pr2.level.ServerLevelDecoderTest;
import pr2.level.ServerLevelFixtureAdapterTest;
import pr2.level.ServerLevelRendererTest;
import pr2.net.AccountCreationClientTest;
import pr2.net.LevelDataClientTest;
import pr2.net.LoginAuthClientTest;
import pr2.net.ServerStatusClientTest;
import pr2.runtime.PR2MovieClipRuntimeTest;

class DeterministicTestSuite {
	public static function main():Void {
		PR2MovieClipRuntimeTest.main();
		PixelEffect1Test.main();
		CharacterAtlasTest.main();
		PR2EncryptorTest.main();
		LevelFixtureParserTest.main();
		ServerLevelDecoderTest.main();
		ServerLevelFixtureAdapterTest.main();
		ServerLevelRendererTest.main();
		FixtureLevelRendererTest.main();
		GameplayHarnessOptionsTest.main();
		LocalPlayerControllerTest.main();
		ServerStatusClientTest.main();
		AccountCreationClientTest.main();
		LoginAuthClientTest.main();
		LevelDataClientTest.main();
		trace("DeterministicTestSuite passed");
	}
}
