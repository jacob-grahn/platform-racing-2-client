package package_15 {
    import com.jiggmin.data.Data;
    import com.jiggmin.data.HTMLNameMaker;
    import fl.controls.ComboBox;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import levelEditor.LevelEditor;
    import package_4.ConfirmPopup;
    import package_4.HoverPopup;
    import package_4.MessagePopup;
    import package_4.Popup;
    import package_4.UploadingPopup;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;

    public class HandleLevelReportPopup extends Popup {
        private var reportsPop:GetLevelReports;
        private var level:Object;

        private var htmlNM:HTMLNameMaker = new HTMLNameMaker();
        private var uploading:UploadingPopup;
        private var banRet:Object = {};

        private var info:HoverPopup;

        private var m:HandleLevelReportPopupGraphic = new HandleLevelReportPopupGraphic();

        public function HandleLevelReportPopup(reportsPopup:GetLevelReports, level:Object)
        {
            this.reportsPop = reportsPopup;
            this.level = level;
            this.htmlNM.listenForLink(this.m.titleBox);
            this.m.titleBox.htmlText = this.htmlNM.makeLevel(this.level.title, this.level.level_id) + ' by ' + this.htmlNM.makeName(this.level.creator, this.level.creator_group);

            this.m.otherReasonBox.visible = this.m.other_cancel_bt.visible = false;
            this.m.other_cancel_bt.addEventListener(MouseEvent.CLICK, this.checkIfSelectedOther, false, 0, true);
            this.m.reason.addEventListener(Event.CHANGE, this.checkIfSelectedOther, false, 0, true);

            this.m.info_bt.addEventListener(MouseEvent.MOUSE_OVER, this.addInfoHover, false, 0, true);
            this.m.info_bt.addEventListener(MouseEvent.MOUSE_OUT, this.removeInfoHover, false, 0, true);

            this.m.ban_bt.addEventListener(MouseEvent.CLICK, this.clickBan, false, 0, true);
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel, false, 0, true);
            this.m.archive_bt.addEventListener(MouseEvent.CLICK, this.clickArchive, false, 0, true);
            addChild(this.m);
        }

        private function addInfoHover(e:MouseEvent)
        {
            var levelTitle:String = "-- " + Data.escapeString(level.title) + " --";
            var popText:String = "Creator: " + Data.escapeString(level.creator) + "<br/>";
            popText += "Version: " + Data.formatNumber(level.version);
            if (Data.trimWhitespace(level.note) != '') {
                popText += "<br/>Note: <i>" + Data.escapeString(level.note, true) + "</i>";
            }
            popText += "<br/>-----<br/>";
            popText += "Reported: "  + Data.getShortDateStr(level.report_time) + '<br/>';
            popText += "^ By: " + Data.escapeString(level.reporter) + "<br/>";
            popText += "Reason: <i>" + Data.escapeString(level.reason) + "</i>";
            this.info = new HoverPopup(levelTitle, popText, this.m.info_bt);
            this.info.x += this.info.width + 23;
        }

        private function removeInfoHover(e:MouseEvent = null)
        {
            if (this.info) {
                this.info.remove();
                this.info = null;
            }
        }

        private function reopenReportedLevelsPopup(e:Event = null)
        {
            this.uploading.removeEventListener(SuperLoader.d, this.reopenReportedLevelsPopup);
            this.reportsPop.startFadeOut();
            new GetLevelReports();

            if (this.banRet.hasOwnProperty('message')) {
                new MessagePopup(this.banRet.message);
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
            this.uploading = new UploadingPopup(request, 'json', 'Unpublishing and banning...', false);
            this.uploading.addEventListener(SuperLoader.d, this.confirmArchive, false, 0, true);
        }

        private function clickCancel(e:MouseEvent)
        {
            startFadeOut();
        }

        private function clickArchive(e:MouseEvent)
        {
            new ConfirmPopup(this.confirmArchive, 'Are you sure you want to archive this report?');
        }

        private function confirmArchive(e:* = null)
        {
            if (this.uploading != null) {
                this.banRet = this.uploading.parsedData;
                this.uploading.removeEventListener(SuperLoader.d, this.confirmArchive);
                this.uploading = null;
            }

            var vars:URLVariables = new URLVariables();
            vars.level_id = this.level.level_id;
            vars.version = this.level.version;

            var request:URLRequest = new URLRequest(Main.baseURL + "/mod/archive_report.php");
            request.method = URLRequestMethod.POST;
            request.data = vars;
            this.uploading = new UploadingPopup(request, 'json', 'Archiving report...');
            this.uploading.addEventListener(SuperLoader.d, this.reopenReportedLevelsPopup, false, 0, true);
        }

        override public function remove()
        {
            if (this.uploading != null) {
                this.uploading.removeEventListener(SuperLoader.d, this.confirmArchive);
                this.uploading.removeEventListener(SuperLoader.d, this.reopenReportedLevelsPopup);
                this.uploading = null;
            }
            this.removeInfoHover();
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