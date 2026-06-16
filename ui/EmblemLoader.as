// ui.EmblemLoader = ui.class_287

package ui
{
    import com.jcward.workers.JPEGEncoder;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Loader;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import flash.net.FileFilter;
    import flash.net.FileReference;
    import flash.net.URLRequest;
    import flash.net.URLRequestHeader;
    import flash.net.URLRequestMethod;
    import flash.utils.ByteArray;

    public class EmblemLoader extends Sprite 
    {

        public static const BEGIN_LOADING:String = "BEGIN_LOADING";
        public static const FINISH_LOADING:String = "FINISH_LOADING"; // finishLoading

        private var eWidth:int;
        private var eHeight:int;
        private var file:FileReference;
        private var loader:Loader;
        private var superLoader:SuperLoader;
        private var bitmap:Bitmap;
        private var bitmapData:BitmapData;
        private var defaultColor:int = 0xFFFFFF;
        private var encoder:JPEGEncoder;
        private var uploadURL:String;
        private var imgDirURL:String;
        private var fileName:String;
        private var loading:Boolean = false;

        public function EmblemLoader(w:int, h:int, u:String, i:String)
        {
            this.eWidth = w;
            this.eHeight = h;
            this.uploadURL = u;
            this.imgDirURL = i;
            this.file = new FileReference();
            this.file.addEventListener(Event.SELECT, this.fileSelected, false, 0, true);
            this.file.addEventListener(Event.COMPLETE, this.fileComplete, false, 0, true);
            this.loader = new Loader();
            this.loader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.drawAndUpload, false, 0, true);
            this.superLoader = new SuperLoader(true, SuperLoader.j);
            this.superLoader.addEventListener(SuperLoader.d, this.gotFileName, false, 0, true);
            this.superLoader.addEventListener(SuperLoader.e, this.fileNameError, false, 0, true);
            this.bitmapData = new BitmapData(this.eWidth, this.eHeight, false);
            this.makeDefault();
            this.bitmap = new Bitmap(this.bitmapData);
            this.bitmap.smoothing = true;
            addChild(this.bitmap);
            this.encoder = new JPEGEncoder(90);
        }

        public function openBrowse()
        {
            this.file.browse([new FileFilter("Images", "*.jpg;*.jpeg;*.gif;*.png;*.JPG;*.JPEG;*.GIF;*.PNG")]);
        }

        public function getImage(s:String)
        {
            this.fileName = s;
            this.loader.load(new URLRequest(this.imgDirURL + this.fileName));
        }

        public function getFileName():String
        {
            return this.fileName;
        }

        public function isLoading():Boolean
        {
            return this.loading;
        }

        private function fileSelected(e:Event)
        {
            this.file.load();
        }

        private function fileComplete(e:Event)
        {
            this.loader.loadBytes(this.file.data);
        }

        private function drawAndUpload(e:Event)
        {
            this.drawImage();
            if (this.fileName != null && this.fileName != "" && this.loader.contentLoaderInfo.url.indexOf(this.fileName) == -1) {
                this.uploadImage();
            }
        }

        private function uploadImage()
        {
            if (!this.loading) {
                dispatchEvent(new Event(EmblemLoader.BEGIN_LOADING));
                this.loading = true;
                var request:URLRequest = new URLRequest(this.uploadURL);
                request.requestHeaders.push(new URLRequestHeader("Content-type", "application/octet-stream"));
                request.method = URLRequestMethod.POST;
                request.data = this.encoder.encode(this.bitmapData);
                this.superLoader.load(request);
            }
        }

        private function gotFileName(e:Event)
        {
            this.loading = false;
            this.fileName = this.superLoader.parsedData.filename;
            dispatchEvent(new Event(EmblemLoader.FINISH_LOADING));
        }

        private function fileNameError(e:Event)
        {
            this.loading = false;
            dispatchEvent(new Event(EmblemLoader.FINISH_LOADING));
        }

        private function drawImage()
        {
            var _local_1:Number = 1;
            var _local_2:Number = 1;
            var _local_3:Number = 1;
            if (this.loader.width > this.eWidth) {
                _local_1 = this.eWidth / this.loader.width;
            }
            if (this.loader.height > this.eHeight) {
                _local_2 = this.eHeight / this.loader.height;
            }
            if (_local_1 < _local_2) {
                _local_3 = _local_1;
            } else {
                _local_3 = _local_2;
            }
            var _local_4:int = int(Math.round(((this.eWidth - (this.loader.width * _local_3)) / 2)));
            var _local_5:int = int(Math.round(((this.eHeight - (this.loader.height * _local_3)) / 2)));
            var _local_6:Matrix = new Matrix();
            _local_6.createBox(_local_3, _local_3, 0, _local_4, _local_5);
            this.makeDefault();
            this.bitmapData.draw(this.loader, _local_6, null, null, null, true);
        }

        private function makeDefault()
        {
            this.bitmapData.fillRect(new Rectangle(0, 0, this.bitmapData.width, this.bitmapData.height), this.defaultColor);
        }

        public function remove()
        {
            this.file.removeEventListener(Event.SELECT, this.fileSelected);
            this.file.removeEventListener(Event.COMPLETE, this.fileComplete);
            this.file = null;
            this.loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, this.drawAndUpload);
            this.loader = null;
            this.bitmapData.dispose();
            this.bitmapData = null;
            removeChild(this.bitmap);
            this.bitmap = null;
            this.superLoader.remove();
            this.superLoader.removeEventListener(SuperLoader.d, this.gotFileName);
            this.superLoader.removeEventListener(SuperLoader.e, this.fileNameError);
            this.superLoader = null;
            this.encoder = null;
            if (parent != null) {
                parent.removeChild(this);
            }
        }


    }
}
