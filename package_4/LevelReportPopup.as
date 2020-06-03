package package_4
{
    import data.class_28;
    import flash.events.MouseEvent;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;

    public class LevelReportPopup extends Popup 
    {

        private var levelId:int = 0;
        private var version:int = 0;
        private var uploading:UploadingPopup;
        private var m:LevelReportPopupGraphic = new LevelReportPopupGraphic();

        public function LevelReportPopup(levelId:int = 0, version:int = 0)
        {
            this.levelId = levelId;
            this.version = version;
            this.m.report_bt.addEventListener(MouseEvent.CLICK, this.clickReport);
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel);
            addChild(this.m);
        }

        private function clickReport(e:MouseEvent)
        {
            if (this.m.reasonBox.text == null || class_28.trimWhitespace(this.m.reasonBox.text) == '') {
                new MessagePopup('Error: Oops, you forgot to write the reason for your report!');
                return;
            }
            new ConfirmPopup(this.confirmReport, "Are you sure you want to report this level to the moderators? If it contains something inappropriate or mean, then please do report this level.");
        }

        private function confirmReport()
        {
            if (LevelInfoPopup.instance != null) {
                LevelInfoPopup.instance.startFadeOut();
            }
            var vars:URLVariables = new URLVariables();
            vars.level_id = this.levelId;
            vars.version = this.version;
            vars.reason = this.m.reasonBox.text;
            var request:URLRequest = new URLRequest(Main.baseURL + "/level_report.php");
            request.method = URLRequestMethod.POST;
            request.data = vars;
            this.uploading = new UploadingPopup(request, 'json');
            startFadeOut();
        }

        private function clickCancel(e:MouseEvent)
        {
            startFadeOut();
        }

        override public function remove()
        {
            this.m.report_bt.removeEventListener(MouseEvent.CLICK, this.clickReport);
            this.m.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
            if (this.uploading != null) {
                this.uploading.remove();
                this.uploading = null;
            }
            super.remove();
        }


    }
}
