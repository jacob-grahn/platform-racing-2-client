package pr2.app;

import pr2.net.ServerInfo;
import pr2.page.Page;

/** The only place that selects between classic and mobile page implementations. */
class ScreenFactory {
	#if ((pr2_mobile_ui && pr2_ui_preview) || (pr2_classic_ui && pr2_ui_preview) || (pr2_classic_ui && pr2_mobile_ui))
	#error "Choose only one UI configuration: classic, mobile, or preview."
	#end

	public static var isMobile(default, null):Bool = #if pr2_mobile_ui true #else false #end;
	private static var siteMode:String = "kongregate";
	private static var activePrize:Null<pr2.lobby.dialogs.Popup>;

	/** Release builds deliberately ignore runtime UI overrides. */
	public static function configure(query:Null<String>, site:String = "kongregate"):Void {
		siteMode = site;
		#if pr2_ui_preview
		isMobile = QueryParams.get(query, "ui") == "mobile";
		#end
	}

	public static function login(?site:String):Page {
		if (site != null) siteMode = site;
		#if pr2_mobile_ui
		return new pr2.page.MobileLoginPage(siteMode);
		#elseif pr2_ui_preview
		return isMobile ? new pr2.page.MobileLoginPage(siteMode) : new pr2.page.LoginPage(siteMode);
		#else
		return new pr2.page.LoginPage(siteMode);
		#end
	}

	public static function lobby(?userName:String, ?server:ServerInfo):Page {
		#if pr2_mobile_ui
		return new pr2.page.MobileLobbyPage(userName, server);
		#elseif pr2_ui_preview
		return isMobile ? new pr2.page.MobileLobbyPage(userName, server) : new pr2.page.LobbyPage(userName, server);
		#else
		return new pr2.page.LobbyPage(userName, server);
		#end
	}

	public static function installPreviewSelector():Void {
		#if (pr2_ui_preview && js && html5)
		var select = js.Browser.document.createSelectElement();
		select.id = "pr2-ui-preview";
		select.setAttribute("aria-label", "Development preview UI");
		select.style.cssText = "position:fixed;left:8px;top:8px;z-index:10000;font:14px sans-serif;padding:6px;";
		for (value in ["classic", "mobile"]) {
			var option = js.Browser.document.createOptionElement();
			option.value = value;
			option.text = "Preview: " + value;
			select.add(option);
		}
		select.value = isMobile ? "mobile" : "classic";
		select.onchange = function(_) {
			// Restart rather than switching a live socket/session underneath a page.
			var url = new js.html.URL(js.Browser.location.href);
			url.searchParams.set("ui", select.value);
			js.Browser.location.href = url.href;
		};
		js.Browser.document.body.appendChild(select);
		#end
	}

	public static function profile(name:String, guest:Bool = false, autoLoad:Bool = true):pr2.lobby.dialogs.Popup {
		#if pr2_mobile_ui
		return new pr2.mobile.MobileProfilePopup(name, guest, autoLoad);
		#elseif pr2_ui_preview
		if (isMobile) return new pr2.mobile.MobileProfilePopup(name, guest, autoLoad);
		return guest ? new pr2.lobby.dialogs.PlayerGuestPopup(name) : new pr2.lobby.dialogs.PlayerPopup(name, autoLoad);
		#else
		return guest ? new pr2.lobby.dialogs.PlayerGuestPopup(name) : new pr2.lobby.dialogs.PlayerPopup(name, autoLoad);
		#end
	}

	public static function composeMessage(name:String = "", message:String = "", guild:Bool = false, focusName:Bool = false):pr2.lobby.dialogs.Popup {
		#if pr2_mobile_ui
		return new pr2.mobile.MobileComposePopup(name, message, guild, focusName);
		#elseif pr2_ui_preview
		return isMobile ? new pr2.mobile.MobileComposePopup(name, message, guild, focusName) : new pr2.lobby.dialogs.SendMessagePopup(name, message, guild, focusName);
		#else
		return new pr2.lobby.dialogs.SendMessagePopup(name, message, guild, focusName);
		#end
	}

	public static function guild(id:Int = 0, name:String = "", autoLoad:Bool = true):pr2.lobby.dialogs.Popup {
		#if pr2_mobile_ui
		return new pr2.mobile.MobileGuildPopup(id, name, autoLoad);
		#elseif pr2_ui_preview
		return isMobile ? new pr2.mobile.MobileGuildPopup(id, name, autoLoad) : new pr2.lobby.dialogs.GuildPopup(id, name, autoLoad);
		#else
		return new pr2.lobby.dialogs.GuildPopup(id, name, autoLoad);
		#end
	}

	public static function editGuild(id:Int = 0):pr2.lobby.dialogs.Popup {
		#if pr2_mobile_ui
		return new pr2.mobile.MobileGuildEditorPopup(id);
		#elseif pr2_ui_preview
		return isMobile ? new pr2.mobile.MobileGuildEditorPopup(id) : new pr2.lobby.dialogs.CreateGuildPopup(id);
		#else
		return new pr2.lobby.dialogs.CreateGuildPopup(id);
		#end
	}

	public static function guildTransfer():pr2.lobby.dialogs.Popup {
		#if pr2_mobile_ui
		return new pr2.mobile.MobileGuildTransferPopup();
		#elseif pr2_ui_preview
		return isMobile ? new pr2.mobile.MobileGuildTransferPopup() : new pr2.lobby.dialogs.TransferGuildPopup();
		#else
		return new pr2.lobby.dialogs.TransferGuildPopup();
		#end
	}

	public static function confirm(message:String, action:Void->Void, title:String="PLEASE CONFIRM"):pr2.lobby.dialogs.Popup {
		#if pr2_mobile_ui
		return new pr2.mobile.MobileConfirmPopup(message,action,title);
		#elseif pr2_ui_preview
		return isMobile ? new pr2.mobile.MobileConfirmPopup(message,action,title) : new pr2.lobby.dialogs.ConfirmPopup(action,message);
		#else
		return new pr2.lobby.dialogs.ConfirmPopup(action,message);
		#end
	}

	public static function upload(url:String, fields:Map<String,String>, label:String, onResult:Dynamic->Void, ?onError:String->Void):pr2.lobby.dialogs.Popup {
		#if pr2_mobile_ui
		return new pr2.mobile.MobileRequestPopup(url,fields,label,onResult,onError);
		#elseif pr2_ui_preview
		return isMobile ? new pr2.mobile.MobileRequestPopup(url,fields,label,onResult,onError) : new pr2.lobby.dialogs.UploadingPopup(url,fields,label,onResult,onError);
		#else
		return new pr2.lobby.dialogs.UploadingPopup(url,fields,label,onResult,onError);
		#end
	}

	public static function message(value:String,title:String="MESSAGE"):pr2.lobby.dialogs.Popup {
		#if pr2_mobile_ui
		return new pr2.mobile.MobileMessagePopup(value,title);
		#elseif pr2_ui_preview
		return isMobile ? new pr2.mobile.MobileMessagePopup(value,title) : new pr2.lobby.dialogs.MessagePopup(value);
		#else
		return new pr2.lobby.dialogs.MessagePopup(value);
		#end
	}

	public static function options():pr2.lobby.dialogs.Popup {
		#if pr2_mobile_ui
		return new pr2.mobile.MobileOptionsPopup();
		#elseif pr2_ui_preview
		return isMobile ? new pr2.mobile.MobileOptionsPopup() : new pr2.lobby.dialogs.OptionsPopup();
		#else
		return new pr2.lobby.dialogs.OptionsPopup();
		#end
	}

	public static function credits():pr2.lobby.dialogs.Popup {
		#if pr2_mobile_ui
		return new pr2.mobile.MobileCreditsPopup();
		#elseif pr2_ui_preview
		return isMobile ? new pr2.mobile.MobileCreditsPopup() : new pr2.lobby.dialogs.CreditsPopup();
		#else
		return new pr2.lobby.dialogs.CreditsPopup();
		#end
	}

	public static function levelInfo(id:Int):pr2.lobby.dialogs.Popup {
		#if pr2_mobile_ui
		return new pr2.mobile.MobileLevelInfoPopup(id);
		#elseif pr2_ui_preview
		return isMobile ? new pr2.mobile.MobileLevelInfoPopup(id) : new pr2.lobby.dialogs.LevelInfoPopup(id);
		#else
		return new pr2.lobby.dialogs.LevelInfoPopup(id);
		#end
	}

	public static function partInfo(type:String,id:Int,name:String,description:String,obtain:String,owned:Bool,epic:Bool,epicEverything:Bool=false):pr2.lobby.dialogs.Popup {
		#if pr2_mobile_ui
		return new pr2.mobile.MobilePartInfoPopup(type,id,name,description,obtain,owned,epic,epicEverything);
		#elseif pr2_ui_preview
		return isMobile ? new pr2.mobile.MobilePartInfoPopup(type,id,name,description,obtain,owned,epic,epicEverything) : new pr2.lobby.account.PartPopup(type,id,name,description,obtain,owned,epic,epicEverything);
		#else
		return new pr2.lobby.account.PartPopup(type,id,name,description,obtain,owned,epic,epicEverything);
		#end
	}

	public static function changePassword():pr2.lobby.dialogs.Popup {
		#if pr2_mobile_ui
		return new pr2.mobile.MobileCredentialPopup("password");
		#elseif pr2_ui_preview
		return isMobile ? new pr2.mobile.MobileCredentialPopup("password") : new pr2.lobby.dialogs.ChangePasswordPopup();
		#else
		return new pr2.lobby.dialogs.ChangePasswordPopup();
		#end
	}

	public static function setEmail():pr2.lobby.dialogs.Popup {
		#if pr2_mobile_ui
		return new pr2.mobile.MobileCredentialPopup("email");
		#elseif pr2_ui_preview
		return isMobile ? new pr2.mobile.MobileCredentialPopup("email") : new pr2.lobby.dialogs.SetEmailPopup();
		#else
		return new pr2.lobby.dialogs.SetEmailPopup();
		#end
	}

	public static function messages():Page {
		#if pr2_mobile_ui
		return new pr2.mobile.MobileMessagesPage();
		#elseif pr2_ui_preview
		return isMobile ? new pr2.mobile.MobileMessagesPage() : new pr2.lobby.tabs.MessagesTab();
		#else
		return new pr2.lobby.tabs.MessagesTab();
		#end
	}

	public static function players(guilds:Bool = false):Page {
		#if pr2_mobile_ui
		return new pr2.mobile.MobilePlayersPage(guilds);
		#elseif pr2_ui_preview
		if (isMobile) return new pr2.mobile.MobilePlayersPage(guilds);
		return guilds ? new pr2.lobby.players.Guilds() : new pr2.lobby.tabs.PlayersTab();
		#else
		return guilds ? new pr2.lobby.players.Guilds() : new pr2.lobby.tabs.PlayersTab();
		#end
	}

	public static function racer():Page {
		#if pr2_mobile_ui
		return new pr2.mobile.MobileRacerPage();
		#elseif pr2_ui_preview
		return isMobile ? new pr2.mobile.MobileRacerPage() : new pr2.lobby.tabs.AccountTab();
		#else
		return new pr2.lobby.tabs.AccountTab();
		#end
	}

	public static function gameHud(quit:Void->Void, isDone:Void->Bool):pr2.gameplay.GameHud {
		#if pr2_mobile_ui
		return new pr2.mobile.MobileGameHud(quit, isDone);
		#elseif pr2_ui_preview
		return isMobile ? new pr2.mobile.MobileGameHud(quit, isDone) : new pr2.gameplay.ClassicGameHud(quit, isDone);
		#else
		return new pr2.gameplay.ClassicGameHud(quit, isDone);
		#end
	}

	public static function resultAssets(levelId:Int):Null<pr2.gameplay.ResultsAssets> {
		#if pr2_mobile_ui
		return null;
		#elseif pr2_ui_preview
		return isMobile ? null : new pr2.gameplay.FinishedPageAssets(levelId);
		#else
		return new pr2.gameplay.FinishedPageAssets(levelId);
		#end
	}

	public static function prize(type:String,id:Int,name:String,description:String="",universal:Bool=false,finished:Bool=false):pr2.lobby.dialogs.Popup {
		if(activePrize!=null&&!activePrize.isRemoved())activePrize.remove();
		#if pr2_mobile_ui
		activePrize=new pr2.mobile.MobilePrizePopup(type,id,name,description,universal,finished);
		#elseif pr2_ui_preview
		activePrize=isMobile?new pr2.mobile.MobilePrizePopup(type,id,name,description,universal,finished):new pr2.gameplay.PrizePopup(type,id,name,description,universal,finished);
		#else
		activePrize=new pr2.gameplay.PrizePopup(type,id,name,description,universal,finished);
		#end
		return activePrize;
	}

	public static function closePrize():Void {if(activePrize!=null&&!activePrize.isRemoved())activePrize.startFadeOut();activePrize=null;}

	public static function lux(amount:Int):pr2.lobby.dialogs.Popup {
		#if pr2_mobile_ui
		return new pr2.mobile.MobileLuxPopup(amount);
		#elseif pr2_ui_preview
		return isMobile?new pr2.mobile.MobileLuxPopup(amount):new pr2.gameplay.LuxPopup(amount);
		#else
		return new pr2.gameplay.LuxPopup(amount);
		#end
	}

	public static function results(levelId:Int, onReturn:Void->Void, onClose:pr2.gameplay.RaceResults->Void,
		physicsFrames:Int, assets:pr2.gameplay.ResultsAssets, title:String, outcome:String):pr2.gameplay.RaceResults {
		#if pr2_mobile_ui
		return new pr2.mobile.MobileResultsPage(levelId, title, outcome, onReturn, onClose);
		#elseif pr2_ui_preview
		if (isMobile) return new pr2.mobile.MobileResultsPage(levelId, title, outcome, onReturn, onClose);
		return new pr2.gameplay.FinishedPage(levelId, onReturn, function(page) { if (onClose != null) onClose(page); }, physicsFrames, cast assets);
		#else
		return new pr2.gameplay.FinishedPage(levelId, onReturn, function(page) { if (onClose != null) onClose(page); }, physicsFrames, cast assets);
		#end
	}

	public static function authDialog(kind:String, message:String, values:Map<String, String>):pr2.page.auth.AuthDialog {
		#if pr2_mobile_ui
		return new pr2.mobile.MobileAuthDialog(kind, message, values);
		#elseif pr2_ui_preview
		return isMobile ? new pr2.mobile.MobileAuthDialog(kind, message, values) : new pr2.page.auth.ClassicAuthDialog(kind, message, values);
		#else
		return new pr2.page.auth.ClassicAuthDialog(kind, message, values);
		#end
	}
}
