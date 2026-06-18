package pr2.lobby.messages;

import openfl.display.DisplayObjectContainer;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `com.jiggmin.data.UnreadNotif`: the small unread-PM badge that
	rides on the PMs tab. New messages arriving over the socket (`pmNotify`) push
	their timestamp; the badge shows while any are newer than the last-read time,
	and opening the PMs tab clears it via `updateLastRead`.
**/
class UnreadNotif {
	private static var lastReadTime:Float = 0;
	private static var unreadMessages:Array<Float> = [];
	private static var notificationIcon:Null<PR2MovieClip> = null;
	private static var pmTab:Null<DisplayObjectContainer> = null;

	private function new() {}

	public static function setLastRead(time:Float):Void {
		lastReadTime = time;
	}

	public static function notifyUser(time:Float):Void {
		if (time > lastReadTime) {
			unreadMessages.push(time);
		}
		addNotif();
	}

	public static function updateLastRead():Void {
		for (timeSent in unreadMessages) {
			if (timeSent > lastReadTime) {
				lastReadTime = timeSent;
			}
		}
		unreadMessages = [];
		removeNotif();
	}

	public static function addNotifContainer(d:DisplayObjectContainer):Void {
		pmTab = d;
		if (numUnread() > 0) {
			addNotif();
		}
	}

	private static function icon():PR2MovieClip {
		if (notificationIcon == null) {
			notificationIcon = PR2MovieClip.fromLinkage("UnreadNotifGraphic", {maxNestedDepth: 2});
		}
		return notificationIcon;
	}

	private static function addNotif():Void {
		if (pmTab != null) {
			var ic = icon();
			ic.x = 26;
			ic.y = 0;
			pmTab.addChild(ic);
		}
	}

	private static function removeNotif():Void {
		if (notificationIcon != null && notificationIcon.parent != null) {
			notificationIcon.parent.removeChild(notificationIcon);
		}
	}

	public static function numUnread():Int {
		return unreadMessages.length;
	}

	public static function reset():Void {
		lastReadTime = 0;
		unreadMessages = [];
		removeNotif();
		pmTab = null;
	}
}
