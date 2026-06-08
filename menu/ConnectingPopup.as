// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// menu.ConnectingPopup = menu.class_119

package menu
{
    import dialogs.Popup;
    import com.jiggmin.data.PR2Socket;
    import com.jiggmin.data.CommandHandler;
    import flash.events.MouseEvent;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.events.Event;

    public class ConnectingPopup extends Popup 
    {

        private var m:ConnectingPopupGraphic = new ConnectingPopupGraphic();

        public function ConnectingPopup()
        {
            addChild(this.m);
            if (Main.socket != null) {
                Main.socket.remove();
            }
            Main.socket = new PR2Socket();
            CommandHandler.commandHandler.defineCommand("setLoginID", this.setLoginID);
            this.m.var_1.addEventListener(MouseEvent.CLICK, this.clickCancel, false, 0, true);
            Main.socket.addEventListener(IOErrorEvent.IO_ERROR, this.onConnectionError, false, 0, true);
            Main.socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, this.onConnectionError, false, 0, true);
            Main.socket.connect(Main.server.address, Main.server.port);
        }

        public function setLoginID(_arg_1:Array)
        {
            new LoggingInPopup(_arg_1[0]);
            startFadeOut();
        }

        private function onConnectionError(_arg_1:Event)
        {
            startFadeOut();
        }

        private function clickCancel(_arg_1:MouseEvent)
        {
            startFadeOut();
            if (Main.socket != null) {
                Main.socket.remove();
            }
        }

        override public function remove()
        {
            CommandHandler.commandHandler.defineCommand("setLoginID", null);
            this.m.var_1.removeEventListener(MouseEvent.CLICK, this.clickCancel);
            Main.socket.removeEventListener(IOErrorEvent.IO_ERROR, this.onConnectionError);
            Main.socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, this.onConnectionError);
            super.remove();
        }


    }
}//package menu

