// package_21.MessagesItem = package_21.class_288

package package_21
{
    import com.jiggmin.data.HTMLNameMaker;
    import com.jiggmin.data.Settings;
    import com.jiggmin.data.Data;
    import flash.events.MouseEvent;
    import package_4.ConfirmPopup;
    import package_4.SendMessagePopup;

    public class MessagesItem extends Removable 
    {

        private var m:MessagesItemGraphic = new MessagesItemGraphic();
        private var reportButton:ReportMessageButton = new ReportMessageButton(); // var_319
        private var deleteButton:DeleteMessageButton = new DeleteMessageButton();
        private var replyButton:ReplyMessageButton = new ReplyMessageButton(); // var_222
        private var htmlNameMaker:HTMLNameMaker = new HTMLNameMaker();
        private var userName:String;
        public var messageId:Number; // var_451
        private var target:Messages;
        private var messageText:String; // var_588

        // _loc8 = htmlName
        // _loc9 = date
        public function MessagesItem(messages:Messages, _arg_2:Number, name:String, group:String, body:String, gm:Boolean, time:Number, userId:Number)
        {
            this.target = messages;
            this.messageId = _arg_2;
            this.userName = name;
            var htmlName:String = this.htmlNameMaker.makeName(name, group);
            this.htmlNameMaker.listenForLink(this.m.nameBox);
            this.htmlNameMaker.listenForLink(this.m.textBox);
            if (Settings.getValue(Settings.FILTER_SWEARS, true)) {
                body = Data.filterSwears(body);
            }
            this.messageText = body;
            if (group < 3) {
                body = Data.escapeString(body, true);
            }
            body = Data.parseLinks(body);
            body = body.replace(/\r/g, "<br>");
            this.m.nameBox.htmlText = htmlName;
            this.m.textBox.htmlText = body;
            this.m.textBox.autoSize = "left";
            this.m.bg.height = this.m.textBox.height + 6;
            this.m.guildMsgIcon.visible = gm;
            var date:Date = new Date();
            date.setTime(time * 1000);
            this.m.timeBox.text = date.toLocaleDateString();
            this.m.timeBox.y = this.m.textBox.height + 32;
            this.reportButton.y = this.deleteButton.y = this.replyButton.y = this.m.textBox.height + 42;
            this.reportButton.x = 15;
            this.deleteButton.x = 37;
            this.replyButton.x = 59;
            this.reportButton.addEventListener(MouseEvent.CLICK, this.clickReport);
            this.deleteButton.addEventListener(MouseEvent.CLICK, this.clickDelete);
            this.replyButton.addEventListener(MouseEvent.CLICK, this.clickReply);
            addChild(this.m);
            addChild(this.reportButton);
            addChild(this.deleteButton);
            addChild(this.replyButton);
        }

        // method_760 = clickReport
        private function clickReport(e:MouseEvent)
        {
            new ConfirmPopup(this.confirmReport, "Are you sure you want to report this message to the moderators? If the sender of this message is asking for your password, being a rather mean jerk, or spamming your inbox, then please do report this message.");
        }

        private function clickDelete(e:MouseEvent)
        {
            new ConfirmPopup(this.confirmDelete, "Are you sure you want to delete this message from " + Data.escapeString(this.userName) + "?");
        }

        // _loc2 = replyStr
        // _loc3 = maxQuote
        // method_460 = clickReply
        private function clickReply(e:MouseEvent)
        {
            var replyStr:String = "\n--- \n" + this.messageText;
            var maxQuote:int = 200;
            if (replyStr.length > maxQuote) {
                replyStr = replyStr.substr(0, maxQuote) + "...";
            }
            new SendMessagePopup(this.userName, replyStr);
        }

        // method_573 = confirmReport
        private function confirmReport()
        {
            this.target.doReport(this);
        }

        // method_73 = confirmDelete
        public function confirmDelete()
        {
            this.target.doDelete(this);
        }

        override public function remove()
        {
            this.reportButton.removeEventListener(MouseEvent.CLICK, this.clickReport);
            this.deleteButton.removeEventListener(MouseEvent.CLICK, this.clickDelete);
            this.replyButton.removeEventListener(MouseEvent.CLICK, this.clickReply);
            this.reportButton.remove();
            this.deleteButton.remove();
            this.replyButton.remove();
            this.htmlNameMaker.remove();
            super.remove();
        }


    }
}//package package_21

