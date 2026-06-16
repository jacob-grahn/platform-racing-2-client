//data.CommandHandler = data.class_12

package com.jiggmin.data
{
    import menu.CommAuth;
    import com.hurlant.crypto.hash.MD5;
    import com.hurlant.util.Hex;
    import flash.events.Event;
    import flash.utils.ByteArray;
    import dialogs.MessagePopup;
    import gameplay.Game;
    import gameplay.CatCaptcha;
    import player_profile.AccountInfo;
    import level_browser.LevelListing;

    public class CommandHandler
    {

        public static var commandHandler:CommandHandler;

        private var EOL:String = String.fromCharCode(4);
        private var inBuffer:String = "";
        private var commands:Object = new Object();
        private var md5:MD5 = new MD5();
        public var sendNum:int = -1;

        public function CommandHandler()
        {
            CommandHandler.commandHandler = this;
            this.defineCommand("message", this.message);
            this.defineCommand("setRank", this.setRank);
            this.defineCommand("setGroup", this.setGroup);
            this.defineCommand("startGame", this.startGame);
            this.defineCommand("resend", this.resend);
            this.defineCommand("pmNotify", this.pmNotify);
            this.defineCommand('becomeSpecialUser', this.becomeSpecialUser);
            this.defineCommand('becomePrizer', this.becomePrizer);
            this.defineCommand('demotePrizer', this.demotePrizer);
            this.defineCommand("becomeTempMod", this.becomeTempMod);
            this.defineCommand("becomeTrialMod", this.becomeTrialMod);
            this.defineCommand("becomeFullMod", this.becomeFullMod);
            this.defineCommand("demoteMod", this.demoteMod);
            this.defineCommand("areYouHuman", this.areYouHuman);
            this.defineCommand("tournamentMode", this.tournamentMode);
            this.defineCommand("guildChange", this.guildChange);
            this.defineCommand('setServerOwner', this.setServerOwner);
            this.defineCommand('wearingHat', this.wearingHat);
        }

        public function addText(s:String)
        {
            this.inBuffer = this.inBuffer + s;
            var endPos:Number = this.inBuffer.indexOf(this.EOL);
            while (endPos != -1) {
                var dataStr:String = this.inBuffer.substring(0, endPos);
                this.inBuffer = this.inBuffer.substr(endPos + 1);
                if (Main.testing == true) {
                    trace('Read: ' + dataStr);
                }
                this.handleResponse(dataStr);
                endPos = this.inBuffer.indexOf(this.EOL);
            }
        }

        private function handleResponse(s:String)
        {
            var arr:Array = s.split("`");
            var servHash:String = arr[0];
            var num:int = arr[1];
            var command:String = arr[2];
            arr.splice(0, 3);
            var gameFullStr:String = CommAuth.getToken(Main.server.server_id) + num + "`" + command + "`" + arr.join("`");
            var gameHash:String = Hex.fromArray(this.md5.hash(Hex.toArray(Hex.fromString(gameFullStr)))).substr(0, 3);
            if (gameHash == servHash && num > this.sendNum) {
                this.sendNum = num;
                if (this.commands[command] != null) {
                    this.commands[command](arr);
                }
            }
        }

        public function defineCommand(s:String, fn:Function)
        {
            this.commands[s] = fn;
        }

        public function resend(a:Array)
        {
            if (Main.socket.sendNum < int(a[0])) {
                Main.socket.close();
            }
        }

        private function message(a:Array)
        {
            new MessagePopup(a[0]);
        }

        private function startGame(a:Array)
        {
            var courseID:int = a[0];
            if (Main.filledSlotCourseID == courseID) {
                Main.pageHolder.changePage(new Game(courseID, Main.filledSlotCourseVersion));
            }
        }

        private function setRank(a:Array)
        {
            var rank:int = a[0];
            SecureData.setNumber("userRank", rank);
            if (Main.instance.kongAPI != null) {
                Main.instance.kongAPI.stats.submit("Rank", rank);
            }
        }

        private function setGroup(a:Array)
        {
            Main.group = a[0];
        }

        private function pmNotify(a:Array)
        {
            UnreadNotif.notifyUser(int(a[0]));
        }

        private function becomeSpecialUser(a:Array)
        {
            Main.isSpecialUser = true;
        }

        private function becomePrizer(a:Array)
        {
            Main.isPrizer = true;
        }

        private function demotePrizer(a:Array)
        {
            Main.isPrizer = false;
        }

        private function becomeTempMod(a:Array)
        {
            Main.group = 1;
            Main.isTempMod = true;
            Main.isTrialMod = false;
        }

        private function becomeTrialMod(a:Array)
        {
            Main.group = 2;
            Main.isTempMod = false;
            Main.isTrialMod = true;
        }

        private function becomeFullMod(a:Array)
        {
            Main.group = 2;
            Main.isTempMod = false;
            Main.isTrialMod = false;
        }

        private function demoteMod(a:Array)
        {
            Main.group = 1;
            Main.isTempMod = false;
            Main.isTrialMod = false;
        }

        private function areYouHuman(a:Array)
        {
            new CatCaptcha();
        }

        private function tournamentMode(a:Array)
        {
            Main.server.tournament = Boolean(int(a[0]));
        }

        private function guildChange(a:Array)
        {
            var ret:Object = JSON.parse(a[0]);
            Main.guild = ret.guild_id;
            Main.guildName = ret.guild_name;
            Main.guildOwner = ret.is_owner;
            Main.instance.dispatchEvent(new Event(Main.accountChange));
        }

        private function setServerOwner(a:Array)
        {
            Main.server.server_owner = int(a[0]);
        }

        private function wearingHat(a:Array)
        {
            AccountInfo.currentHat = int(a[0]);
            if (LevelListing.levelListing != null) {
                LevelListing.levelListing.dispatchEvent(new Event('testLevelAccess'));
            }
        }


    }
}
