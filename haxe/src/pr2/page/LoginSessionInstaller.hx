package pr2.page;

import pr2.lobby.LobbySession;
import pr2.lobby.account.Presets;
import pr2.lobby.account.Settings;
import pr2.lobby.messages.UnreadNotif;
import pr2.net.LoginSessionGate.LoginSessionResult;
import pr2.net.SavedAccounts;
import pr2.net.ServerInfo;

class LoginSessionInstaller {
	private function new() {}

	public static function install(session:LoginSessionResult, server:ServerInfo, remember:Bool):Void {
		LobbySession.begin(session.userName, session.group, server, session.userId, remember);
		LobbySession.updateAccountState(session.hasEmail, session.token, false);
		LobbySession.updateGuildState(session.guildId, session.guildName, session.guildOwner, session.emblem, false);
		LobbySession.favoriteLevels = session.favoriteLevels;
		LobbySession.lastAuthTime.setTime(session.authTime);
		UnreadNotif.setLastRead(session.lastRead);
		UnreadNotif.notifyUser(session.lastRecv);
		Settings.init(session.userName);
		Presets.load();
		if (remember) {
			SavedAccounts.add(session.userName, session.token);
		}
	}
}
