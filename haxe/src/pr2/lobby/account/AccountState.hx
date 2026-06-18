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

	private function new() {}
}
