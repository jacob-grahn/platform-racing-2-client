package pr2.lobby.tabs;

/**
	Port-in-progress of Flash `player_profile.AccountInfo` (the Account tab).

	Renders the real `AccountInfoGraphic` art and requests the customize info
	(`get_customize_info`) on enter. The character preview, part/color/stat
	selectors, rank token controls, loadouts, and `set_customize_info` writes are
	still being ported.
**/
class AccountTab extends ScaffoldTab {
	public function new() {
		super("AccountInfoGraphic", "get_customize_info`", null,
			"Account — character preview and part/color/stat selectors are being ported.");
	}
}
