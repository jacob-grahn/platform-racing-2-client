// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_15.UploadingLevelPopup = package_15.class_235

package package_15
{
    import com.hurlant.crypto.hash.MD5;
    import com.hurlant.util.Hex;
    import data.class_28;
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

        private var overrideBanConfirmed:Boolean = false;
        private var overwriteExistingConfirmed:Boolean = false;

        public function UploadingLevelPopup(overrideBan:Boolean = false, overwriteExisting:Boolean = false)
        {
            this.overrideBanConfirmed = overrideBan;
            this.overwriteExistingConfirmed = overwriteExisting;
            this.uploadLevel();
        }

        // _loc1 = md5
        // _loc2 = lVars
        // _loc3 = unhashedStr
        // _loc4 = byteHash
        // deleted _loc5 (put on the same line as lVars.hash)
        // _loc6 = request
        // method_240 = uploadLevel
        private function uploadLevel()
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
                    lVars.override_banned = int(this.overrideBanConfirmed); // if banned
                    lVars.overwrite_existing = int(this.overwriteExistingConfirmed); // if overwriting an existing level
                    var request:URLRequest = new URLRequest(Main.baseURL + "/upload_level.php");
                    request.method = URLRequestMethod.POST;
                    request.data = lVars;
                    loader = new SuperLoader();
                    loader.addEventListener(SuperLoader.d, this.onParse, false, 0, true);
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
            if (parsedData.status == 'banned') {
                var banLang:String = parsedData.scope === 's' ? 'socially ' : '';
                new ConfirmPopup(this.overrideBanConfirmUploadLevel, "You are currently " + class_28.urlify(Main.baseURL + '/bans/show_record.php?ban_id=' + parsedData.ban_id, banLang + 'banned') + ". You can still save this level, but it won't be published. If this level is already published, continuing will unpublish it.<br /><br />Do you want to proceed?");
            } else if (parsedData.status == 'exists') {
                new ConfirmPopup(this.overwriteConfirmUploadLevel, "You have another level with this title. Is it okay to overwrite the existing level with this save?");
            }
        }

        private function overrideBanConfirmUploadLevel()
        {
            this.overrideBanConfirmed = true;
            new UploadingLevelPopup(this.overrideBanConfirmed, this.overwriteExistingConfirmed);
        }

        private function overwriteConfirmUploadLevel()
        {
            this.overwriteExistingConfirmed = true;
            new UploadingLevelPopup(this.overrideBanConfirmed, this.overwriteExistingConfirmed);
        }

        override public function remove()
        {
            clearTimeout(this.waitTimeout);
            super.remove();
        }


    }
}
