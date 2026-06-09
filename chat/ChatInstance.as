

package chat
{
    import page.Chat;
    import com.jiggmin.data.Memory;
	import flash.events.FocusEvent;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import fl.events.ScrollEvent;
    import flash.ui.Keyboard;
    import flash.utils.clearTimeout;

    public class ChatInstance extends Chat 
    {

        public static var instance:ChatInstance;

        private var m:ChatGraphic = new ChatGraphic();
        private var lockBot:Boolean = true;
        private var memory:Object = Memory.memory;
        private var infoPopup:ChatRoomInfoPopup;
        private var timeoutId:uint;
        private var updateMessages:Boolean = true;

        public function ChatInstance()
        {
            ChatInstance.instance = this;
            addChild(this.m);
            this.m.roomBox.addEventListener(KeyboardEvent.KEY_DOWN, this.roomBoxListenForEnter, false, 0, true);
            this.m.chatInput.addEventListener(KeyboardEvent.KEY_DOWN, this.chatInputListenForEnter, false, 0, true);
			this.m.chatInput.addEventListener(FocusEvent.FOCUS_IN, this.lockToBottom, false, 0, true);
			this.m.textBox.addEventListener(FocusEvent.FOCUS_OUT, this.lockToBottom, false, 0, true);
            this.m.send_bt.addEventListener(MouseEvent.CLICK, this.clickSend, false, 0, true);
            this.m.joinRoom_bt.addEventListener(MouseEvent.CLICK, this.clickJoinRoom, false, 0, true);
            this.m.infoButton.addEventListener(MouseEvent.MOUSE_OVER, this.overInfoHandler, false, 0, true);
            this.m.infoButton.addEventListener(MouseEvent.MOUSE_OUT, this.outInfoHandler, false, 0, true);
            addEventListener(KeyboardEvent.KEY_DOWN, this.pauseListener, false, 0, true);
            addEventListener(KeyboardEvent.KEY_UP, this.pauseListener, false, 0, true);
            htmlNameMaker.listenForLink(this.m.textBox);
            if (this.memory.chatRoom == null) {
                this.memory.chatRoom = "main";
            }
			this.m.roomBox.text = this.memory.chatRoom;
            Main.socket.write("set_chat_room`" + this.memory.chatRoom);
        }

        private function pauseListener(e:KeyboardEvent)
        {
            if (e.keyCode == 17) {
                this.updateMessages = !this.updateMessages;
                this.showMessages();
            }
        }

        public function getChatRecord():String
        {
            return this.m.textBox.text;
        }

        private function chatInputListenForEnter(e:KeyboardEvent)
        {
            if (e.keyCode == 13) {
                this.sendMessage(this.m.chatInput.text);
            }
        }

        private function clickSend(e:MouseEvent)
        {
            this.sendMessage(this.m.chatInput.text);
        }

        override protected function sendMessage(s:String)
        {
            this.m.chatInput.text = "";
            super.sendMessage(s);
            this.m.textBox.verticalScrollPosition = this.m.textBox.maxVerticalScrollPosition + 999;
            this.lockBot = true;
        }

        private function roomBoxListenForEnter(e:KeyboardEvent)
        {
            if (e.keyCode == 13) {
                this.changeRoom();
            }
        }

        private function clickJoinRoom(e:MouseEvent)
        {
            this.changeRoom();
        }

        private function changeRoom()
        {
            if (this.m.roomBox.text == "") {
                this.m.roomBox.text = "main";
            }
            this.memory.chatRoom = this.m.roomBox.text;
            Main.socket.write("set_chat_room`" + this.memory.chatRoom);
            existingMessages = "";
            this.m.textBox.text = existingMessages;
            messages = 0;
        }

        override protected function showMessages()
        {
            if (this.updateMessages === true) {
                this.maybeLockToBottom();
                this.m.textBox.htmlText = existingMessages;
                if (this.lockBot) {
                    this.lockToBottom();
                }
            }
        }

        private function maybeLockToBottom()
        {
            var pos:Number = this.m.textBox.verticalScrollPosition;
            var maxPos:Number = this.m.textBox.maxVerticalScrollPosition;
            if (pos >= (maxPos - 2)) {
                this.lockBot = true;
            } else {
                this.lockBot = false;
            }
        }

        // _SafeStr_1 = lockToBottom
        private function lockToBottom(e:FocusEvent = null)
        {
			this.lockBot = true;
            this.m.textBox.verticalScrollPosition = this.m.textBox.maxVerticalScrollPosition + 999;
        }

        private function overInfoHandler(e:MouseEvent)
        {
            this.infoPopup = new ChatRoomInfoPopup(this.m.infoButton);
        }

        private function outInfoHandler(e:MouseEvent)
        {
            this.infoPopup.remove();
            this.infoPopup = null;
        }

        override public function remove()
        {
            ChatInstance.instance = null;
            Main.socket.write("set_chat_room`none");
            clearTimeout(this.timeoutId);
            this.m.roomBox.removeEventListener(KeyboardEvent.KEY_DOWN, this.roomBoxListenForEnter);
            this.m.chatInput.removeEventListener(KeyboardEvent.KEY_DOWN, this.chatInputListenForEnter);
            this.m.send_bt.removeEventListener(MouseEvent.CLICK, this.clickSend);
            this.m.joinRoom_bt.removeEventListener(MouseEvent.CLICK, this.clickJoinRoom);
            this.m.infoButton.removeEventListener(MouseEvent.MOUSE_OVER, this.overInfoHandler);
            this.m.infoButton.removeEventListener(MouseEvent.MOUSE_OUT, this.outInfoHandler);
            removeEventListener(KeyboardEvent.KEY_DOWN, this.pauseListener);
            removeEventListener(KeyboardEvent.KEY_UP, this.pauseListener);
            if (this.infoPopup != null) {
                this.infoPopup.remove();
            }
            super.remove();
        }


    }
}
