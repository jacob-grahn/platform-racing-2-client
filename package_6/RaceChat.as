// RaceChat = class_94

package package_6
{
    import page.Chat;
    import flash.text.TextField;
	import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.KeyboardEvent;
    import fl.events.ScrollEvent;

    public class RaceChat extends Chat 
    {

        public static var textBox:TextField; // textBox = var_423

        private var m:RaceChatGraphic = new RaceChatGraphic();

        public function RaceChat()
        {
            addChild(this.m);
            maxMessages = 7;
            this.m.top.textBox1.addEventListener(Event.ENTER_FRAME, this.ensureBottom);
            this.m.bg.textBox2.addEventListener(Event.ENTER_FRAME, this.ensureBottom);
            Main.stage.addEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler, false, 0, true);
            Main.stage.addEventListener(KeyboardEvent.KEY_DOWN, this.focusOrSend, false, 0, true); // focusOrSend = method_374
            htmlNameMaker.listenForLink(this.m.top.textBox1);
            RaceChat.textBox = this.m.chatInput;
        }

        override public function recieveSystemMessage(arr:Array)
        {
            displayMessage("<i><font color='#3E8697'>" + arr[0] + "</font></i><br/>");
        }

        private function ensureBottom(e:Event)
        {
            this.showMessages();
        }

        private function mouseDownHandler(e:MouseEvent)
        {
            if (e.target != this && e.target != this.m.chatInput && Main.stage.focus == this.m.chatInput) {
                this.focusOnRace();
            }
        }

        private function focusOrSend(e:KeyboardEvent)
        {
            if (e.keyCode == 13) {
                if (e.target != this && e.target != this.m.chatInput) {
                    Main.stage.focus = this.m.chatInput;
                    this.m.chatInput.setSelection(0, 0);
                } else {
                    this.sendMessage(this.m.chatInput.text);
                    this.m.chatInput.text = "";
                    this.focusOnRace(); // focusOnRace = method_223
                }
            }
        }

        override protected function sendMessage(message:String)
        {
            this.m.chatInput.text = "";
            super.sendMessage(message);
        }

        override protected function showMessages()
        {
            this.m.top.textBox1.htmlText = this.m.bg.textBox2.htmlText = existingMessages;
            this.m.top.textBox1.scrollV = this.m.bg.textBox2.scrollV = this.m.top.textBox1.maxScrollV;
        }

        private function focusOnRace()
        {
            Main.stage.focus = Main.stage;
        }

        override public function remove()
        {
            this.m.top.textBox1.removeEventListener(Event.ENTER_FRAME, this.ensureBottom);
            this.m.bg.textBox2.removeEventListener(Event.ENTER_FRAME, this.ensureBottom);
            Main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler);
            Main.stage.removeEventListener(KeyboardEvent.KEY_DOWN, this.focusOrSend);
            RaceChat.textBox = null;
            super.remove();
        }


    }
}
