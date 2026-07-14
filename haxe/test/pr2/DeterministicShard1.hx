package pr2;

import pr2.gameplay.player.LocalPlayerControllerTest;

class DeterministicShard1 {
	public static function main():Void {
		LocalPlayerControllerTest.main();
		trace("DeterministicShard1 passed");
		Sys.exit(0);
	}
}
