// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_9.class_81

package package_9
{
    import flash.events.Event;
    import flash.geom.Point;
    import blocks.Block;
    import package_6.Course;
    import com.jiggmin.data.Data;
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
        private var grounded:Boolean = false; // var_42

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
            var _local_3:Block;
            var _local_4:Point;
            this.velY += 0.2;
            if (this.velY > 8) {
                this.velY = 8;
            }
            this.posY += this.velY;
            this.posX += this.velX;
            rotation = Course.course.blockBackground.rotation - this.rot;
            var _local_2:Point = Data.method_9(this.posX, this.posY, -rotation);
            if (this.velX != 0) {
                var _local_5:Point = Data.method_9(this.posX + this.velX, this.posY - 10, -rotation);
                _local_3 = Course.course.blockBackground.getBlockFromPos(_local_5.x, _local_5.y, true);
                if (_local_3 != null && _local_3.isActive()) {
                    _local_4 = _local_3.method_18(this.rot);
                    if (this.velX < 0) {
                        this.posX = _local_4.x + 31;
                    } else {
                        this.posX = _local_4.x - 1;
                    }
                    this.onTouchWall();
                }
            }
            _local_3 = Course.course.blockBackground.getBlockFromPos(_local_2.x, _local_2.y, true);
            if (_local_3 != null && _local_3.isActive()) {
                this.grounded = true;
                _local_4 = _local_3.method_18(this.rot);
                if (this.velY < 0) {
                    this.velY *= -0.5;
                    this.posY = _local_4.y + 31;
                } else {
                    this.velY = 0;
                    this.posY = _local_4.y;
                }
            } else {
                this.grounded = false;
            }
            if (this.method_181(x, y)) {
                this.onTouchLocalPlayer();
            }
            _local_2 = Data.method_9(this.posX, this.posY, -rotation);
            x = _local_2.x;
            y = _local_2.y;
        }

        // deleted _loc3 (return boolean)
        // _loc4 = p
        protected function method_181(_arg_1:int, _arg_2:int):Boolean
        {
            var p:LocalCharacter = Course.course.var_9;
            if (p != null && !p.removed) {
                if (Math.abs(p.x - _arg_1) < 25 && p.y > _arg_2 - 5 && ((!p.crouching && p.y < _arg_2 + 65) || (p.crouching && p.y < _arg_2 + 25))) {
                    return true;
                }
            }
            return false;
        }

        protected function onTouchLocalPlayer()
        {
        }

        protected function onTouchWall()
        {
        }

        public function method_311():Boolean
        {
            return this.grounded;
        }

        override public function remove()
        {
            this.method_205();
            super.remove();
        }


    }
}//package package_9

