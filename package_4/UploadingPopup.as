// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_4.UploadingPopup = package_4.class_117

package package_4
{
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.events.MouseEvent;
    import flash.net.URLRequest;
    import ui.ProgressBar;

    public class UploadingPopup extends Popup 
    {

        protected var loader:SuperLoader;
        private var progressBar:ProgressBar = new ProgressBar(); // progressBar = var_206
        protected var m:UploadingPopupGraphic = new UploadingPopupGraphic();
        public var data:String;
        public var parsedData:Object;

        public function UploadingPopup(request:URLRequest = null, dataMode:String = "url")
        {
            this.loader = new SuperLoader(true, dataMode);
            addChild(this.m);
            addChild(this.progressBar);
            this.progressBar.x = -100;
            this.progressBar.y = -5;
            this.loader.addEventListener(ProgressEvent.PROGRESS, this.onProgress, false, 0, true); // onProgress = method_278
            this.loader.addEventListener(Event.COMPLETE, this.onComplete, false, 0, true);
            this.loader.addEventListener(SuperLoader.d, this.parsedDataHandler, false, 0, true);
            this.loader.addEventListener(SuperLoader.e, this.clickClose, false, 0, true);
            this.loader.addEventListener(IOErrorEvent.IO_ERROR, this.clickClose, false, 0, true);
            this.m.close_bt.addEventListener(MouseEvent.CLICK, this.clickClose, false, 0, true); // clickClose = method_292
            if (request != null) {
                this.loader.load(request);
            }
        }

        protected function onComplete(e:Event)
        {
            this.progressBar.incProgress(1);
            this.data = e.target.data;
            dispatchEvent(e);
        }

        protected function parsedDataHandler(e:Event)
        {
            this.parsedData = this.loader.parsedData;
            dispatchEvent(e);
            startFadeOut();
        }

        protected function onProgress(loadObj:ProgressEvent)
        {
            this.progressBar.incProgress(loadObj.bytesLoaded / loadObj.bytesTotal);
        }

        private function clickClose(e:*)
        {
            startFadeOut();
        }

        override public function remove()
        {
            this.loader.removeEventListener(ProgressEvent.PROGRESS, this.onProgress);
            this.loader.removeEventListener(Event.COMPLETE, this.onComplete);
            this.loader.removeEventListener(SuperLoader.d, this.parsedDataHandler);
            this.loader.removeEventListener(SuperLoader.e, this.clickClose);
            this.loader.remove();
            this.loader = null;
            this.m.close_bt.removeEventListener(MouseEvent.CLICK, this.clickClose);
            this.progressBar.remove();
            super.remove();
        }


    }
}
