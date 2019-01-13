// SuperLoader = class_15

package
{
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import package_4.MessagePopup;

    public class SuperLoader extends URLLoader
    {

        public static const j:String = "json"; // const_5
        public static const u:String = "url"; // const_80
        public static const d:String = "parsedData"; // const_4
        public static const e:String = "anyError"; // const_6

        public var useRandomNum:Boolean;
        public var parsedData:Object;
        private var readMode:String; // var_346

        public function SuperLoader(rand:Boolean=true, read:String="url")
        {
            this.useRandomNum = rand;
            this.readMode = read;
            addEventListener(IOErrorEvent.IO_ERROR, this.IOErrorHandler);
            addEventListener(Event.COMPLETE, this.onComplete);
            addEventListener(SecurityErrorEvent.SECURITY_ERROR, this.securityErrorHandler);
        }

        override public function load(request:URLRequest):void
        {
            if (this.useRandomNum) {
                var rand:int = int(Math.random() * 10000000);
                if (request.data is URLVariables) {
                    request.data.rand = rand;
                    request.data.token = Main.token;
                } else {
                    if (request.url.indexOf("?") != -1) {
                        request.url = request.url + "&";
                    } else {
                        request.url = request.url + "?";
                    }
                    request.url = request.url + "rand=" + rand + "&token=" + Main.token;
                }
            }
            try {
                super.load(request);
            } catch(error:SecurityError) {
                new MessagePopup("SuperLoader::load - A SecurityError has occurred.");
                dispatchEvent(new Event(e));
            }
        }

        private function onComplete(event:Event)
        {
            if (data != "") {
                try {
                    if (this.readMode == u) {
                        this.parsedData = new URLVariables(data);
                    }
                    if (this.readMode == j) {
                        this.parsedData = JSON.parse(data);
                    }
                    if (this.parsedData.message != null) {
                        new MessagePopup(this.parsedData.message);
                    }
                    if (this.parsedData.error == null) {
                        dispatchEvent(new Event(d));
                    } else {
                        new MessagePopup("Error: " + this.parsedData.error);
                        dispatchEvent(new Event(e));
                    }
                } catch(error:Error) {
                    new MessagePopup("Error: Loaded data was not in expected format. \n\nlocation: SuperLoader::onComplete \n\nreadMode: " + readMode + "\n\ndata: " + data);
                    dispatchEvent(new Event(e));
                }
            }
        }

         // method_426 = securityErrorHandler
        private function securityErrorHandler(e:SecurityError)
        {
            new MessagePopup("Security error. :(");
            dispatchEvent(new Event(e));
        }

        // method_359 = IOErrorHandler
        private function IOErrorHandler(err:ErrorEvent)
        {
            var errPrefix:String;
            if (err.text.indexOf('Error #') == 0) {
                errPrefix = err.text.substring(0, err.text.indexOf(':'));
                err.text = err.text.substring(err.text.indexOf(':'));
            } else {
                errPrefix = 'Error: ';
            }
            new MessagePopup(errPrefix + err.text);
            dispatchEvent(new Event(e));
        }

        public function remove()
        {
            removeEventListener(IOErrorEvent.IO_ERROR, this.IOErrorHandler);
            removeEventListener(Event.COMPLETE, this.onComplete);
            removeEventListener(SecurityErrorEvent.SECURITY_ERROR, this.securityErrorHandler);
        }


    }
}
