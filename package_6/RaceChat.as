// RaceChat = class_94

package package_6
{
    import com.jiggmin.data.Data;
    import fl.events.ScrollEvent;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import package_4.LevelInfoPopup;
    import page.Chat;

    public class RaceChat extends Chat 
    {

        public static var textBox:TextField; // textBox = var_423

        private var m:RaceChatGraphic = new RaceChatGraphic();

        public function RaceChat()
        {
            addChild(this.m);
            maxMessages = 7;
            this.m.chatInput.restrict = "^`";
            this.m.top.textBox1.mouseWheelEnabled = this.m.bg.textBox2.mouseWheelEnabled = false;
            this.m.addEventListener(MouseEvent.MOUSE_WHEEL, this.ensureBottom, false, 0, true);
            Main.stage.addEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler, false, 0, true);
            Main.stage.addEventListener(KeyboardEvent.KEY_DOWN, this.focusOrSend, false, 0, true); // method_374
            htmlNameMaker.listenForLink(this.m.top.textBox1);
            RaceChat.textBox = this.m.chatInput;
        }

        override public function receiveSystemMessage(arr:Array)
        {
            displayMessage("<i><font color='#3E8697'>" + arr[0] + "</font></i><br/>");
        }

        private function ensureBottom(e:MouseEvent)
        {
            this.m.top.textBox1.scrollV = this.m.bg.textBox2.scrollV = this.m.top.textBox1.maxScrollV;
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
                    if (Data.trimWhitespace(this.m.chatInput.text).toLowerCase() === '/level' && Course.course != null && Course.course.getCourseID() > 0) {
                        new LevelInfoPopup(Course.course.getCourseID());
                    } else {
                        this.sendMessage(this.m.chatInput.text);
                    }
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
            this.m.removeEventListener(MouseEvent.MOUSE_WHEEL, this.ensureBottom);
            Main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler);
            Main.stage.removeEventListener(KeyboardEvent.KEY_DOWN, this.focusOrSend);
            RaceChat.textBox = null;
            super.remove();
        }


    }
}
