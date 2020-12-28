// data.PR2Socket = data.class_9

package com.jiggmin.data
{
    import com.hurlant.crypto.hash.MD5;
    import com.hurlant.util.Hex;
    import flash.errors.IOError;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.events.ProgressEvent;
    import flash.net.Socket;
    import flash.utils.ByteArray;
    import flash.utils.clearInterval;
    import flash.utils.setInterval;
    import menu.class_4;
    import menu.LoginPage;
    import package_4.MessagePopup;
    import package_22.Campaign;

    public class PR2Socket extends Socket 
    {

        private var pingInterval:uint = setInterval(sendPing, 10000); // var_616
        public var sendNum:int = 0;
        private var endChar:String = String.fromCharCode(4); // var_478
        private var md5:MD5 = new MD5();
        private var var_363:Time = new Time();

        public function PR2Socket()
        {
            addEventListener(Event.CLOSE, this.closeHandler, false, 0, true);
            addEventListener(Event.CONNECT, this.requestLoginId, false, 0, true);
            addEventListener(IOErrorEvent.IO_ERROR, this.anyErrorHandler, false, 0, true);
            addEventListener(SecurityErrorEvent.SECURITY_ERROR, this.anyErrorHandler, false, 0, true); // was securityErrorHandler
            addEventListener(ProgressEvent.SOCKET_DATA, this.read, false, 0, true);
            CommandHandler.commandHandler.defineCommand("ping", this.receivePing);
        }

        override public function connect(address:String, port:int) : void
        {
            this.close();
            CommandHandler.commandHandler.sendNum = -1;
            super.connect(address, port);
        }

        override public function close() : void
        {
            if (connected) {
                this.write("close`");
                super.close();
                this.sendNum = 0;
                CommandHandler.commandHandler.sendNum = -1;
            }
            delete Memory.memory["coursePageNumcampaign"]; // delete campaign page from memory
            delete Memory.memory["campaignInfo" + Campaign.campaignPage]; // delete today's campaign information from memory
            Main.isSpecialUser = Main.isPrizer = Main.isTempMod = Main.isTrialMod = false;
            UnreadNotif.reset();
        }

        public function write(str:String)
        {
            var strToHash:String;
            var hashArray:ByteArray;
            var hashStr:String;
            var subHash:String;
            if (connected) {
                this.sendNum++;
                if (this.sendNum == 12) {
                    this.sendNum++;
                }
                str = this.sendNum + "`" + str;
                strToHash = class_4.method_310(Main.server.server_id) + str;
                hashArray = this.md5.hash(Hex.toArray(Hex.fromString(strToHash)));
                hashStr = Hex.fromArray(hashArray);
                subHash = hashStr.substr(0, 3);
                str = subHash + "`" + str + this.endChar;
                try {
                    if (Main.testing == true) {
                        trace('Write: ' + str);
                    }
                    writeUTFBytes(str);
                    flush();
                } catch(e:IOError) {
                }
            }
        }

        // method_593 = read
        private function read(e:* = null)
        {
            CommandHandler.commandHandler.addText(readUTFBytes(bytesAvailable));
        }

        // method_427 = requestLoginId
        private function requestLoginId(e:Event)
        {
            this.write("request_login_id`");
        }

        // method_307 = closeHandler
        private function closeHandler(e:Event)
        {
            if (!(Main.pageHolder.getCurrentPage() is LoginPage)) {
                new MessagePopup("Disconnected.");
                Main.pageHolder.changePage(new LoginPage());
            }
            delete Memory.memory["coursePageNumcampaign"];
            delete Memory.memory["campaignInfo" + Campaign.campaignPage];
        }

        // ioErrorHandler = anyErrorHandler
        private function anyErrorHandler(e:*)
        {
            new MessagePopup("Could not connect. This could be because: \n A: My server is broken. \n B: The internet is broken. \n C: Evil aliens.");
            this.remove();
        }

        // method_247 = securityErrorHandler
        /*private function securityErrorHandler(e:SecurityErrorEvent)
        {
            this.remove();
        }

        private function method_519(e:SecurityErrorEvent)
        {
        }

        // method_227 = onData (DEPRECIATED; use this.read())
        private function onData(e:ProgressEvent)
        {
            this.read();
        }*/

        // method_725 = sendPing
        public function sendPing()
        {
            if (connected) {
                this.write("ping`");
            }
        }

        // method_824 = receivePing
        public function receivePing(arr:Array)
        {
            var _local_2:Number = Number(arr);
            var _local_3:Number = this.var_363.getTimestamp();
            var _local_4:Number = Math.abs(_local_2 - _local_3);
            if (_local_4 > 2) {
                this.var_363.setTime(_local_2);
            }
        }

        // method_26 = getMS
        public function getMS():Number
        {
            return this.var_363.getMS();
        }

        public function remove()
        {
            clearInterval(this.pingInterval);
            removeEventListener(Event.CLOSE, this.closeHandler);
            removeEventListener(Event.CONNECT, this.requestLoginId);
            removeEventListener(IOErrorEvent.IO_ERROR, this.anyErrorHandler);
            removeEventListener(SecurityErrorEvent.SECURITY_ERROR, this.anyErrorHandler);
            removeEventListener(ProgressEvent.SOCKET_DATA, this.read);
            this.close();
            //addEventListener(SecurityErrorEvent.SECURITY_ERROR, this.method_519, false, 0, true);
        }


    }
}
