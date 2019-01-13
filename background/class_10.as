// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//background.class_10

package background
{
    import flash.display.BitmapData;
    import flash.display.Bitmap;
    import page.GamePage;
    import data.Objects;
    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.geom.ColorTransform;

    public class class_10 extends class_75 
    {

        private var bitmapData:BitmapData = new BitmapData(550, 400, false, 0);
        private var bitmap:Bitmap = new Bitmap(bitmapData);
        private var color:Number;
        private var displayCode:int;

        public function class_10(_arg_1:GamePage)
        {
            super(_arg_1);
            scale = 0;
            cacheAsBitmap = true;
            mouseEnabled = false;
            mouseChildren = false;
            this.bitmap.x = -275;
            this.bitmap.y = -200;
            addChild(this.bitmap);
        }

        override public function setColor(_arg_1:Number)
        {
            this.color = _arg_1;
            this.bitmapData.fillRect(this.bitmapData.rect, _arg_1);
            this.displayCode = -1;
            super.setColor(_arg_1);
        }

        public function method_338(_arg_1:int)
        {
            this.displayCode = _arg_1;
            var _local_2:DisplayObject = Objects.getFromCode(_arg_1);
            if (_arg_1 == Objects.BG5Code) {
                this.method_536(_local_2);
            }
            this.bitmapData.draw(_local_2);
            if (((_arg_1 == Objects.BG4Code) || (_arg_1 == Objects.BG5Code))) {
                scale = 0;
            } else {
                scale = 1;
            }
            method_59();
        }

        private function method_536(_arg_1:DisplayObject)
        {
            var _local_2:MovieClip;
            var _local_6:Circle;
            var _local_7:ColorTransform;
            var _local_9:int;
            _local_2 = MovieClip(_arg_1);
            var _local_3:int = 50;
            var _local_4:int = int((550 / _local_3));
            var _local_5:int = int((400 / _local_3));
            _local_7 = new ColorTransform();
            var _local_8:int;
            while (_local_8 < _local_4) {
                _local_9 = 0;
                while (_local_9 < _local_5) {
                    _local_7.color = (Math.random() * 0xFFFFFF);
                    _local_6 = new Circle();
                    _local_6.width = (_local_6.height = 25);
                    _local_6.x = (((_local_8 * _local_3) + (15 / 2)) + (_local_6.width / 2));
                    _local_6.y = (((_local_9 * _local_3) + (15 / 2)) + (_local_6.height / 2));
                    _local_6.transform.colorTransform = _local_7;
                    _local_2.addChild(_local_6);
                    _local_9++;
                }
                _local_8++;
            }
        }

        override public function getSaveString():String
        {
            return this.displayCode.toString();
        }

        override public function setSaveString(s:String, fromLE:Boolean = true)
        {
            // drawbg true; string is not any of these: -1, square, null, and empty (ORIGINAL)
            // drawbg + isLE false; string is either -1, square, null, or empty
            if ((!Main.drawBackgrounds && !fromLE) || s == "-1" || s == "Square" || s == null || s == "") {
                return;
            }
            if (s.indexOf("BG") != -1) {
                s = "20" + s.substr(2);
            }
            this.method_338(int(s));
        }

        override public function remove()
        {
            this.bitmapData.dispose();
            this.bitmap.bitmapData = null;
            removeChild(this.bitmap);
            this.bitmap = null;
            this.bitmapData = null;
            super.remove();
        }


    }
}//package background

