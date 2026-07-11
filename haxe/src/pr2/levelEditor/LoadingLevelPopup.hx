package pr2.levelEditor;

import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.dialogs.ProgressBar;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.net.LevelDataClient;
import pr2.net.ServerLevelData;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;
import pr2.levelEditor.EditorPersistenceTypes.LoadingLevelFetchFactory;

class LoadingLevelPopup extends Popup {
	public static var fetchFactory:LoadingLevelFetchFactory = defaultFetch;

	public var art(default, null):Null<PR2MovieClip>;
	public final levelId:Int;
	public final version:Int;
	public final report:Bool;
	private var closeBinding:Null<Binding>;
	private var progressBar:Null<ProgressBar>;

	public function new(levelId:Int, version:Int, report:Bool = false) {
		super();
		this.levelId = levelId;
		this.version = version;
		this.report = report;
		art = PR2MovieClip.fromLinkage("UploadingPopupGraphic", {maxNestedDepth: 4});
		var textBox = LobbyArt.text(art, "textBox");
		if (textBox != null) {
			textBox.text = "Loading level...";
		}
		addChild(art);
		progressBar = new ProgressBar();
		progressBar.x = -100;
		progressBar.y = -5;
		addChild(progressBar);
		closeBinding = LobbyArt.bind(DisplayUtil.findByName(art, "close_bt"), function():Void startFadeOut());
		fetchFactory(levelId, version, handleLoad, handleError);
	}

	private function handleLoad(data:ServerLevelData):Void {
		if (progressBar != null) {
			progressBar.setProgress(1);
		}
		if (LevelEditor.editor != null) {
			LevelEditor.editor.applyLoadedLevelData(data, report);
		}
		startFadeOut();
	}

	private function handleError(message:String):Void {
		if (progressBar != null) {
			progressBar.setProgress(1);
		}
		if (message != null && message != "") {
			new MessagePopup(formatLoadError(message));
		}
		startFadeOut();
	}

	private static function formatLoadError(message:String):String {
		return StringTools.startsWith(message, "Error: ") ? message : "Error: " + message;
	}

	public static function defaultFetch(levelId:Int, version:Int, onResult:ServerLevelData->Void, onError:String->Void):Void {
		LevelDataClient.fetchEditorLoad(levelId, version, onResult, onError);
	}

	override public function remove():Void {
		LobbyArt.unbind(closeBinding);
		closeBinding = null;
		if (progressBar != null) {
			progressBar.remove();
			progressBar = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
