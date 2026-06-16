// package_7.class_66 = com.jiggmin.pixelEffects.pixels.SegPixel

package com.jiggmin.pixelEffects.pixels
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.geom.Point;

    public class SegPixel extends Sprite 
    {

        private var bitmap:Bitmap;
        private var src:BitmapData;
        private var product:BitmapData;
        private var finalX:Number;
        private var finalY:Number;
        private var pull:Number;
        private var glintFrames:int = 20;
        private var glintCounter:Number = glintFrames;

        public function SegPixel(_arg_1:BitmapData, _arg_2:BitmapData, _arg_3:Number, _arg_4:Number, _arg_5:Number, _arg_6:Number, _arg_7:Number, _arg_8:Number, _arg_9:Number)
        {
            this.finalX = _arg_7;
            this.finalY = _arg_8;
            this.pull = _arg_9;
            this.src = _arg_1;
            this.product = _arg_2;
            alpha = 0;
            this.bitmap = new Bitmap(_arg_1);
            addChild(this.bitmap);
            x = _arg_3;
            y = _arg_4;
            scaleX = _arg_5;
            scaleY = _arg_6;
            addEventListener(Event.ENTER_FRAME, this.go);
        }

        private function go(e:Event)
        {
            if (Math.abs(x - this.finalX) < 1 && Math.abs(y - this.finalY) < 1) {
                this.settle();
            } else {
                x = x - (x - this.finalX) * this.pull;
                y = y - (y - this.finalY) * this.pull;
                scaleX = scaleX - (scaleX - 1) * this.pull;
                scaleY = scaleY - (scaleY - 1) * this.pull;
                alpha = alpha - (alpha - 1) * this.pull;
            }
        }

        private function settle()
        {
            x = this.finalX;
            y = this.finalY;
            scaleX = scaleY = 1;
            alpha = 1;
            removeEventListener(Event.ENTER_FRAME, this.go);
            addEventListener(Event.ENTER_FRAME, this.glint);
            var _local_1:Point = new Point(this.finalX, this.finalY);
            this.product.copyPixels(this.src, this.src.rect, _local_1);
            this.src.fillRect(this.src.rect, 0xFFFFFF);
            alpha = 0.25;
        }

        private function glint(e:Event)
        {
            this.glintCounter--;
            if (this.glintCounter > 0) {
                alpha = this.glintCounter / this.glintFrames / 2;
            } else {
                this.remove();
            }
        }

        private function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.glint);
            removeEventListener(Event.ENTER_FRAME, this.go);
            this.src.dispose();
            removeChild(this.bitmap);
            parent.removeChild(this);
        }


    }
}
