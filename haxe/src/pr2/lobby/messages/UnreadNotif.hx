package pr2.lobby.messages;

import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;

/**
	Port of Flash `com.jiggmin.data.UnreadNotif`: the small unread-PM badge that
	rides on the PMs tab. New messages arriving over the socket (`pmNotify`) push
	their timestamp; the badge shows while any are newer than the last-read time,
	and opening the PMs tab clears it via `updateLastRead`.
**/
class UnreadNotif {
	private static var lastReadTime:Float = 0;
	private static var unreadMessages:Array<Float> = [];
	private static var notificationIcon:Null<Sprite> = null;
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

	public static function removeNotifContainer(d:DisplayObjectContainer):Void {
		if (pmTab == d) {
			removeNotif();
			pmTab = null;
		}
	}

	public static function containerForTests():Null<DisplayObjectContainer> {
		return pmTab;
	}

	public static function hasNotificationForTests():Bool {
		return notificationIcon != null && notificationIcon.parent != null;
	}

	private static function icon():Sprite {
		if (notificationIcon == null) {
			var holder = new Sprite();
			var art = NativeAssets.svg(StaticSvg.UnreadNotification);
			art.x = 3.3;
			art.y = 3.15;
			holder.addChild(art);
			notificationIcon = holder;
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
