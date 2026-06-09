// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.WaterBlock = blocks.class_43

package blocks
{
    import com.jiggmin.data.Objects;
    import flash.geom.Point;
    import gameplay.Course;
    import character.LocalCharacter;
    import flash.events.Event;

    public class WaterBlock extends Block 
    {

        private var rippleActive:Boolean = false;

        public function WaterBlock()
        {
            super(Objects.BLOCK_WATER);
            safeStand = false;
            active = false;
        }

        override public function onTouch(player:LocalCharacter)
        {
            super.onTouch(player);
            if (!frozen) {
                if (!player.grounded && player.mode != "freeze" && player.mode != "hurt") {
                    player.setMode("water");
                    player.waterTicks = 2;
                } else {
                    player.targetVelX *= 0.9;
                    player.accelFactor = 0.1;
                }
                if (player.parent == Course.course.frontBackground) {
                    Course.course.backBackground.addChild(player);
                }
                var _local_2:Point = getRotatedPos();
                var _local_3:Point = getSeg();
                player.standingSegX = _local_3.x;
                player.standingSegY = _local_3.y;
                player.lastSafeX = _local_2.x + 15;
                player.lastSafeY = _local_2.y + 15;
                this.startRipple();
            }
        }

        public function triggerRipple()
        {
            this.startRipple();
        }

        private function startRipple()
        {
            alpha -= 0.1;
            if (alpha < 0.5) {
                alpha = 0.5;
            }
            if (!this.rippleActive) {
                this.rippleActive = true;
                addEventListener(Event.ENTER_FRAME, this.onRippleFrame, false, 0, true);
            }
        }

        private function onRippleFrame(_arg_1:Event)
        {
            alpha += 0.03;
            if (alpha >= 1) {
                alpha = 1;
                this.rippleActive = false;
                removeEventListener(Event.ENTER_FRAME, this.onRippleFrame);
            }
        }

        override public function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.onRippleFrame);
            super.remove();
        }


    }
}//package blocks
