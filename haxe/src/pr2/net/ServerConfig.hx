package pr2.net;

/**
	Endpoints and hash salts for talking to the live PR2 server, mirrored from
	the Flash client (`Main.baseURL`/`Main.levelsURL` and `Env`). Only the values
	needed to fetch and validate public level data are included here; account and
	socket secrets are intentionally left out of the port for now.
**/
final class ServerConfig {
	/** Production build string accepted by the current PR2 server. **/
	public static inline var BUILD:String = "29-oct-2023-v168_2_1";

	/** Default origin, matching `Main.baseURL` in the Flash client. **/
	public static inline var DEFAULT_HOST:String = "https://pr2hub.com";

	/** Hash salt used when listing levels (`Env.LEVEL_LIST_SALT`). **/
	public static inline var LEVEL_LIST_SALT:String = "984cn98c54$";
	/** Hash salt used when checking level passwords (`Env.LEVEL_PASS_SALT`). **/
	public static inline var LEVEL_PASS_SALT:String = "WGZSL3JWcUE9L3Q4YipZIQ==";
	/** Hash salt used when uploading a level (`Env.LEVEL_SALT`). **/
	public static inline var LEVEL_SALT:String = "84ge5tnr";
	/** AES key used for encrypted level-password responses (`Env.LEVEL_PASS_KEY`). **/
	public static inline var LEVEL_PASS_KEY:String = "OWdCREBKUkI9JjEpQCNuYg==";
	/** AES IV used for encrypted level-password responses (`Env.LEVEL_PASS_IV`). **/
	public static inline var LEVEL_PASS_IV:String = "ZiUybmpjc04mNEAkNythbg==";

	/** Hash salt applied to a downloaded level txt file (`Env.LEVEL_SALT_2`). **/
	public static inline var LEVEL_SALT_2:String = "0kg4%dsw";

	/** Hash salt used in the in-race `finish_drawing` readiness payload. **/
	public static inline var LEVEL_HASH_SALT:String = "N^&drwseawf";

	/** Pixels per block segment; the Flash block strings are in these units. **/
	public static inline var SEG_SIZE:Int = 30;

	/**
		Host (origin or path prefix) that level endpoints are built on.
		pr2hub.com sends no CORS headers, so a browser cannot read its responses
		cross-origin. For html5 dev, point this at a same-origin proxy prefix
		such as `/api` (see `tools/dev_proxy.py`) via `?apiHost=/api`.
	**/
	private static var host:String = DEFAULT_HOST;

	private function new() {}

	public static function setHost(value:Null<String>):Void {
		if (value != null && StringTools.trim(value) != "") {
			host = StringTools.trim(value);
		}
	}

	public static function resetHost():Void {
		host = DEFAULT_HOST;
	}

	public static function applyLocalOverrides(?apiHost:Null<String>):Void {
		if (apiHost == null) {
			#if sys
			apiHost = Sys.getEnv("PR2_API_HOST");
			#end
		}
		setHost(apiHost);
	}

	public static function getHost():String {
		return host;
	}

	public static function hasProxyHost():Bool {
		return host != DEFAULT_HOST;
	}

	/**
		Course list endpoint, e.g. `listUrl("campaign", 1)` ->
		`{host}/files/lists/campaign/1`. Matches `LevelListing.requestCourses`.
	**/
	public static function listUrl(mode:String, page:Int):String {
		return host + "/files/lists/" + mode + "/" + page;
	}

	/**
		Single level txt endpoint, matching `Game.getLevelData`:
		`{host}/levels/{id}.txt?version={version}`.
	**/
	public static function levelDataUrl(levelId:Int, version:Int):String {
		return host + "/levels/" + levelId + ".txt?version=" + version;
	}

	/** Luna portrait loaded by Flash `gameplay.LuxPopup`. */
	public static function lunaImageUrl():String {
		return host + "/img/luna.jpg";
	}

	/**
		Live multiplayer server status endpoint, matching `CheckServers`.
	**/
	public static function serverStatusUrl():String {
		return host + "/files/server_status_2.txt";
	}

	/**
		Account creation endpoint, matching `CreateAccountPopup`.
	**/
	public static function registerUserUrl():String {
		return host + "/register_user.php";
	}

	/**
		Encrypted login endpoint, matching `LoggingInPopup`.
	**/
	public static function loginUrl():String {
		return host + "/login.php";
	}

	/**
		Password recovery endpoint, matching `menu.ForgotPassPopup`.
	**/
	public static function forgotPasswordUrl():String {
		return host + "/forgot_password.php";
	}

	public static function logoutUrl():String {
		return host + "/logout.php";
	}

	public static function changePasswordUrl():String {
		return host + "/change_password.php";
	}

	public static function vaultUrl():String return host + "/vault/vault.php";
	public static function vaultPurchaseUrl():String return host + "/vault/purchase_item.php";
	public static function vaultSuperBoosterUrl():String return host + "/vault/use_super_booster.php";
	public static function vaultBuyCoinsUrl():String return host + "/vault/buy_coins.php";

	/**
		Friends/Following/Ignored player list endpoint, matching
		`social.PlayersTabUserListDataLoader`: `{host}/user_list_get.php?mode={mode}`.
	**/
	public static function userListUrl(mode:String):String {
		return host + "/user_list_get.php?mode=" + StringTools.urlEncode(mode);
	}

	/**
		Top guilds endpoint, matching `social.Guilds`: `{host}/guilds_top.php`.
	**/
	public static function guildsTopUrl():String {
		return host + "/guilds_top.php";
	}

	/** Guild profile lookup, matching `dialogs.GuildPopup`. */
	public static function guildInfoUrl(id:Int = 0, name:String = ""):String {
		return host + "/guild_info.php?id=" + id + "&name=" + StringTools.urlEncode(name) + "&getMembers=yes";
	}

	public static function guildCreateUrl():String {
		return host + "/guild_create.php";
	}

	public static function guildEditUrl():String {
		return host + "/guild_edit.php";
	}

	public static function guildJoinUrl():String {
		return host + "/guild_join.php";
	}

	public static function emblemUploadUrl():String {
		return host + "/emblem_upload.php";
	}

	public static function emblemsUrl():String {
		return host + "/emblems/";
	}

	/** Private-message list GET, matching `chat.Messages.getMessages`. */
	public static function messagesGetUrl(start:Int, count:Int):String {
		return host + "/messages_get.php?start=" + start + "&count=" + count;
	}

	public static function messageSendUrl():String {
		return host + "/message_send.php";
	}

	public static function guildMessageUrl():String {
		return host + "/guild_message.php";
	}

	public static function messageReportUrl():String {
		return host + "/message_report.php";
	}

	public static function messageDeleteUrl():String {
		return host + "/message_delete.php";
	}

	public static function messagesDeleteAllUrl():String {
		return host + "/messages_delete_all.php";
	}

	/** Player profile lookup, matching `dialogs.PlayerPopup.playerInfoFromHTTP`. */
	public static function getPlayerInfoUrl(name:String):String {
		return host + "/get_player_info.php?name=" + StringTools.urlEncode(name);
	}

	/** Friend/following/ignored list add/remove POST, matching `PlayerPopup.handleUserListURL`. */
	public static function userListModifyUrl():String {
		return host + "/user_list_modify.php";
	}

	/** Guild invite POST, matching `PlayerPopup.clickInvite`. */
	public static function guildInviteUrl():String {
		return host + "/guild_invite.php";
	}

	/** Guild kick POST, matching `PlayerPopup.clickKick`. */
	public static function guildKickUrl():String {
		return host + "/guild_kick.php";
	}

	/** Moderator ban POST endpoint, matching `dialogs.BanMenu`. */
	public static function banUserUrl():String {
		return host + "/ban_user.php";
	}

	/** Favorites add/remove POST, matching `LevelItem.handleFavorite`. */
	public static function favoriteModifyUrl():String {
		return host + "/favorite_levels_modify.php";
	}

	/**
		Favorites list POST endpoint, matching `level_browser.Favorites.requestCourses`.
		Unlike the other listing modes, favorites use a dedicated endpoint (POST
		`user_id` + `page`) rather than the generic `{host}/files/lists/...` path.
	**/
	public static function favoriteLevelsGetUrl():String {
		return host + "/favorite_levels_get.php";
	}

	/** Level password check POST, matching `LevelItem.clickPassEnter`. */
	public static function levelPassCheckUrl():String {
		return host + "/level_pass_check.php";
	}

	/** Search POST endpoint, matching `level_browser.Search.requestCourses`. */
	public static function searchLevelsUrl():String {
		return host + "/search_levels.php";
	}

	/** Level rating POST endpoint, matching `ui.RatingSelect.rateLevel`. */
	public static function submitRatingUrl():String {
		return host + "/submit_rating.php";
	}

	/** Level report POST endpoint, matching `dialogs.LevelReportPopup`. */
	public static function levelReportUrl():String {
		return host + "/level_report.php";
	}

	/** Level moderation POST endpoint, matching `dialogs.ChooseLevelModModePopup`. */
	public static function levelModerateUrl():String {
		return host + "/level_moderate.php";
	}

	/** Editor owned-level list POST endpoint, matching `level_management.GetLevels`. */
	public static function levelsGetUrl():String {
		return host + "/levels_get.php";
	}

	/** Moderator reported-level list POST endpoint, matching `level_management.GetLevelReports`. */
	public static function levelsGetReportedUrl():String {
		return host + "/levels_get_reported.php";
	}

	/** Moderator report archive POST endpoint, matching `level_management.HandleLevelReportPopup`. */
	public static function archiveReportUrl():String {
		return host + "/mod/archive_report.php";
	}

	/** Level upload POST endpoint, matching `level_management.UploadingLevelPopup`. */
	public static function uploadLevelUrl():String {
		return host + "/upload_level.php";
	}

	/** Level delete POST endpoint, matching `level_management.DeletingLevelPopup`. */
	public static function deleteLevelUrl():String {
		return host + "/delete_level.php";
	}

	/** Artifact placement POST endpoint, matching `gameplay.PlaceArtifact`. */
	public static function placeArtifactUrl():String {
		return host + "/place_artifact.php";
	}

	/** Cat captcha challenge endpoint, matching `gameplay.CatCaptcha`. */
	public static function catCaptchaUrl():String {
		return host + "/cat/cat-captcha.php";
	}

	/** Cat captcha image endpoint, matching `gameplay.CatImage`. */
	public static function catImageUrl():String {
		return host + "/cat/cat-img.php";
	}

	/** Cat captcha answer POST endpoint, matching `gameplay.CatCaptcha`. */
	public static function catCaptchaSubmitUrl():String {
		return host + "/cat/captcha-submit.php";
	}
}
