package com.jiggmin.data
{
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.Socket;
    import flash.system.Security;
    import flash.utils.getTimer;

    public class PhysicsTrace
    {
        private static const HOST:String = "127.0.0.1";
        private static const PORT:int = 9451;
        private static const MAX_BUFFER:int = 20000;
        private static const FLAG_URL:String = "physics-trace.flag";
        private static const FLAG_POLL_MS:int = 500;

        private static var socket:Socket;
        private static var connected:Boolean = false;
        private static var disabled:Boolean = false;
        private static var enabled:Boolean = false;
        private static var checkingFlag:Boolean = false;
        private static var lastFlagCheck:int = -500;
        private static var flagLoader:URLLoader;
        private static var buffer:Array = [];

        public static function isEnabled():Boolean
        {
            pollEnabled();
            return enabled;
        }

        public static function log(line:String)
        {
            if (line == null || disabled || !isEnabled()) {
                return;
            }
            ensureSocket();
            if (connected) {
                writeLine(line);
            } else {
                buffer.push(line);
                if (buffer.length > MAX_BUFFER) {
                    buffer.shift();
                }
            }
        }

        public static function pollEnabled()
        {
            var now:int = getTimer();
            if (checkingFlag || now - lastFlagCheck < FLAG_POLL_MS) {
                return;
            }
            checkingFlag = true;
            lastFlagCheck = now;
            flagLoader = new URLLoader();
            flagLoader.addEventListener(Event.COMPLETE, onFlagComplete, false, 0, false);
            flagLoader.addEventListener(IOErrorEvent.IO_ERROR, onFlagMissing, false, 0, false);
            flagLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onFlagMissing, false, 0, false);
            try {
                flagLoader.load(new URLRequest(FLAG_URL + "?t=" + now));
            } catch (error:Error) {
                enabled = false;
                checkingFlag = false;
                flagLoader = null;
            }
        }

        private static function onFlagComplete(event:Event)
        {
            enabled = true;
            checkingFlag = false;
            flagLoader = null;
        }

        private static function onFlagMissing(event:Event)
        {
            enabled = false;
            checkingFlag = false;
            flagLoader = null;
        }

        private static function ensureSocket()
        {
            if (socket != null || disabled) {
                return;
            }
            socket = new Socket();
            socket.addEventListener(Event.CONNECT, onConnect, false, 0, true);
            socket.addEventListener(Event.CLOSE, onClose, false, 0, true);
            socket.addEventListener(IOErrorEvent.IO_ERROR, onError, false, 0, true);
            socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError, false, 0, true);
            try {
                Security.loadPolicyFile("xmlsocket://" + HOST + ":" + PORT);
                socket.connect(HOST, PORT);
            } catch (error:Error) {
                disabled = true;
            }
        }

        private static function onConnect(event:Event)
        {
            connected = true;
            while (buffer.length > 0 && connected) {
                writeLine(String(buffer.shift()));
            }
        }

        private static function onClose(event:Event)
        {
            connected = false;
            disabled = true;
        }

        private static function onError(event:Event)
        {
            connected = false;
            disabled = true;
        }

        private static function writeLine(line:String)
        {
            try {
                socket.writeUTFBytes(line + "\n");
                socket.flush();
            } catch (error:Error) {
                connected = false;
                disabled = true;
            }
        }
    }
}
