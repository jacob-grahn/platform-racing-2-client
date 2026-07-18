package pr2.lobby;

import pr2.lobby.tabs.MessagesView;
import pr2.util.TestDisplayUtil as DisplayUtil;

class MessagesViewTest {
	private static var assertions = 0;

	public static function main():Void {
		var view = new MessagesView();
		var background = DisplayUtil.findByName(view, "background");
		assertClose(174 * 1.01148986816406, background.width, "messages background keeps XFL width");
		if (pr2.DeterministicTestMode.finishSmokeSuite("MessagesViewTest")) return;
		assertClose(350 * 0.971389770507812, background.height, "messages background keeps XFL height before footer controls");
		var holder = DisplayUtil.findByName(view, "var_295");
		assertClose(0, holder.x, "messages holder keeps XFL X");
		assertClose(0, holder.y, "messages holder keeps XFL Y");
		var deleteAll = DisplayUtil.findByName(view, "deleteAll_bt");
		assertClose(4, deleteAll.x, "delete-all keeps XFL X");
		assertClose(346, deleteAll.y, "delete-all keeps XFL Y");
		assertClose(100 * 0.699996948242188, deleteAll.width, "delete-all keeps XFL width");
		var send = DisplayUtil.findByName(view, "sendMessage_bt");
		assertClose(81, send.x, "send-message keeps XFL X");
		assertClose(346, send.y, "send-message keeps XFL Y");
		assertClose(100, send.width, "send-message keeps XFL width");
		view.dispose();
		trace('MessagesViewTest passed $assertions assertions');
	}

	private static function assertClose(expected:Float, actual:Float, message:String):Void {
		assertions++;
		if (Math.abs(expected - actual) > 0.000001) throw '$message: expected $expected, got $actual';
	}
}
