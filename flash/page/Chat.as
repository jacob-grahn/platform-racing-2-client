// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//page.Chat

package page
{
    import com.jiggmin.data.HTMLNameMaker;
    import com.jiggmin.data.CommandHandler;
    import com.jiggmin.data.Data;
    import com.jiggmin.data.Settings;
    import dialogs.PlayerPopup;
    import dialogs.GuildPopup;
    import dialogs.SendMessagePopup;
    import dialogs.LevelInfoPopup;

    public class Chat extends Page 
    {

        protected var existingMessages:String = "";
        protected var maxMessages:int = 40;
        protected var messages:int = 0;
        protected var htmlNameMaker:HTMLNameMaker = new HTMLNameMaker();
        private var hint:ArtifactHint;
        private var cm:CommandHandler = CommandHandler.commandHandler;

        public function Chat()
        {
            this.cm.defineCommand("systemChat", this.receiveSystemMessage);
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

        public function handleMessageFromArray(chatMessageArray:Array, fred:Boolean = false)
        {
            var userName:String = chatMessageArray[0];
            var group:String = chatMessageArray[1];
            var messageText:String = chatMessageArray[2];
            if (!fred) {
                if (Settings.getValue(Settings.FILTER_SWEARS, true)) {
                    messageText = Data.escapeAndFilterString(messageText); // filters swears, prevents nuking, escapes problematic chars
                } else {
                    messageText = Data.escapeString(messageText); // prevents nuking, escapes problematic chars
                }
            }
            var chatMessageName:String = this.htmlNameMaker.makeName(userName, group);
            var fullMessage:String = chatMessageName + "<font color='#666666'>: " + messageText + "</font><br/>";
            fullMessage = fred ? '<i>' + fullMessage + '</i>' : fullMessage;
            this.displayMessage(fullMessage);
        }

        // recieveSystemMessage = receiveSystemMessage (typo fix)
        public function receiveSystemMessage(arr:Array)
        {
            this.displayMessage("<br/><i><font color='#3E8697'>" + arr[0] + "</font></i><br/><br/>");
        }

        protected function sendMessage(message:String)
        {
            var lowerStr = message.toLowerCase();
            var trimStr = Data.trimWhitespace(lowerStr);
            if (lowerStr.indexOf("/view ") == 0) {
                var playerName:String = message.substr(6);
                new PlayerPopup(playerName);
            } else if (trimStr == '/hint' || trimStr == '/lotw' || trimStr == '/arti') {
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

