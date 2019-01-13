// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//pixelEffects.class_21

package pixelEffects
{
    import flash.display.Sprite;
    import flash.display.BitmapData;
    import flash.display.Bitmap;
    import flash.utils.setInterval;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import package_7.class_66;
    import flash.utils.clearInterval;

    public class class_21 extends Sprite 
    {

        private var var_236:BitmapData;
        private var var_315:BitmapData;
        private var var_402:Bitmap;
        private var bgColor:Number;
        private var var_299:Number;
        private var var_267:Number;
        private var var_78:Number;
        private var var_294:Number;
        private var var_416:Number;
        private var var_162:Array;
        private var var_555:uint;

        public function class_21(_arg_1:BitmapData, _arg_2:Number=0, _arg_3:Number=500, _arg_4:Number=0.19, _arg_5:Number=15, _arg_6:Number=15, _arg_7:Number=55)
        {
            this.var_236 = _arg_1;
            this.var_299 = _arg_3;
            this.var_267 = _arg_4;
            this.var_78 = _arg_5;
            this.var_294 = _arg_6;
            this.var_416 = _arg_7;
            this.var_315 = new BitmapData(_arg_1.width, _arg_1.height, false, _arg_2);
            this.var_402 = new Bitmap(this.var_315);
            addChild(this.var_402);
            this.var_162 = this.method_572();
            this.var_555 = setInterval(this.method_549, _arg_7);
        }

        private function method_572():Array
        {
            var _local_3:int;
            var _local_1:Array = new Array();
            var _local_2:int;
            while ((_local_2 * this.var_78) < this.var_236.width) {
                _local_1[_local_2] = new Array();
                _local_3 = 0;
                while ((_local_3 * this.var_78) < this.var_236.height) {
                    _local_1[_local_2][_local_3] = new Point((_local_2 * this.var_78), (_local_3 * this.var_78));
                    _local_3++;
                }
                _local_2++;
            }
            return (_local_1);
        }

        private function method_549()
        {
            this.method_204();
            this.method_204();
            this.method_204();
        }

        private function method_204()
        {
            var _local_1:Number;
            var _local_2:Number;
            var _local_3:Number;
            var _local_4:Number;
            var _local_5:BitmapData;
            var _local_6:Rectangle;
            var _local_7:Point;
            var _local_8:Number;
            var _local_9:Number;
            var _local_10:Number;
            var _local_11:Number;
            var _local_12:class_66;
            if (this.var_162.length > 0) {
                _local_1 = Math.floor((Math.random() * this.var_162.length));
                _local_2 = Math.floor((Math.random() * this.var_162[_local_1].length));
                _local_3 = this.var_162[_local_1][_local_2].x;
                _local_4 = this.var_162[_local_1][_local_2].y;
                this.var_162[_local_1].splice(_local_2, 1);
                if (this.var_162[_local_1].length <= 0) {
                    this.var_162.splice(_local_1, 1);
                }
                _local_5 = new BitmapData(this.var_78, this.var_78, false, this.bgColor);
                _local_6 = new Rectangle(_local_3, _local_4, this.var_78, this.var_78);
                _local_7 = new Point(0, 0);
                _local_5.copyPixels(this.var_236, _local_6, _local_7);
                _local_8 = (((_local_3 + (Math.random() * this.var_299)) - (this.var_299 / 2)) - ((this.var_78 * this.var_294) / 2));
                _local_9 = (((_local_4 + (Math.random() * this.var_299)) - (this.var_299 / 2)) - ((this.var_78 * this.var_294) / 2));
                _local_10 = (Math.random() * this.var_294);
                _local_11 = (Math.random() * this.var_294);
                _local_12 = new class_66(_local_5, this.var_315, _local_8, _local_9, _local_10, _local_11, _local_3, _local_4, this.var_267);
                addChild(_local_12);
            } else {
                this.finishDrawing();
            }
        }

        private function finishDrawing()
        {
            clearInterval(this.var_555);
        }

        private function remove()
        {
            this.var_236.dispose();
            this.var_315.dispose();
            removeChild(this.var_402);
        }


    }
}//package pixelEffects

