package package_4 {
    import flash.events.MouseEvent;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;

    public class ChooseLevelModModePopup extends Popup {
        private var levelId:int;
        private var uploading:UploadingPopup;
        private var m:ChooseLevelModModePopupGraphic = new ChooseLevelModModePopupGraphic();

        public function ChooseLevelModModePopup(levelId:int)
        {
            this.levelId = levelId;
            this.m.unpublish_bt.addEventListener(MouseEvent.CLICK, this.clickUnpublish, false, 0, true);
            this.m.restrict_bt.addEventListener(MouseEvent.CLICK, this.clickRestrict, false, 0, true);
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel, false, 0, true);
            addChild(this.m);
        }

        private function clickUnpublish(e:MouseEvent)
        {
            new ConfirmPopup(function () {
                confirmAction('unpublish');
            }, "Are you sure you want to unpublish this level? The author will need to re-publish it from their account.");
        }

        private function clickRestrict(e:MouseEvent)
        {
            new ConfirmPopup(function () {
                confirmAction('restrict');
            }, "Are you sure you want to restrict this level? The level will remain playable but will not appear in any level lists except Search and Favorites.");
        }

        private function confirmAction(action:String = 'unpublish')
        {
            var vars:URLVariables = new URLVariables();
            vars.level_id = this.levelId;
            vars.action = action;
            var request:URLRequest = new URLRequest(Main.baseURL + "/level_moderate.php");
            request.method = URLRequestMethod.POST;
            request.data = vars;
            this.uploading = new UploadingPopup(request, 'json', action == 'restrict' ? 'Restricting level...' : 'Unpublishing level...');
            this.uploading.addEventListener(SuperLoader.d, this.returnAction, false, 0, true);
        }

        private function returnAction(e:*)
        {
            if (this.uploading.parsedData.success === true) {
                if (LevelInfoPopup.instance != null) {
                    LevelInfoPopup.instance.startFadeOut();
                }
                startFadeOut();
            }
        }

        private function clickCancel(e:MouseEvent)
        {
            startFadeOut();
        }

        override public function remove()
        {
            if (this.uploading != null) {
                this.uploading.removeEventListener(SuperLoader.d, this.returnAction);
                this.uploading.startFadeOut();
                this.uploading = null;
            }
            this.m.unpublish_bt.removeEventListener(MouseEvent.CLICK, this.clickUnpublish);
            this.m.restrict_bt.removeEventListener(MouseEvent.CLICK, this.clickRestrict);
            this.m.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
            super.remove();
        }
    }
}