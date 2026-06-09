// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// effects.class_106 = effects.BlockPiece

package effects
{
    import flash.events.Event;
    import flash.display.DisplayObject;

    public class BlockPiece extends Effect 
    {

        private var velX:Number;
        private var velY:Number;
        private var rotVel:Number;
        private var gravity:Number;
        private var friction:Number;
        private var fadeRate:Number;

        public function BlockPiece(child:DisplayObject, gravity:Number=1, friction:Number=0.95, fadeRate:Number=0.01, spreadX:Number=10, spreadY:Number=10, spreadRot:Number=10, startX:Number=0, startY:Number=0)
        {
            addChild(child);
            x = startX;
            y = startY;
            this.gravity = gravity;
            this.friction = friction;
            this.fadeRate = fadeRate;
            rotation = Math.random() * 360;
            this.velX = (Math.random() * spreadX * 2) - spreadX;
            this.velY = (Math.random() * spreadY * 2) - spreadY;
            this.rotVel = (Math.random() * spreadRot * 2) - spreadRot;
            addEventListener(Event.ENTER_FRAME, this.go, false, 0, true);
        }

        private function go(e:Event)
        {
            this.velX *= this.friction;
            this.velY *= this.friction;
            this.rotVel *= this.friction;
            this.velY += this.gravity;
            x += this.velX;
            y += this.velY;
            rotation += this.rotVel;
            alpha -= this.fadeRate;
            if (alpha <= 0) {
                this.remove();
            }
        }

        override public function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.go);
            super.remove();
        }


    }
}//package effects

