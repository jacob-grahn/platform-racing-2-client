// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_4.BanMenu = package_4.class_191

package package_4
{
    import data.class_28;
    import flash.events.MouseEvent;
    import package_21.ChatInstance;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.events.Event;

    public class BanMenu extends class_7 
    {

        private var m:BanMenuGraphic = new BanMenuGraphic();
        private var target:Popup;
        private var userName:String;
        private var banSecs:int; // var_488
        //private var minSecs:int = 60; // var_539
        private var hourSecs:int = 3600; // var_501
        private var daySecs:int = 86400; // var_440
        private var weekSecs:int = 604800; // var_475
        private var monthSecs:int = 2592000; // var_343
        private var yearSecs:int = 31536000; // var_605
        private var eternSecs:int = 145152000; // var_647
        private var uploading:UploadingPopup;

        public function BanMenu(name:String, playerPopup:Popup)
        {
            this.userName = name;
            this.target = playerPopup;
            //this.m.banMinuteButton.addEventListener(MouseEvent.CLICK, this.banMinute, false, 0, true); 
            this.m.banHourButton.addEventListener(MouseEvent.CLICK, this.banHour, false, 0, true);
            this.m.banDayButton.addEventListener(MouseEvent.CLICK, this.banDay, false, 0, true);
            if (Main.isTrialMod == false) {
                this.m.banWeekButton.addEventListener(MouseEvent.CLICK, this.banWeek, false, 0, true);
                this.m.banMonthButton.addEventListener(MouseEvent.CLICK, this.banMonth, false, 0, true);
                this.m.banYearButton.addEventListener(MouseEvent.CLICK, this.banYear, false, 0, true);
            } else {
                this.m.banWeekButton.enabled = this.m.banMonthButton.enabled = this.m.banYearButton.enabled = false;
            }
            this.m.warning1Button.addEventListener(MouseEvent.CLICK, this.clickWarning1, false, 0, true);
            this.m.warning2Button.addEventListener(MouseEvent.CLICK, this.clickWarning2, false, 0, true);
            this.m.warning3Button.addEventListener(MouseEvent.CLICK, this.clickWarning3, false, 0, true);
            this.m.kickButton.addEventListener(MouseEvent.CLICK, this.clickKick, false, 0, true);
            addChild(this.m);
        }

        // method_388 = banMinute
        /*private function banMinute(e:MouseEvent)
        {
            this.confirmBan(this.minSecs);
        }*/

        // method_468 = banHour
        private function banHour(e:MouseEvent)
        {
            this.confirmBan(this.hourSecs);
        }

        // method_445 = banDay
        private function banDay(e:MouseEvent)
        {
            this.confirmBan(this.daySecs);
        }

        // method_286 = banWeek
        private function banWeek(e:MouseEvent)
        {
            this.confirmBan(this.weekSecs);
        }

        // method_235 = banMonth
        private function banMonth(e:MouseEvent)
        {
            this.confirmBan(this.monthSecs);
        }

        // method_365 = banYear
        private function banYear(e:MouseEvent)
        {
            this.confirmBan(this.yearSecs);
        }

        // method_60 = confirmBan
        private function confirmBan(secs:int)
        {
            this.banSecs = secs;
            new ConfirmPopup(this.banUser, "Are you sure you want to ban " + class_28.escapeString(this.userName) + "?");
        }

        // chatRecord = _loc1
        // vars = _loc2
        // request = _loc3
        // method_797 = banUser
        public function banUser()
        {
            Main.socket.write("ban`" + this.userName + "`" + this.banSecs + "`" + this.m.reasonBox.text);
            var chatRecord:String = "";
            if (ChatInstance.instance != null) {
                chatRecord = ChatInstance.instance.getChatRecord();
            }
            var vars:URLVariables = new URLVariables();
            vars.banned_name = this.userName;
            vars.duration = this.banSecs;
            vars.reason = this.m.reasonBox.text;
            vars.record = chatRecord;
            var request:URLRequest = new URLRequest(Main.baseURL + "/ban_user.php");
            request.data = vars;
            request.method = URLRequestMethod.POST;
            this.uploading = new UploadingPopup(request, 'json');
            this.uploading.addEventListener(Event.COMPLETE, this.method_238, false, 0, true);
        }

        private function method_238(e:Event)
        {
            this.target.startFadeOut();
        }

        private function clickWarning1(e:MouseEvent)
        {
            this.warnUser(1);
        }

        private function clickWarning2(e:MouseEvent)
        {
            this.warnUser(2);
        }

        private function clickWarning3(e:MouseEvent)
        {
            this.warnUser(3);
        }

        // method_145 = warnUser
        private function warnUser(warnLevel:int)
        {
            Main.socket.write("warn`" + this.userName + "`" + warnLevel);
            this.target.startFadeOut();
        }

        private function clickKick(e:MouseEvent)
        {
            new ConfirmPopup(this.kickUser, "Are you sure you want to kick " + class_28.escapeString(this.userName) + "?");
        }

        public function kickUser()
        {
            Main.socket.write("kick`" + this.userName);
            this.target.startFadeOut();
        }

        override public function remove()
        {
            //this.m.banMinuteButton.removeEventListener(MouseEvent.CLICK, this.banMinute);
            this.m.banHourButton.removeEventListener(MouseEvent.CLICK, this.banHour);
            this.m.banDayButton.removeEventListener(MouseEvent.CLICK, this.banDay);
            this.m.banWeekButton.removeEventListener(MouseEvent.CLICK, this.banWeek);
            this.m.banMonthButton.removeEventListener(MouseEvent.CLICK, this.banMonth);
            this.m.banYearButton.removeEventListener(MouseEvent.CLICK, this.banYear);
            this.m.warning1Button.removeEventListener(MouseEvent.CLICK, this.clickWarning1);
            this.m.warning2Button.removeEventListener(MouseEvent.CLICK, this.clickWarning2);
            this.m.warning3Button.removeEventListener(MouseEvent.CLICK, this.clickWarning3);
            this.m.kickButton.removeEventListener(MouseEvent.CLICK, this.clickKick);
            this.target = null;
            if (this.uploading != null) {
                this.uploading.removeEventListener(Event.COMPLETE, this.method_238);
                this.uploading = null;
            }
            super.remove();
        }


    }
}
