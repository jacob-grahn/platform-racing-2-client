// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_7.class_66

package package_7
{
    import flash.display.Sprite;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.events.Event;
    import flash.geom.Point;

    public class class_66 extends Sprite 
    {

        private var bitmap:Bitmap;
        private var var_236:BitmapData;
        private var var_315:BitmapData;
        private var var_291:Number;
        private var var_328:Number;
        private var var_267:Number;
        private var var_547:int = 20;
        private var var_318:Number = var_547;

        public function class_66(_arg_1:BitmapData, _arg_2:BitmapData, _arg_3:Number, _arg_4:Number, _arg_5:Number, _arg_6:Number, _arg_7:Number, _arg_8:Number, _arg_9:Number)
        {
            this.var_291 = _arg_7;
            this.var_328 = _arg_8;
            this.var_267 = _arg_9;
            this.var_236 = _arg_1;
            this.var_315 = _arg_2;
            alpha = 0;
            this.bitmap = new Bitmap(_arg_1);
            addChild(this.bitmap);
            x = _arg_3;
            y = _arg_4;
            scaleX = _arg_5;
            scaleY = _arg_6;
            addEventListener(Event.ENTER_FRAME, this.go);
        }

        private function go(_arg_1:Event)
        {
            if (((Math.abs((x - this.var_291)) < 1) && (Math.abs((y - this.var_328)) < 1))) {
                this.method_582();
            } else {
                x = (x - ((x - this.var_291) * this.var_267));
                y = (y - ((y - this.var_328) * this.var_267));
                scaleX = (scaleX - ((scaleX - 1) * this.var_267));
                scaleY = (scaleY - ((scaleY - 1) * this.var_267));
                alpha = (alpha - ((alpha - 1) * this.var_267));
            }
        }

        private function method_582()
        {
            x = this.var_291;
            y = this.var_328;
            scaleX = (scaleY = 1);
            alpha = 1;
            removeEventListener(Event.ENTER_FRAME, this.go);
            addEventListener(Event.ENTER_FRAME, this.method_435);
            var _local_1:Point = new Point(this.var_291, this.var_328);
            this.var_315.copyPixels(this.var_236, this.var_236.rect, _local_1);
            this.var_236.fillRect(this.var_236.rect, 0xFFFFFF);
            alpha = 0.25;
        }

        private function method_435(_arg_1:Event)
        {
            this.var_318--;
            if (this.var_318 > 0) {
                alpha = ((this.var_318 / this.var_547) / 2);
            } else {
                this.remove();
            }
        }

        private function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.method_435);
            removeEventListener(Event.ENTER_FRAME, this.go);
            this.var_236.dispose();
            removeChild(this.bitmap);
            parent.removeChild(this);
        }


    }
}//package package_7

