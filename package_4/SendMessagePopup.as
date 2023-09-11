// package_4.SendMessagePopup = package_4.class_190

package package_4
{
	import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;

    public class SendMessagePopup extends Popup 
    {

        private var m:SendMessagePopupGraphic = new SendMessagePopupGraphic();
        private var isGuildMessage:Boolean = false; // var_622
        private var hover:HoverPopup = null;

        public function SendMessagePopup(name:String = "", message:String = "", guild:Boolean = false, level:Boolean = false)
        {
            this.isGuildMessage = guild;
            this.m.send_bt.addEventListener(MouseEvent.CLICK, this.clickSend, false, 0, true);
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel, false, 0, true);
            this.m.codes_bt.addEventListener(MouseEvent.CLICK, this.clickCodes, false, 0, true);
            this.m.codes_bt.addEventListener(MouseEvent.MOUSE_OVER, this.hoverOverCodes, false, 0, true);
            this.m.codes_bt.addEventListener(MouseEvent.MOUSE_OUT, this.hoverOutCodes, false, 0, true);
            this.m.nameBox.text = name;
            this.m.textBox.text = message;
            this.countChars();
            this.m.textBox.addEventListener(Event.CHANGE, this.countChars, false, 0, true);
            addChild(this.m);
            if (this.isGuildMessage) {
                this.m.nameBox.editable = false;
                this.m.nameBox.alpha = 0.5;
            }
            if (level) {
                addEventListener(LOADED, this.focusNameBox, false, 0, true);
            } else {
                addEventListener(LOADED, this.focusTextBox, false, 0, true);
            }
        }

        private function hoverOverCodes(e:MouseEvent)
        {
            this.hover = new HoverPopup("Rich Formatting", 'Impress your friends by using rich formatting in PMs! Click to learn more.', this.m.codes_bt);
        }

        private function hoverOutCodes(e:* = null)
        {
            if (this.hover != null) {
                this.hover.remove();
                this.hover = null;
            }
        }

        private function clickCodes(e:MouseEvent)
        {
            new PMRFCodesPopup();
        }

        private function focusNameBox(e:Event)
        {
            removeEventListener(LOADED, this.focusNameBox);
            Main.stage.focus = this.m.nameBox;
        }

        private function focusTextBox(e:Event)
        {
            removeEventListener(LOADED, this.focusTextBox);
            Main.stage.focus = this.m.textBox;
        }

        private function countChars(e:Event = null)
        {
            this.m.messageCharsRemaining.text = this.m.textBox.length + " / 1000";
        }

        // method_264 = clickSend
        private function clickSend(e:MouseEvent)
        {
            if (this.m.nameBox.text == "") {
                new MessagePopup("Please enter a name!");
            } else if (this.m.textBox.text == "") {
                new MessagePopup("You didn't write a message!");
            } else {
                var vars:URLVariables = new URLVariables();
                vars.to_name = this.m.nameBox.text;
                vars.message = this.m.textBox.text;
                var toURL:String = Main.baseURL + "/message_send.php";
                if (this.isGuildMessage) {
                    toURL = Main.baseURL + "/guild_message.php";
                }
                var request:URLRequest = new URLRequest(toURL);
                request.data = vars;
                request.method = URLRequestMethod.POST;
                var uploading:UploadingPopup = new UploadingPopup(request, 'json');
                uploading.addEventListener(SuperLoader.d, this.clickCancel, false, 0, true);
                uploading.addEventListener(SuperLoader.e, this.onError, false, 0, true);
            }
        }

        private function onError(e:*)
        {
            return;
        }

        private function clickCancel(e:*)
        {
            startFadeOut();
        }

        override public function remove()
        {
            this.hoverOutCodes();
            this.m.textBox.removeEventListener(Event.CHANGE, this.countChars);
            this.m.send_bt.removeEventListener(MouseEvent.CLICK, this.clickSend);
            this.m.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
            this.m.codes_bt.removeEventListener(MouseEvent.CLICK, this.clickCodes);
            this.m.codes_bt.removeEventListener(MouseEvent.MOUSE_OVER, this.hoverOverCodes);
            this.m.codes_bt.removeEventListener(MouseEvent.MOUSE_OUT, this.hoverOutCodes);
            super.remove();
        }


    }
}
