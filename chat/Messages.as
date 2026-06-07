

package chat
{
    import page.Page;
    import ui.CustomScrollBar;
    import ui.PageNavigation;
    import dialogs.UploadingPopup;
    import flash.events.MouseEvent;
    import com.jiggmin.data.UnreadNotif;
    import dialogs.SendMessagePopup;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.events.Event;
    import dialogs.ConfirmPopup;

    public class Messages extends Page 
    {

        private var m:MessagesGraphic = new MessagesGraphic();
        private var scrollBar:CustomScrollBar = new CustomScrollBar();
        private var loadingGraphic:LoadingGraphic = new LoadingGraphic();
        private var pageNavigation:PageNavigation;
        private var loader:SuperLoader;
        private var messagesArray:Array; // var_178
        private var uploading:UploadingPopup; // var_148
        private var currentPage:int = 1;
        private var itemsPerPage:int = 10;

        public function Messages()
        {
            this.pageNavigation = new PageNavigation(this, "minimal", 1, 99, 110);
            this.loader = new SuperLoader(true, SuperLoader.j);
            this.messagesArray = new Array();
            // super();
            this.scrollBar.x = 176;
            this.scrollBar.init(this.m.var_295, 340, 330);
            addChild(this.scrollBar);
            this.pageNavigation.x = 33;
            this.m.sendMessage_bt.addEventListener(MouseEvent.CLICK, this.clickSend, false, 0, true);
            this.m.deleteAll_bt.addEventListener(MouseEvent.CLICK, this.clickDeleteAll, false, 0, true);
            addChild(this.m);
            this.loadingGraphic.x = 88;
            this.loadingGraphic.y = 150;
            this.loader.addEventListener(SuperLoader.d, this.handleData);
            this.loader.addEventListener(SuperLoader.e, this.handleError);
            this.getMessages();
            UnreadNotif.updateLastRead();
        }

        // method_295 = clickSend
        private function clickSend(e:MouseEvent)
        {
            new SendMessagePopup();
        }

        // _loc1 = vars
        // _loc2 = request
        // method_453 = getMessages
        private function getMessages()
        {
            this.removeMessages();
            var vars:URLVariables = new URLVariables();
            vars.start = (this.currentPage - 1) * this.itemsPerPage;
            vars.count = this.itemsPerPage;
            var request:URLRequest = new URLRequest(Main.baseURL + "/messages_get.php");
            request.data = vars;
            this.loader.load(request);
            addChild(this.loadingGraphic);
        }

        // _loc2 = message
        // _loc3 = item
        // method_228 = handleData
        private function handleData(e:Event)
        {
            removeChild(this.loadingGraphic);
            this.pageNavigation.y = 50;
            this.m.var_295.addChild(this.pageNavigation);
            this.scrollBar.position(0);
            for each (var message:Object in this.loader.parsedData.messages) {
                var item:MessagesItem = new MessagesItem(this, message.message_id, message.name, message.group, message.message, message.guild_message, message.time, message.user_id);
                this.messagesArray.push(item);
            }
            this.populateMessages();
        }

        // _loc1 = message
        // _loc2 = nextY
        // _loc3 = i
        // method_528 = populateMessages
        private function populateMessages()
        {
            var nextY:Number = 0;
            var i:int = 0;
            while (i < this.messagesArray.length) {
                var message:MessagesItem = this.messagesArray[i];
                message.y = nextY;
                this.m.var_295.addChild(message);
                nextY += Math.round(message.height) + 18;
                i++;
            }
            this.pageNavigation.y = nextY + 10;
        }

        // _loc1 = message
        // _loc2 = i
        // method_170 = removeMessages
        private function removeMessages()
        {
            var i:int = 0;
            while (i < this.messagesArray.length) {
                var message:MessagesItem = this.messagesArray[i];
                message.remove();
                i++;
            }
            this.messagesArray = new Array();
            if (this.pageNavigation.parent == this.m.var_295) {
                this.m.var_295.removeChild(this.pageNavigation);
            }
        }

        // _loc2 = vars
        // _loc3 = request
        // method_670 = doReport
        public function doReport(item:MessagesItem)
        {
            item.alpha = 0.5;
            var vars:URLVariables = new URLVariables();
            vars.message_id = item.messageId;
            var request:URLRequest = new URLRequest(Main.baseURL + "/message_report.php");
            request.method = URLRequestMethod.POST;
            request.data = vars;
            this.uploading = new UploadingPopup(request, 'json', 'Reporting message...');
        }

        // _loc2 = vars
        // _loc3 = request
        // method_521 = doDelete
        public function doDelete(item:MessagesItem)
        {
            item.alpha = 0.25;
            var vars:URLVariables = new URLVariables();
            vars.message_id = item.messageId;
            var request:URLRequest = new URLRequest(Main.baseURL + "/message_delete.php");
            request.method = URLRequestMethod.POST;
            request.data = vars;
            this.uploading = new UploadingPopup(request, 'json', 'Deleting message...');
        }

        private function handleError(e:Event)
        {
            removeChild(this.loadingGraphic);
        }

        // method_245 = clickDeleteAll
        private function clickDeleteAll(e:MouseEvent)
        {
            new ConfirmPopup(this.doDeleteAll, "Are you sure you want to delete all of your messages?");
        }

        // method_530 = doDeleteAll
        public function doDeleteAll()
        {
            var vars:URLVariables = new URLVariables();
            var request:URLRequest = new URLRequest(Main.baseURL + "/messages_delete_all.php");
            request.data = vars;
            request.method = URLRequestMethod.POST;
            new UploadingPopup(request, 'json', 'Deleting messages...');
            this.removeMessages();
        }

        public function setPageNum(pageNum:int)
        {
            this.currentPage = pageNum;
            this.getMessages();
        }

        override public function remove()
        {
            this.removeMessages();
            this.m.sendMessage_bt.removeEventListener(MouseEvent.CLICK, this.clickSend);
            this.m.deleteAll_bt.removeEventListener(MouseEvent.CLICK, this.clickDeleteAll);
            this.loader.removeEventListener(SuperLoader.d, this.handleData);
			this.loader.removeEventListener(SuperLoader.e, this.handleError);
            this.loader.remove();
            this.loader = null;
            this.pageNavigation.remove();
            this.scrollBar.remove();
            this.messagesArray = new Array();
            if (this.uploading != null) {
                this.uploading.remove();
                this.uploading = null;
            }
            super.remove();
        }


    }
}//package chat

