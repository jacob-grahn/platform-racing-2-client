package pr2.lobby.dialogs;

import pr2.lobby.LobbySession;
import pr2.lobby.chat.ChatText;

class DiscordVerificationPopup extends UploadingPopup {
	public static inline var VERIFY_URL:String = "https://jiggmin2.com/discord/verify_pr2.php";

	public function new(code:String) {
		super(VERIFY_URL, [
			"code" => code,
			"pr2_name" => ChatText.trimWhitespace(LobbySession.userName),
		], "Verifying...");
	}
}
