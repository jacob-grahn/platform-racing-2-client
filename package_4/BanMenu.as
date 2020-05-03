// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_4.BanMenu = package_4.class_191

package package_4
{
    import data.class_28;
    import data.Memory;
    import flash.events.MouseEvent;
    import package_21.ChatInstance;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.events.Event;

    public class BanMenu extends Removable 
    {

        private var m:BanMenuGraphic = new BanMenuGraphic();
        private var target:Popup;
        private var userName:String;
        private var banSecs:int; // var_488
        /*private var minSecs:int = 60; // var_539
        private var hourSecs:int = 3600; // var_501
        private var daySecs:int = 86400; // var_440
        private var weekSecs:int = 604800; // var_475
        private var monthSecs:int = 2592000; // var_343
        private var yearSecs:int = 31536000; // var_605
        private var eternSecs:int = 145152000; // var_647*/
        private var uploading:UploadingPopup;

        public function BanMenu(name:String, playerPopup:Popup)
        {
            this.userName = name;
            this.target = playerPopup;
            //this.m.banMinuteButton.addEventListener(MouseEvent.CLICK, this.banMinute, false, 0, true);
            //this.m.banHourButton.addEventListener(MouseEvent.CLICK, this.banHour, false, 0, true);
            //this.m.banDayButton.addEventListener(MouseEvent.CLICK, this.banDay, false, 0, true);
            /*if (Main.isTrialMod == false) {
                this.m.banWeekButton.addEventListener(MouseEvent.CLICK, this.banWeek, false, 0, true);
                this.m.banMonthButton.addEventListener(MouseEvent.CLICK, this.banMonth, false, 0, true);
                this.m.banYearButton.addEventListener(MouseEvent.CLICK, this.banYear, false, 0, true);
            } else {
                this.m.banWeekButton.enabled = this.m.banMonthButton.enabled = this.m.banYearButton.enabled = false;
            }*/
            if (Main.isTrialMod == false) {
                this.m.duration.addItem({"label":"One Week", "data":604800});
                this.m.duration.addItem({"label":"One Month", "data":2592000});
                this.m.duration.addItem({"label":"One Year", "data":31536000});
                this.m.scope.addItemAt({"label":"Game", "data":"game"}, 0);
                this.m.scope.enabled = true;
            }
            this.m.warning1Button.addEventListener(MouseEvent.CLICK, this.clickWarning1, false, 0, true);
            this.m.warning2Button.addEventListener(MouseEvent.CLICK, this.clickWarning2, false, 0, true);
            this.m.warning3Button.addEventListener(MouseEvent.CLICK, this.clickWarning3, false, 0, true);
            this.m.kickButton.addEventListener(MouseEvent.CLICK, this.clickKick, false, 0, true);
            this.m.banButton.addEventListener(MouseEvent.CLICK, this.confirmBan, false, 0, true);
            this.m.viewPriorsButton.addEventListener(MouseEvent.CLICK, this.viewPriors, false, 0, true);
            addChild(this.m);
        }

        private function viewPriors(e:MouseEvent)
        {
            Main.socket.write('view_priors`' + this.userName);
        }

        /*
        // method_388 = banMinute
        private function banMinute(e:MouseEvent)
        {
            this.confirmBan(this.minSecs);
        }

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
        }*/

        // method_60 = confirmBan
        private function confirmBan(e:MouseEvent)
        {
            this.banSecs = this.m.duration.selectedItem.data;
            if (this.banSecs == 0) {
                new MessagePopup("Error: You must specify a ban length.");
                return;
            }
            var scope:String = this.m.scope.selectedItem.data === 'game' ? 'ban' : 'socially ban';
            var msg:String = "Are you sure you want to " + scope + " " + class_28.escapeString(this.userName) + "?";
            if (this.m.scope.selectedItem.data === 'game') {
                msg += " They won't be able to log onto PR2 or use any of the pages on pr2hub.com.";
            } else {
                msg += " They won't be able to register new accounts, use guest accounts, or use any messaging, contest, or guild-related features. They also won't be able to publish or rate levels.";
            }
            new ConfirmPopup(this.banUser, msg);
        }

        // chatRecord = _loc1
        // vars = _loc2
        // request = _loc3
        // method_797 = banUser
        public function banUser()
        {
            Main.socket.write("ban`" + this.userName + "`" + this.banSecs + "`" + this.m.scope.selectedItem.data + "`" + this.m.reason.text);
            var chatRecord:String = "";
            if (ChatInstance.instance != null) {
                chatRecord = ChatInstance.instance.getChatRecord();
            }
            var vars:URLVariables = new URLVariables();
            vars.banned_name = this.userName;
            vars.duration = this.banSecs;
            vars.reason = this.m.reason.text;
            vars.type = this.m.type.selectedItem.data;
            vars.scope = this.m.scope.selectedItem.data;
            if (Memory.memory.chatRoom !== 'mod' && Memory.memory.chatRoom !== 'admin') {
                vars.record = chatRecord;
            }
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
            new ConfirmPopup(this.kickUser, "Are you sure you want to kick " + class_28.escapeString(this.userName) + "? They will not be able to re-enter this server for 30 minutes.");
        }

        public function kickUser()
        {
            Main.socket.write("kick`" + this.userName);
            this.target.startFadeOut();
        }

        override public function remove()
        {
            /*this.m.banMinuteButton.removeEventListener(MouseEvent.CLICK, this.banMinute);
            this.m.banHourButton.removeEventListener(MouseEvent.CLICK, this.banHour);
            this.m.banDayButton.removeEventListener(MouseEvent.CLICK, this.banDay);
            this.m.banWeekButton.removeEventListener(MouseEvent.CLICK, this.banWeek);
            this.m.banMonthButton.removeEventListener(MouseEvent.CLICK, this.banMonth);
            this.m.banYearButton.removeEventListener(MouseEvent.CLICK, this.banYear);*/
            this.m.viewPriorsButton.removeEventListener(MouseEvent.CLICK, this.viewPriors);
            this.m.banButton.removeEventListener(MouseEvent.CLICK, this.confirmBan);
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
