// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_9.class_81

package package_9
{
    import flash.events.Event;
    import flash.geom.Point;
    import blocks.Block;
    import package_6.Course;
    import data.class_28;
    import package_8.LocalCharacter;

    public class class_81 extends Effect 
    {

        protected var velX:Number = 0;
        protected var velY:Number = 0;
        public var posX:Number;
        public var posY:Number;
        public var rot:int;
        private var time:Number;
        private var var_681:Number;
        private var var_683:Number;
        private var var_42:Boolean = false;

        public function class_81(_arg_1:int, _arg_2:int, _arg_3:int)
        {
            this.posX = _arg_1;
            this.posY = _arg_2;
            this.rot = _arg_3;
            this.method_720();
        }

        public function method_720()
        {
            addEventListener(Event.ENTER_FRAME, this.go, false, 0, true);
        }

        public function method_205()
        {
            removeEventListener(Event.ENTER_FRAME, this.go);
        }

        protected function go(_arg_1:Event)
        {
            var _local_2:Point;
            var _local_3:Block;
            var _local_4:Point;
            var _local_5:Point;
            this.velY = (this.velY + 0.2);
            if (this.velY > 8) {
                this.velY = 8;
            }
            this.posY = (this.posY + this.velY);
            this.posX = (this.posX + this.velX);
            rotation = (Course.course.blockBackground.rotation - this.rot);
            _local_2 = class_28.method_9(this.posX, this.posY, -(rotation));
            if (this.velX != 0) {
                _local_5 = class_28.method_9((this.posX + this.velX), (this.posY - 10), -(rotation));
                _local_3 = Course.course.blockBackground.method_24(_local_5.x, _local_5.y, true);
                if (((!(_local_3 == null)) && (_local_3.method_23()))) {
                    _local_4 = _local_3.method_18(this.rot);
                    if (this.velX < 0) {
                        this.posX = (_local_4.x + 31);
                    } else {
                        this.posX = (_local_4.x - 1);
                    }
                    this.onTouchWall();
                }
            }
            _local_3 = Course.course.blockBackground.method_24(_local_2.x, _local_2.y, true);
            if (((!(_local_3 == null)) && (_local_3.method_23()))) {
                this.var_42 = true;
                _local_4 = _local_3.method_18(this.rot);
                if (this.velY < 0) {
                    this.velY = (this.velY * -0.5);
                    this.posY = (_local_4.y + 31);
                } else {
                    this.velY = 0;
                    this.posY = _local_4.y;
                }
            } else {
                this.var_42 = false;
            }
            if (this.method_181(x, y)) {
                this.onTouchLocalPlayer();
            }
            _local_2 = class_28.method_9(this.posX, this.posY, -(rotation));
            x = _local_2.x;
            y = _local_2.y;
        }

        protected function method_181(_arg_1:int, _arg_2:int):Boolean
        {
            var _local_3:Boolean;
            var _local_4:LocalCharacter = Course.course.var_9;
            if (((!(_local_4 == null)) && (!(_local_4.removed)))) {
                if ((((Math.abs((_local_4.x - _arg_1)) < 25) && (_local_4.y > (_arg_2 - 5))) && (((!(_local_4.crouching)) && (_local_4.y < (_arg_2 + 65))) || ((_local_4.crouching) && (_local_4.y < (_arg_2 + 25)))))) {
                    _local_3 = true;
                }
            }
            return (_local_3);
        }

        protected function onTouchLocalPlayer()
        {
        }

        protected function onTouchWall()
        {
        }

        public function method_311():Boolean
        {
            return (this.var_42);
        }

        override public function remove()
        {
            this.method_205();
            super.remove();
        }


    }
}//package package_9

