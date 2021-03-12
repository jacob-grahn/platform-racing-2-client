// package_15.LoadingLevelPopup = package_15.class_233

package package_15
{
    import com.adobe.crypto.MD5;
    import flash.events.Event;
    import flash.net.URLRequest;
    import flash.net.URLVariables;
    import levelEditor.LevelEditor;
    import package_4.MessagePopup;
    import package_4.UploadingPopup;

    public class LoadingLevelPopup extends UploadingPopup 
    {

        private var levelID:int;
        private var version:int;
        private var report:Boolean = false;

        public function LoadingLevelPopup(id:int, v:int, report:Boolean = false)
        {
            this.levelID = id;
            this.version = v;
            this.report = report;
            m.textBox.text = "Loading...";
            var request:URLRequest = new URLRequest(Main.levelsURL + "/" + this.levelID + ".txt?version=" + this.version);
            loader.useRandomNum = false;
            loader = new SuperLoader();
            loader.addEventListener(SuperLoader.d, onComplete, false, 0, true);
            loader.addEventListener(SuperLoader.e, errorHandler, false, 0, true);
            loader.load(request);
        }

        // _loc2 = levelTxt
        // _loc3 = hashPos
        // _loc4 = levelHash
        // _loc5 = levelData
        // _loc7 = gameHash
        // _loc8 = LE
        // _loc9 = LEVars
        override protected function onComplete(e:Event)
        {
            var levelTxt:String = e.target.data;
            var hashPos:int = levelTxt.length - 32;
            var levelHash:String = levelTxt.substr(hashPos);
            var levelData:String = levelTxt.substr(0, hashPos);
            var gameHash:String = MD5.hash(this.version.toString() + this.levelID.toString() + levelData + Env.LEVEL_SALT_2);
            if (gameHash != levelHash) {
                new MessagePopup("Error: The course did not download correctly.");
            } else if (levelData == "") {
                new MessagePopup("Error: The course did not load.");
            } else {
                var LE:LevelEditor = LevelEditor.editor;
                levelData = LE.method_158(levelData);
                var LEVars:URLVariables = new URLVariables(levelData);
                LE.setVariables(LEVars);
            }
            super.onComplete(e);
            super.parsedDataHandler(e);
            LevelEditor.editor.menu.setReportsMode(this.report);
        }

        override public function remove()
        {
            super.remove();
        }


    }
}
