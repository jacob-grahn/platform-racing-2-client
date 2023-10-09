package package_15 {
    import com.jiggmin.data.Data;
    import com.jiggmin.data.HTMLNameMaker;
    import fl.controls.ComboBox;
    import flash.events.MouseEvent;
    import levelEditor.LevelEditor;
    import package_4.Popup;
    import flash.events.Event;
    import package_4.ConfirmPopup;
    import package_4.MessagePopup;
    import package_4.UploadingPopup;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;

    public class HandleLevelReportPopup extends Popup {
        private var reportsPop:GetLevelReports;
        private var level:Object;

        private var htmlNM:HTMLNameMaker = new HTMLNameMaker();
        private var uploading:UploadingPopup;

        private var m:HandleLevelReportPopupGraphic = new HandleLevelReportPopupGraphic();

        public function HandleLevelReportPopup(reportsPopup:GetLevelReports, level:Object)
        {
            this.reportsPop = reportsPopup;
            this.level = level;
            this.htmlNM.listenForLink(this.m.titleBox);
            this.m.titleBox.htmlText = this.htmlNM.makeLevel(this.level.title, this.level.level_id) + ' by ' + this.htmlNM.makeName(this.level.creator, this.level.creator_group);
            this.m.reportReasonBox.text = 'Report reason: ' + this.level.reason;

            this.m.otherReasonBox.visible = this.m.other_cancel_bt.visible = false;
            this.m.other_cancel_bt.addEventListener(MouseEvent.CLICK, this.checkIfSelectedOther, false, 0, true);
            this.m.reason.addEventListener(Event.CHANGE, this.checkIfSelectedOther, false, 0, true);

            this.m.ban_bt.addEventListener(MouseEvent.CLICK, this.clickBan, false, 0, true);
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel, false, 0, true);
            this.m.archive_bt.addEventListener(MouseEvent.CLICK, this.clickArchive, false, 0, true);
            addChild(this.m);
        }

        private function reopenReportedLevelsPopup(e:Event = null)
        {
            this.uploading.removeEventListener(SuperLoader.d, this.reopenReportedLevelsPopup);
            this.uploading.removeEventListener(SuperLoader.e, this.reopenReportedLevelsPopup);
            this.reportsPop.startFadeOut();
            new GetLevelReports();

            var ret:Object = SuperLoader(e.target).parsedData;
            if (message != '') {
                new MessagePopup(ret.message);
            }
            startFadeOut();
        }

        private function checkIfSelectedOther(selectedOther:*)
        {
            if (selectedOther is MouseEvent) { // clicked other cancel bt
                selectedOther = false;
            } else if (selectedOther is Event) { // combobox changed
                if (this.m.reason.selectedIndex < this.m.reason.length - 1) {
                    return;
                }
                selectedOther = true;
            }

            this.m.reason.selectedItem = this.m.reason.getItemAt(0);
            this.m.reason.visible = !selectedOther;
            this.m.otherReasonBox.visible = this.m.other_cancel_bt.visible = selectedOther;
        }

        private function clickBan(e:MouseEvent)
        {
            var reason:String = this.m.reason.selectedIndex == 0 || this.m.reason.selectedIndex == this.m.reason.length - 1 ? this.m.otherReasonBox.text : this.m.reason.selectedItem.data;
            if (reason == '') {
                return new MessagePopup('Error: You must enter a reason for the ban.');
            }

            var duration:int = this.m.duration.selectedItem.data;
            if (duration == 0) {
                return new MessagePopup("Error: You must specify a ban length.");
            }

            var safeCreator:String = Data.escapeString(this.level.creator);
            new ConfirmPopup(this.banUser, 'Are you sure you want to socially ban ' + safeCreator + '? This will also unpublish the reported level.');
        }

        private function banUser()
        {
            var vars:URLVariables = new URLVariables();
            vars.level_id = this.level.level_id;
            vars.banned_name = this.level.creator;
            vars.duration = int(this.m.duration.selectedItem.data);
            vars.reason = 'Inappropriate Level -- ' + (this.m.reason.selectedIndex == 0 || this.m.reason.selectedIndex == this.m.reason.length - 1 ? this.m.otherReasonBox.text : this.m.reason.selectedItem.data);
            vars.scope = 'social';
            vars.record = 'Level ID: ' + this.level.level_id + '\nTitle: ' + Data.escapeString(this.level.title) + '\nNote: ' + Data.escapeString(this.level.note) + '\nVersion: ' + this.level.version;

            var request:URLRequest = new URLRequest(Main.baseURL + "/ban_user.php");
            request.data = vars;
            request.method = URLRequestMethod.POST;
            this.uploading = new UploadingPopup(request, 'json', false);
            this.uploading.addEventListener(SuperLoader.d, this.reopenReportedLevelsPopup, false, 0, true);
        }

        private function clickCancel(e:MouseEvent)
        {
            startFadeOut();
        }

        private function clickArchive(e:MouseEvent)
        {
            new ConfirmPopup(this.confirmArchive, 'Are you sure you want to archive this report?');
        }

        private function confirmArchive()
        {
            var vars:URLVariables = new URLVariables();
            vars.level_id = this.level.level_id;
            vars.version = this.level.version;

            var request:URLRequest = new URLRequest(Main.baseURL + "/mod/archive_report.php");
            request.method = URLRequestMethod.POST;
            request.data = vars;
            this.uploading = new UploadingPopup(request, 'json');
            this.uploading.addEventListener(SuperLoader.d, this.reopenReportedLevelsPopup, false, 0, true);
        }

        override public function remove()
        {
            this.m.reason.removeEventListener(Event.CHANGE, this.checkIfSelectedOther);
            this.m.other_cancel_bt.removeEventListener(MouseEvent.CLICK, this.checkIfSelectedOther);
            this.m.ban_bt.removeEventListener(MouseEvent.CLICK, this.clickBan);
            this.m.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
            this.m.archive_bt.removeEventListener(MouseEvent.CLICK, this.clickArchive);
            this.htmlNM.remove();
            super.remove();
        }
    }
}