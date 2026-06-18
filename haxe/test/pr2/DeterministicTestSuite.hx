package pr2;

import pr2.character.CharacterAtlasTest;
import pr2.character.CharacterStateTest;
import pr2.crypto.PR2EncryptorTest;
import pr2.effects.PixelEffect1Test;
import pr2.harness.FixtureLevelRendererTest;
import pr2.harness.GameplayHarnessOptionsTest;
import pr2.harness.LocalPlayerControllerTest;
import pr2.level.LevelFixtureParserTest;
import pr2.lobby.LobbyServicesTest;
import pr2.level.ServerLevelDecoderTest;
import pr2.level.ServerLevelFixtureAdapterTest;
import pr2.level.ServerLevelRendererTest;
import pr2.net.AccountCreationClientTest;
import pr2.net.CampaignListClientTest;
import pr2.net.LevelDataClientTest;
import pr2.net.LoginAuthClientTest;
import pr2.net.LoginSocketProtocolTest;
import pr2.net.ServerConfigTest;
import pr2.net.ServerStatusClientTest;
import pr2.page.CampaignTestScreenTest;
import pr2.runtime.PR2MovieClipRuntimeTest;

class DeterministicTestSuite {
	public static function main():Void {
		PR2MovieClipRuntimeTest.main();
		PixelEffect1Test.main();
		CharacterAtlasTest.main();
		CharacterStateTest.main();
		PR2EncryptorTest.main();
		LevelFixtureParserTest.main();
		ServerLevelDecoderTest.main();
		ServerLevelFixtureAdapterTest.main();
		ServerLevelRendererTest.main();
		FixtureLevelRendererTest.main();
		GameplayHarnessOptionsTest.main();
		LocalPlayerControllerTest.main();
		ServerConfigTest.main();
		ServerStatusClientTest.main();
		LoginSocketProtocolTest.main();
		CampaignListClientTest.main();
		AccountCreationClientTest.main();
		LoginAuthClientTest.main();
		LevelDataClientTest.main();
		CampaignTestScreenTest.main();
		LobbyServicesTest.main();
		trace("DeterministicTestSuite passed");
	}
}
