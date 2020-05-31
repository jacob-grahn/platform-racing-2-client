// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_9.ShotEffect = package_9.class_135

package package_9
{
    import package_6.Course;
    import flash.events.Event;
    import data.class_28;
    import flash.geom.Point;
    import blocks.Block;
    import package_8.Character;
    import package_8.LocalCharacter;

    public class ShotEffect extends Effect 
    {

        private var course:Course;
        private var var_154:Number = 5;
        private var posX:Number;
        private var posY:Number;
        private var velX:Number;
        private var velY:Number;
        private var var_278:Number = 0;
        private var type:String;
        protected var var_377:int;
        protected var life:Number = 100;
        protected var shooterID:int = -1; // var_357; tempID of shooter
        protected var var_493:Boolean = false;

        public function ShotEffect(_arg_1:Number, _arg_2:Number, _arg_3:Number, _arg_4:int, tempID:int, item:String)
        {
            super(_arg_1, _arg_2);
            this.course = Course.course;
            this.posX = _arg_1;
            this.posY = _arg_2;
            this.method_775(_arg_3);
            this.rotation = _arg_3 + (this.course.blockBackground.rotation - _arg_4);
            this.var_377 = _arg_4;
            this.shooterID = tempID;
            this.type = item;
            addEventListener(Event.ENTER_FRAME, this.method_152, false, 0, true);
            this.position();
            this.method_253();
        }

        public function method_62(_arg_1:Number)
        {
            this.var_154 = _arg_1;
            this.method_389();
        }

        public function method_775(_arg_1:Number)
        {
            this.var_278 = _arg_1;
            this.method_389();
        }

        protected function method_152(_arg_1:Event)
        {
            this.move();
            this.position();
            this.method_253();
            this.life--;
            if (this.life <= 0) {
                this.method_601();
            }
        }

        protected function move()
        {
            this.posX = (this.posX + this.velX);
            this.posY = (this.posY + this.velY);
        }

        protected function position()
        {
            var _local_1:Point = class_28.method_9(this.posX, this.posY, -(this.course.blockBackground.rotation - this.var_377));
            x = _local_1.x;
            y = _local_1.y;
        }

        private function method_253()
        {
            var _local_1:Block = this.course.blockBackground.getBlockFromPos(x, y, true);
            if (_local_1 != null && (this.var_493 || _local_1.isActive())) {
                this.hitBlock(_local_1);
            }
            var _local_2:Character = this.method_782(x, y);
            if (_local_2 != null) {
                this.hitPlayer(_local_2);
            }
        }

        
        // _loc4 = c
        protected function method_782(x:int, y:int):Character
        {
            var _local_3:Character;
            for each (var c:Character in this.course.playerArray) {
                if (c.tempID != this.shooterID && c.y > y && c.y < y + 60 && !c.removed) {
                    if ((scaleX == 1 && c.x > x - 60 && c.x < x) || (scaleX == -1 && c.x < x + 60 && c.x > x)) {
                        _local_3 = c;
                        break;
                    }
                }
            }
            return _local_3;
        }

        protected function method_389()
        {
            var _local_1:Number = (this.var_278 * class_74.const_78);
            this.velX = (Math.cos(_local_1) * this.var_154);
            this.velY = (Math.sin(_local_1) * this.var_154);
        }

        protected function hitBlock(_arg_1:Block)
        {
            _arg_1.onDamage(this.velX);
            this.hitAnything();
        }

        protected function hitPlayer(c:Character)
        {
            if (c.type == "local") {
                c.hit(this.velX, this.velY);
            }
            x = c.x - this.velX;
            this.hitAnything();
        }

        protected function hitAnything()
        {
        }

        protected function method_601()
        {
            this.remove();
        }

        override public function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.method_152);
            this.course = null;
            super.remove();
        }


    }
}//package package_9

