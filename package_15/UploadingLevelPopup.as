// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_15.UploadingLevelPopup = package_15.class_235

package package_15
{
    import com.hurlant.crypto.hash.MD5;
    import com.hurlant.util.Hex;
	import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.utils.ByteArray;
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;
    import levelEditor.LevelEditor;
    import package_4.ConfirmPopup;
    import package_4.MessagePopup;
    import package_4.UploadingPopup;

    public class UploadingLevelPopup extends UploadingPopup 
    {

        private var editor:LevelEditor = LevelEditor.editor;
        private var waitTimeout:uint;

        public function UploadingLevelPopup(overwriteExisting = false)
        {
            this.uploadLevel(overwriteExisting);
        }

        // _loc1 = md5
        // _loc2 = lVars
        // _loc3 = unhashedStr
        // _loc4 = byteHash
        // deleted _loc5 (put on the same line as lVars.hash)
        // _loc6 = request
        // method_240 = uploadLevel
        private function uploadLevel(overwriteExisting = false)
        {
            if (!this.editor.drawing) {
                var md5:MD5 = new MD5();
                var lVars:URLVariables = this.editor.method_344();
                if (lVars.data == "" || lVars.data == null) {
                    new MessagePopup("The client is glitching out. Could not save your level.");
                } else {
                    var unhashedStr:String = lVars.title + Main.loggedInAs.toLowerCase() + lVars.data + Env.LEVEL_SALT;
                    var byteHash:ByteArray = md5.hash(Hex.toArray(Hex.fromString(unhashedStr)));
                    lVars.hash = Hex.fromArray(byteHash);
                    if (overwriteExisting) {
                        lVars.overwrite_existing = '1';
                    }
                    var request:URLRequest = new URLRequest(Main.baseURL + "/upload_level.php");
                    request.method = URLRequestMethod.POST;
                    request.data = lVars;
                    loader = new SuperLoader();
                    loader.addEventListener(SuperLoader.d, this.onParse);
                    loader.load(request);
                }
            } else {
                clearTimeout(this.waitTimeout);
                this.waitTimeout = setTimeout(this.uploadLevel, 1000);
            }
        }

        private function onParse(e:Event)
        {
            super.parsedDataHandler(e);
            if (parsedData.status == 'exists') {
                new ConfirmPopup(overwriteConfirmUploadLevel, "You have another level with this title. Is it okay to overwrite the existing level with this save?");
            }
        }

        private function overwriteConfirmUploadLevel()
        {
            new UploadingLevelPopup(true);
        }

        override public function remove()
        {
            clearTimeout(this.waitTimeout);
            super.remove();
        }


    }
}
