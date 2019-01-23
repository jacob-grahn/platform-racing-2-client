// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_21.Messages = package_21.class_259

package package_21
{
    import page.Page;
    import ui.CustomScrollBar;
    import ui.PageNavigation;
    import package_4.UploadingPopup;
    import flash.events.MouseEvent;
    import data.UnreadNotif;
    import package_4.SendMessagePopup;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.events.Event;
    import package_4.ConfirmPopup;

    public class Messages extends Page 
    {

        private var m:MessagesGraphic = new MessagesGraphic();
        private var scrollBar:CustomScrollBar = new CustomScrollBar();
        private var loadingGraphic:LoadingGraphic = new LoadingGraphic();
        private var pageNavigation:PageNavigation;
        private var loader:SuperLoader;
        private var var_178:Array;
        private var uploading:UploadingPopup; // var_148
        private var var_167:int = 1;
        private var var_564:int = 10;

        public function Messages()
        {
            this.pageNavigation = new PageNavigation(this, "minimal", 1, 99, 110);
            this.loader = new SuperLoader(true, SuperLoader.j);
            this.var_178 = new Array();
            super();
            this.scrollBar.x = 176;
            this.scrollBar.init(this.m.var_295, 340, 330);
            addChild(this.scrollBar);
            this.pageNavigation.x = 33;
            this.m.var_93.addEventListener(MouseEvent.CLICK, this.method_295, false, 0, true);
            this.m.var_108.addEventListener(MouseEvent.CLICK, this.method_245, false, 0, true);
            addChild(this.m);
            this.loadingGraphic.x = 88;
            this.loadingGraphic.y = 150;
            this.loader.addEventListener(SuperLoader.d, this.method_228);
            this.loader.addEventListener(SuperLoader.e, this.handleError);
            this.method_453();
            UnreadNotif.method_692();
        }

        private function method_295(e:MouseEvent)
        {
            new SendMessagePopup();
        }

        // _loc1 = vars
        // _loc2 = request
        private function method_453()
        {
            this.method_170();
            var vars:URLVariables = new URLVariables();
            vars.start = (this.var_167 - 1) * this.var_564;
            vars.count = this.var_564;
            var request:URLRequest = new URLRequest(Main.baseURL + "/messages_get.php");
            request.data = vars;
            this.loader.load(request);
            addChild(this.loadingGraphic);
        }

        // _loc2 = message
        // _loc3 = item
        private function method_228(e:Event)
        {
            removeChild(this.loadingGraphic);
            this.pageNavigation.y = 50;
            this.m.var_295.addChild(this.pageNavigation);
            this.scrollBar.position(0);
            for each (var message:Object in this.loader.parsedData.messages) {
                var item:MessagesItem = new MessagesItem(this, message.message_id, message.name, message.group, message.message, message.time, message.user_id);
                this.var_178.push(item);
            }
            this.method_528();
        }

        private function method_528()
        {
            var _local_1:MessagesItem;
            var _local_2:Number = 0;
            var _local_3:int;
            while (_local_3 < this.var_178.length) {
                _local_1 = this.var_178[_local_3];
                _local_1.y = _local_2;
                this.m.var_295.addChild(_local_1);
                _local_2 = (_local_2 + (Math.round(_local_1.height) + 18));
                _local_3++;
            }
            this.pageNavigation.y = (_local_2 + 10);
        }

        private function method_170()
        {
            var _local_1:MessagesItem;
            var _local_2:int;
            while (_local_2 < this.var_178.length) {
                _local_1 = this.var_178[_local_2];
                _local_1.remove();
                _local_2++;
            }
            this.var_178 = new Array();
            if (this.pageNavigation.parent == this.m.var_295) {
                this.m.var_295.removeChild(this.pageNavigation);
            }
        }

        // _loc2 = vars
        // _loc3 = request
        public function method_670(item:MessagesItem)
        {
            item.alpha = 0.5;
            var vars:URLVariables = new URLVariables();
            vars.message_id = item.var_451;
            var request:URLRequest = new URLRequest(Main.baseURL + "/message_report.php");
            request.method = URLRequestMethod.POST;
            request.data = vars;
            this.uploading = new UploadingPopup(request, 'json');
            //this.uploading.addEventListener(Event.COMPLETE, this.method_386, false, 0, true);
        }

        // _loc2 = vars
        // _loc3 = request
        public function method_521(item:MessagesItem)
        {
            item.alpha = 0.25;
            var vars:URLVariables = new URLVariables();
            vars.message_id = item.var_451;
            var request:URLRequest = new URLRequest(Main.baseURL + "/message_delete.php");
            request.method = URLRequestMethod.POST;
            request.data = vars;
            this.uploading = new UploadingPopup(request, 'json');
            //this.uploading.addEventListener(Event.COMPLETE, this.method_443, false, 0, true);
        }

        private function handleError(e:Event)
        {
            removeChild(this.loadingGraphic);
        }

        private function method_386(e:Event)
        {
        }

        private function method_443(e:Event)
        {
        }

        private function method_245(e:MouseEvent)
        {
            new ConfirmPopup(this.method_530, "Are you sure you want to delete all of your messages?");
        }

        public function method_530()
        {
            var vars:URLVariables = new URLVariables();
            var request:URLRequest = new URLRequest(Main.baseURL + "/messages_delete_all.php");
            request.data = vars;
            request.method = URLRequestMethod.POST;
            new UploadingPopup(request, 'json');
            this.method_170();
        }

        public function setPageNum(_arg_1:int)
        {
            this.var_167 = _arg_1;
            this.method_453();
        }

        override public function remove()
        {
            this.method_170();
            this.m.var_93.removeEventListener(MouseEvent.CLICK, this.method_295);
            this.m.var_108.removeEventListener(MouseEvent.CLICK, this.method_245);
            this.loader.removeEventListener(SuperLoader.d, this.method_228);
            this.loader.remove();
            this.loader = null;
            this.pageNavigation.remove();
            this.scrollBar.remove();
            this.var_178 = new Array();
            if (this.uploading != null) {
                this.uploading.removeEventListener(Event.COMPLETE, this.method_386);
                this.uploading.removeEventListener(Event.COMPLETE, this.method_443);
                this.uploading.method_136();
                this.uploading = null;
            }
            super.remove();
        }


    }
}//package package_21

