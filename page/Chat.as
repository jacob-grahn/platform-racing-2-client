// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//page.Chat

package page
{
    import data.HTMLNameMaker;
    import data.CommandHandler;
    import data.class_28;
    import data.Settings;
    import package_4.PlayerPopup;
    import package_4.GuildPopup;
    import package_4.SendMessagePopup;
    import package_4.LevelInfoPopup;

    public class Chat extends Page 
    {

        protected var existingMessages:String = ""; // var_137
        protected var maxMessages:int = 40; // var_489
        protected var messages:int = 0;
        protected var htmlNameMaker:HTMLNameMaker = new HTMLNameMaker();
        private var hint:ArtifactHint; // var_244
        private var cm:CommandHandler = CommandHandler.commandHandler;

        public function Chat()
        {
            this.cm.defineCommand("systemChat", this.recieveSystemMessage);
            this.cm.defineCommand("chat", this.handleMessageFromArray);
        }

        override public function initialize()
        {
        }

        // fred -- artifact hint
        public function makeLink(type:String, data:Array)
        {
            if (('make' + type) in this.htmlNameMaker) {
                return this.htmlNameMaker['make' + type](data[0], data[1]);
            }
            return '';
        }

        // userName = _loc2
        // group = _loc3
        // messageText = _loc4
        // chatMessageName = _loc5
        // method_151 = handleMessageFromArray
        public function handleMessageFromArray(chatMessageArray:Array, fred:Boolean = false)
        {
            var userName:String = chatMessageArray[0];
            var group:String = chatMessageArray[1];
            var messageText:String = chatMessageArray[2];
            if (!fred) {
                if (Settings.getValue(Settings.FILTER_SWEARS, true)) {
                    messageText = class_28.escapeAndFilterString(messageText); // filters swears, prevents nuking, escapes problematic chars
                } else {
                    messageText = class_28.escapeString(messageText); // prevents nuking, escapes problematic chars
                }
            }
            var chatMessageName:String = this.htmlNameMaker.makeName(userName, group);
            var fullMessage:String = chatMessageName + "<font color='#666666'>: " + messageText + "</font><br/>";
            fullMessage = fred ? '<i>' + fullMessage + '</i>' : fullMessage;
            this.displayMessage(fullMessage);
        }

        public function recieveSystemMessage(arr:Array)
        {
            this.displayMessage("<br/><i><font color='#3E8697'>" + arr[0] + "</font></i><br/><br/>");
        }

        protected function sendMessage(message:String)
        {
            var lowerStr = message.toLowerCase();
            if (lowerStr.indexOf("/view ") == 0) {
                var playerName:String = message.substr(6);
                new PlayerPopup(playerName);
            } else if (class_28.trimWhitespace(lowerStr) == '/hint') {
                if (this.hint == null) {
                    this.hint = new ArtifactHint(this);
                }
                this.hint.load();
            } else if (message.indexOf("/guild ") == 0) {
                new GuildPopup(0, message.substr(7));
            } else if (message.indexOf("/pm ") == 0) {
                new SendMessagePopup(message.substr(4));
            } else if (message.indexOf("/level ") == 0) {
                new LevelInfoPopup(message.substr(7));
            } else {
                message = message.replace("", "");
                message = message.replace("\n", "");
                if (message != "") {
                    Main.socket.write("chat`" + message);
                }
            }
        }

        // method_107 = displayMessage
        protected function displayMessage(message:String)
        {
            this.messages++;
            if (this.messages > this.maxMessages) {
                this.existingMessages = this.existingMessages.substr(this.existingMessages.indexOf("<br/>") + 5);
            }
            this.existingMessages = this.existingMessages + message;
            this.showMessages();
        }

        protected function showMessages()
        {
        }

        override public function remove()
        {
            this.cm.defineCommand("systemChat", null);
            this.cm.defineCommand("chat", null);
            this.htmlNameMaker.remove();
            if (this.hint != null) {
                this.hint.remove();
                this.hint = null;
            }
            super.remove();
        }


    }
}

