// pixelEffects.class_21 = com.jiggmin.pixelEffects.PixelEffect1

package com.jiggmin.pixelEffects
{
    import com.jiggmin.pixelEffects.pixels.SegPixel;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.clearInterval;
    import flash.utils.setInterval;

    public class PixelEffect1 extends Sprite 
    {

        private var src:BitmapData;
        private var product:BitmapData;
        private var productBitmap:Bitmap;
        private var bgColor:Number;
        private var spread:Number;
        private var pull:Number;
        private var pixels:Number;
        private var scaleRange:Number;
        private var interval:Number;
        private var segArray:Array;
        private var drawInterval:uint;

        public function PixelEffect1(_arg_1:BitmapData, _arg_2:Number=0, _arg_3:Number=500, _arg_4:Number=0.19, _arg_5:Number=15, _arg_6:Number=15, _arg_7:Number=55)
        {
            this.src = _arg_1;
            this.spread = _arg_3;
            this.pull = _arg_4;
            this.pixels = _arg_5;
            this.scaleRange = _arg_6;
            this.interval = _arg_7;
            this.product = new BitmapData(_arg_1.width, _arg_1.height, false, _arg_2);
            this.productBitmap = new Bitmap(this.product);
            addChild(this.productBitmap);
            this.segArray = this.createSegArray();
            this.drawInterval = setInterval(this.drawPixels, _arg_7);
        }

        private function createSegArray()
        {
            var arr:Array = new Array();
            var segX:int = 0;
            while (segX * this.pixels < this.src.width) {
                arr[segX] = new Array();
                var segY:int = 0;
                while (segY * this.pixels < this.src.height) {
                    arr[segX][segY] = new Point(segX * this.pixels, segY * this.pixels);
                    segY++;
                }
                segX++;
            }
            return arr;
        }

        private function drawPixels()
        {
            this.drawPixel();
            this.drawPixel();
            this.drawPixel();
        }

        private function drawPixel()
        {
            if (this.segArray.length > 0) {
                var _local_1:Number = Math.floor(Math.random() * this.segArray.length);
                var _local_2:Number = Math.floor(Math.random() * this.segArray[_local_1].length);
                var _local_3:Number = this.segArray[_local_1][_local_2].x;
                var _local_4:Number = this.segArray[_local_1][_local_2].y;
                this.segArray[_local_1].splice(_local_2, 1);
                if (this.segArray[_local_1].length <= 0) {
                    this.segArray.splice(_local_1, 1);
                }
                var _local_5:BitmapData = new BitmapData(this.pixels, this.pixels, false, this.bgColor);
                var _local_6:Rectangle = new Rectangle(_local_3, _local_4, this.pixels, this.pixels);
                var _local_7:Point = new Point(0, 0);
                _local_5.copyPixels(this.src, _local_6, _local_7);
                var _local_8:Number = _local_3 + Math.random() * this.spread - this.spread / 2 - this.pixels * this.scaleRange / 2;
                var _local_9:Number = _local_4 + Math.random() * this.spread - this.spread / 2 - this.pixels * this.scaleRange / 2;
                var _local_10:Number = Math.random() * this.scaleRange;
                var _local_11:Number = Math.random() * this.scaleRange;
                var _local_12:SegPixel = new SegPixel(_local_5, this.product, _local_8, _local_9, _local_10, _local_11, _local_3, _local_4, this.pull);
                addChild(_local_12);
            } else {
                this.finishDrawing();
            }
        }

        private function finishDrawing()
        {
            clearInterval(this.drawInterval);
        }

        private function remove()
        {
            this.src.dispose();
            this.product.dispose();
            removeChild(this.productBitmap);
        }


    }
}//package pixelEffects

