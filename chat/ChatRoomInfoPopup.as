

package chat
{
    import dialogs.InfoPopup;
    import com.jiggmin.data.CommandHandler;
    import flash.display.DisplayObject;

    public class ChatRoomInfoPopup extends InfoPopup 
    {

        private var m:ChatRoomInfoPopupGraphic = new ChatRoomInfoPopupGraphic();

        public function ChatRoomInfoPopup(d:DisplayObject)
        {
            addChild(this.m);
            super(d);
            CommandHandler.commandHandler.defineCommand("setChatRoomList", this.setChatRoomList);
            Main.socket.write("get_chat_rooms`");
        }

        public function setChatRoomList(array:Array)
        {
            this.m.loadingGraphic.visible = false;
            var fontTag:String = "<font face=\"_sans\" size=\"11\">"; // fixes the alternating font bug when viewing the chat room list
			var room:String;
            for each (room in array) { // room name escaped at server level
                this.m.textBox.htmlText = this.m.textBox.htmlText + fontTag + room + "</font>" + "<br/>";
            }
        }

        override public function remove()
        {
            CommandHandler.commandHandler.defineCommand("setChatRoomList", null);
            super.remove();
        }


    }
}
