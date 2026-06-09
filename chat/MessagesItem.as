
package chat
{
    import com.jiggmin.data.Data;
    import com.jiggmin.data.HTMLNameMaker;
    import com.jiggmin.data.Settings;
    import flash.events.MouseEvent;
    import flash.ui.Mouse;
    import flash.ui.MouseCursor;
    import dialogs.ConfirmPopup;
    import dialogs.HoverPopup;
    import dialogs.SendMessagePopup;

    public class MessagesItem extends Removable 
    {

        private var m:MessagesItemGraphic = new MessagesItemGraphic();
        private var reportButton:ReportMessageButton = new ReportMessageButton();
        private var deleteButton:DeleteMessageButton = new DeleteMessageButton();
        private var replyButton:ReplyMessageButton = new ReplyMessageButton();
        private var htmlNameMaker:HTMLNameMaker = new HTMLNameMaker();
        private var userName:String;
        public var messageId:Number;
        private var target:Messages;
        private var messageText:String;
        private var time:int;
        private var hover:HoverPopup;

        // _loc8 = htmlName
        // _loc9 = date
        public function MessagesItem(messages:Messages, messageId:Number, name:String, group:String, body:String, gm:Boolean, time:Number, userId:Number)
        {
            this.target = messages;
            this.messageId = messageId;
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
            this.time = time;
            var date:Date = new Date(this.time * 1000);
            this.m.timeBox.text = date.toLocaleDateString();
            this.m.timeBox.y = this.m.textBox.height + 32;
            this.reportButton.y = this.deleteButton.y = this.replyButton.y = this.m.textBox.height + 42;
            this.reportButton.x = 15;
            this.deleteButton.x = 37;
            this.replyButton.x = 59;
            this.m.timeBox.addEventListener(MouseEvent.MOUSE_OVER, this.hoverTime, false, 0, true);
            this.m.timeBox.addEventListener(MouseEvent.MOUSE_OUT, this.hoverOutTime, false, 0, true);
            this.reportButton.addEventListener(MouseEvent.CLICK, this.clickReport);
            this.deleteButton.addEventListener(MouseEvent.CLICK, this.clickDelete);
            this.replyButton.addEventListener(MouseEvent.CLICK, this.clickReply);
            addChild(this.m);
            addChild(this.reportButton);
            addChild(this.deleteButton);
            addChild(this.replyButton);
        }

        private function clickReport(e:MouseEvent)
        {
            new ConfirmPopup(this.confirmReport, "Are you sure you want to report this message to the moderators? If the sender of this message is asking for your password, being a rather mean jerk, or spamming your inbox, then please do report this message.");
        }

        private function clickDelete(e:MouseEvent)
        {
            new ConfirmPopup(this.confirmDelete, "Are you sure you want to delete this message from " + Data.escapeString(this.userName) + "?");
        }

        private function clickReply(e:MouseEvent)
        {
            var replyStr:String = "\n--- \n" + this.messageText;
            var maxQuote:int = 200;
            if (replyStr.length > maxQuote) {
                replyStr = replyStr.substr(0, maxQuote) + "...";
            }
            new SendMessagePopup(this.userName, replyStr);
        }

        private function confirmReport()
        {
            this.target.doReport(this);
        }

        public function confirmDelete()
        {
            this.target.doDelete(this);
        }

        private function hoverTime(e:MouseEvent)
        {
            Mouse.cursor = MouseCursor.BUTTON;
            this.m.timeBox.textColor = 0x666666;
            this.hover = new HoverPopup("Sent Time", 'This message was sent on ' + Data.getDateTimeStr(this.time, ['long', 'medium']) + '.', this.m.timeBox);
        }

        private function hoverOutTime(e:* = null)
        {
            Mouse.cursor = MouseCursor.AUTO;
            this.m.timeBox.textColor = 0x000000;
            if (this.hover != null) {
                this.hover.remove();
                this.hover = null;
            }
        }

        override public function remove()
        {
            this.hoverOutTime();
            this.m.timeBox.removeEventListener(MouseEvent.MOUSE_OVER, this.hoverTime);
            this.m.timeBox.removeEventListener(MouseEvent.MOUSE_OUT, this.hoverOutTime);
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
}//package chat

