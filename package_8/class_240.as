// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_8.class_240

package package_8
{
    import flash.display.Sprite;
    import flash.events.Event;
    import com.jiggmin.data.Data;
    import flash.geom.ColorTransform;
    import flash.display.DisplayObject;

    public class class_240 extends Sprite 
    {

        private var velX:Number;
        private var velY:Number;
        private var fricX:Number;
        private var fricY:Number;
        private var accelX:Number;
        private var accelY:Number;
        private var var_578:int;
        private var life:int;
        private var targetAlpha:Number;
        private var var_275:Number;
        private var velAlpha:Number;
        private var velScaleX:Number;
        private var velScaleY:Number;
        private var velRotation:Number;

        public function class_240(_arg_1:Object)
        {
            this.setColor(_arg_1.colors);
            _arg_1.x = this.method_38(_arg_1.minX, _arg_1.maxX);
            _arg_1.y = this.method_38(_arg_1.minY, _arg_1.maxY);
            _arg_1.velX = this.method_38(_arg_1.minVelX, _arg_1.maxVelX);
            _arg_1.velY = this.method_38(_arg_1.minVelY, _arg_1.maxVelY);
            _arg_1.velAlpha = this.method_38(_arg_1.minVelAlpha, _arg_1.maxVelAlpha);
            _arg_1.velRotation = this.method_38(_arg_1.minVelRotation, _arg_1.maxVelRotation);
            _arg_1.scale = this.method_38(_arg_1.minScale, _arg_1.maxScale);
            _arg_1.rotation = this.method_38(_arg_1.minRotation, _arg_1.maxRotation);
            x = ((_arg_1.x) || (0));
            y = ((_arg_1.y) || (0));
            rotation = ((_arg_1.rotation) || (0));
            scaleX = (scaleY = ((_arg_1.scale) || (0)));
            this.velX = ((_arg_1.velX) || (0));
            this.velY = ((_arg_1.velY) || (0));
            this.fricX = ((_arg_1.fricX) || (1));
            this.fricY = ((_arg_1.fricY) || (1));
            this.accelX = ((_arg_1.accelX) || (0));
            this.accelY = ((_arg_1.accelY) || (0));
            this.life = (this.var_578 = ((_arg_1.life) || (10)));
            this.targetAlpha = ((_arg_1.targetAlpha) || (1));
            this.var_275 = (alpha = ((_arg_1.startAlpha) || (0)));
            this.velAlpha = ((_arg_1.velAlpha) || (0.1));
            this.velScaleX = ((_arg_1.velScaleX) || (0));
            this.velScaleY = ((_arg_1.velScaleY) || (0));
            this.velRotation = ((_arg_1.velRotation) || (0));
            addChild(this.method_508(_arg_1.graphic));
            addEventListener(Event.ENTER_FRAME, this.method_251);
        }

        public function setColor(_arg_1:Array)
        {
            var _local_2:Number = Data.randArrayKey(_arg_1);
            var _local_3:ColorTransform = new ColorTransform();
            _local_3.color = _local_2;
            transform.colorTransform = _local_3;
        }

        public function method_508(_arg_1:String):DisplayObject
        {
            var _local_2:DisplayObject;
            if (_arg_1 == "DjinnIceGraphic") {
                _local_2 = new DjinnIceGraphic();
            }
            return (_local_2);
        }

        private function method_38(_arg_1:Number, _arg_2:Number):Number
        {
            if (((isNaN(_arg_1)) || (isNaN(_arg_2)))) {
                return (0);
            }
            var _local_3:Number = (_arg_2 - _arg_1);
            var _local_4:Number = ((Math.random() * _local_3) + _arg_1);
            return (_local_4);
        }

        private function method_251(_arg_1:Event)
        {
            x = (x + this.velX);
            y = (y + this.velY);
            this.velX = (this.velX + this.accelX);
            this.velY = (this.velY + this.accelY);
            this.velX = (this.velX * this.fricX);
            this.velY = (this.velY * this.fricY);
            scaleX = (scaleX + this.velScaleX);
            scaleY = (scaleY + this.velScaleY);
            rotation = (rotation + this.velRotation);
            this.var_275 = (this.var_275 + this.velAlpha);
            if (this.var_275 > 1) {
                this.var_275 = 1;
            }
            alpha = (this.var_275 * (this.life / this.var_578));
            this.life--;
            if (this.life <= 0) {
                this.remove();
            }
        }

        public function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.method_251);
            if (parent) {
                parent.removeChild(this);
            }
        }


    }
}//package package_8

