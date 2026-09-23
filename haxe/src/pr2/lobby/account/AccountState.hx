package pr2.lobby.account;

/**
	Minimal wrapper for the pieces of Flash `player_profile.AccountInfo` that other
	lobby code reads as statics. Right now only `currentHat` is needed (level access
	checks compare it against a level's disallowed-hat list); the full account
	customization subsystem populates the rest as it is ported.
**/
class AccountState {
	/** Equipped hat id (Flash `AccountInfo.currentHat`). -1 = none / unknown. */
	public static var currentHat:Int = -1;

	/** Keep access checks available even when the account editor is not visible. */
	public static function applyCustomize(data:AccountCustomizeData):Void {
		pr2.lobby.SecureData.setNumber("userRank", data.rank);
		currentHat = data.hat;
		pr2.net.CommandHandler.commandHandler.dispatch("testLevelAccess", []);
	}

	private function new() {}
}
