// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

package effects
{
    import blocks.Block;
    import com.jiggmin.data.Data;
    import flash.events.Event;
    import flash.geom.Point;
    import package_6.Course;
    import package_8.Character;
    import package_8.LocalCharacter;

    public class ShotEffect extends Effect
    {

        private var course:Course;
        private var speed:Number = 5;
        private var posX:Number;
        private var posY:Number;
        private var velX:Number;
        private var velY:Number;
        private var angle:Number = 0;
        private var type:String;
        protected var rot:int;
        protected var life:Number = 100;
        protected var shooterID:int = -1;
        protected var hitInactiveBlocks:Boolean = false;

        public function ShotEffect(startX:Number, startY:Number, startAngle:Number, startRot:int, tempID:int, item:String)
        {
            super(startX, startY);
            this.course = Course.course;
            this.posX = startX;
            this.posY = startY;
            this.setAngle(startAngle);
            this.rotation = startAngle + this.course.blockBackground.rotation - startRot;
            this.rot = startRot;
            this.shooterID = tempID;
            this.type = item;
            addEventListener(Event.ENTER_FRAME, this.onEnterFrame, false, 0, true);
            this.position();
            this.checkCollisions();
        }

        public function setSpeed(s:Number)
        {
            this.speed = s;
            this.updateVelocity();
        }

        public function setAngle(a:Number)
        {
            this.angle = a;
            this.updateVelocity();
        }

        protected function onEnterFrame(e:Event)
        {
            this.move();
            this.position();
            this.checkCollisions();
            this.life--;
            if (this.life <= 0) {
                this.onLifeEnd();
            }
        }

        protected function move()
        {
            this.posX += this.velX;
            this.posY += this.velY;
        }

        protected function position()
        {
            var pos:Point = Data.method_9(this.posX, this.posY, -(this.course.blockBackground.rotation - this.rot));
            x = pos.x;
            y = pos.y;
        }

        private function checkCollisions()
        {
            var _local_1:Block = this.course.blockBackground.getBlockFromPos(x, y, true);
            if (_local_1 != null && (this.hitInactiveBlocks || _local_1.isActive())) {
                this.hitBlock(_local_1);
            }
            var _local_2:Character = this.getPlayerAt(x, y);
            if (_local_2 != null) {
                this.hitPlayer(_local_2);
            }
        }

        protected function getPlayerAt(px:int, py:int):Character
        {
            for each (var p:Character in this.course.playerArray) {
                if (p.tempID != this.shooterID && p.y > py && p.y < py + 60 && !p.removed) {
                    if ((scaleX == 1 && p.x > px - 60 && p.x < px) || (scaleX == -1 && p.x < px + 60 && p.x > px)) {
                        return p;
                    }
                }
            }
            return null;
        }

        protected function updateVelocity()
        {
            var _local_1:Number = this.angle * Data.DEG_RAD;
            this.velX = Math.cos(_local_1) * this.speed;
            this.velY = Math.sin(_local_1) * this.speed;
        }

        protected function hitBlock(_arg_1:Block)
        {
            _arg_1.onDamage(this.velX);
            this.hitAnything();
        }

        protected function hitPlayer(player:Character)
        {
            if (player.type == "local") {
                player.hit(this.velX, this.velY);
            }
            x = player.x - this.velX;
            this.hitAnything();
        }

        protected function hitAnything()
        {
        }

        protected function onLifeEnd()
        {
            this.remove();
        }

        override public function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.onEnterFrame);
            this.course = null;
            super.remove();
        }


    }
}//package effects
