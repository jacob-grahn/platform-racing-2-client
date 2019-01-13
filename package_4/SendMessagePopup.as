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

        public function SendMessagePopup(name:String = "", message:String = "", guild:Boolean = false)
        {
            this.isGuildMessage = guild;
            this.m.send_bt.addEventListener(MouseEvent.CLICK, this.clickSend);
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel);
            this.m.nameBox.text = name;
            this.m.textBox.text = message;
            addChild(this.m);
            Main.stage.focus = this.m.textBox;
            if (this.isGuildMessage) {
                this.m.nameBox.editable = false;
                this.m.nameBox.alpha = 0.5;
            }
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
                uploading.addEventListener(Event.COMPLETE, this.clickCancel);
            }
        }

        private function clickCancel(e:*)
        {
            startFadeOut();
        }

        override public function remove()
        {
            this.m.send_bt.removeEventListener(MouseEvent.CLICK, this.clickSend);
            this.m.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
            super.remove();
        }


    }
}
