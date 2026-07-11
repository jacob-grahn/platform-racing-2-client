package pr2.levelEditor;

import haxe.Timer;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.dialogs.UploadingPopup;
import pr2.net.ServerLevelData;

typedef SaveLevelUploadFactory = LevelEditor->Null<Popup>;
typedef GetLevelsPostFactory = String->Map<String, String>->(Dynamic->Void)->(String->Void)->Void;
typedef GetLevelsLoadFactory = Int->Int->Void;
typedef LoadingLevelFetchFactory = Int->Int->(ServerLevelData->Void)->(String->Void)->Void;
typedef UploadingLevelPostFactory = String->Map<String, String>->String->(Dynamic->Void)->(String->Void)->Null<UploadingPopup>;
typedef UploadingLevelRetryFactory = (Void->Void)->Int->Null<Timer>;
typedef DeleteLevelPostFactory = String->Map<String, String>->String->(Dynamic->Void)->(String->Void)->Null<UploadingPopup>;
typedef HandleLevelReportUploadFactory = String->Map<String, String>->String->(Dynamic->Void)->(String->Void)->Null<UploadingPopup>;
typedef HandleLevelReportReopenFactory = Void->Void;
