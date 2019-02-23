// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//data.CommandHandler = data.class_12

package data
{
    import com.hurlant.crypto.hash.MD5;
    import menu.class_4;
    import com.hurlant.util.Hex;
    import flash.utils.ByteArray;
    import package_4.MessagePopup;
    import package_6.Game;
    import package_6.CatCaptcha;

    public class CommandHandler
    {

        public static var commandHandler:CommandHandler;

        private var EOL:String = String.fromCharCode(4); // var_478
        private var inBuffer:String = ""; // var_226
        private var commands:Object = new Object(); // var_360
        private var md5:MD5 = new MD5();
        public var sendNum:int = -1; // var_359

        public function CommandHandler()
        {
            CommandHandler.commandHandler = this;
            this.defineCommand("message", this.message);
            this.defineCommand("setRank", this.setRank);
            this.defineCommand("setGroup", this.setGroup);
            this.defineCommand("startGame", this.startGame);
            this.defineCommand("resend", this.resend);
            this.defineCommand("pmNotify", this.pmNotify);
            this.defineCommand("becomeTempMod", this.becomeTempMod);
            this.defineCommand("becomeTrialMod", this.becomeTrialMod);
            this.defineCommand("becomeFullMod", this.becomeFullMod);
            this.defineCommand("demoteMod", this.demoteMod);
            this.defineCommand("areYouHuman", this.areYouHuman);
            this.defineCommand("tournamentMode", this.tournamentMode);
        }

        // _loc2 = endPos
        // _loc3 = data
        // method_129 = addText
        public function addText(s:String)
        {
            this.inBuffer = this.inBuffer + s;
            var endPos:Number = this.inBuffer.indexOf(this.EOL);
            while (endPos != -1) {
                var dataStr:String = this.inBuffer.substring(0, endPos);
                this.inBuffer = this.inBuffer.substr(endPos + 1);
                this.handleResponse(dataStr);
                endPos = this.inBuffer.indexOf(this.EOL);
            }
        }

        // _loc2 = arr
        // _loc3 = servHash
        // _loc4 = num
        // _loc5 = command
        // _loc6 = gameFullStr
        // _loc9 = gameHash
        // removed _loc7, _loc8, _loc10, _loc11 (condensed)
        // method_690 = handleResponse
        private function handleResponse(s:String)
        {
            var arr:Array = s.split("`");
            var servHash:String = arr[0];
            var num:int = arr[1];
            var command:String = arr[2];
            arr.splice(0, 3);
            var gameFullStr:String = class_4.method_310(Main.server.server_id) + num + "`" + command + "`" + arr.join("`");
            var gameHash:String = Hex.fromArray(this.md5.hash(Hex.toArray(Hex.fromString(gameFullStr)))).substr(0, 3);
            if (gameHash == servHash && num > this.sendNum) {
                this.sendNum = num;
                if (this.commands[command] != null) {
                    this.commands[command](arr);
                }
            }
        }

        // defineCommand = defineCommand
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

        // _loc2 = courseID
        private function startGame(a:Array)
        {
            var courseID:int = a[0];
            if (Main.var_583 != courseID) { // is this a decompilation error?
            }
            Main.pageHolder.changePage(new Game(courseID, Main.var_514));
        }

        private function setRank(a:Array)
        {
            var rank:int = a[0];
            class_33.setNumber("userRank", rank);
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
            UnreadNotif.setLastRecv(int(a[0]));
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

        // method_710 = areYouHuman
        private function areYouHuman(a:Array)
        {
            new CatCaptcha();
        }

        private function tournamentMode(a:Array)
        {
            Main.server.tournament = Boolean(int(a[0]));
        }


    }
}
