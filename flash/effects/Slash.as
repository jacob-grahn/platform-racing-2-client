// effects.Slash = effects.class_134

package effects
{
    import gameplay.Course;
    import character.LocalCharacter;
    import sounds.SoundEffects;
    import com.jiggmin.data.Data;
    import flash.geom.Point;
    import blocks.Block;

    public class Slash extends Effect 
    {

        private var m:SlashAnimation = new SlashAnimation();
        private var course:Course = Course.course;
        private var localPlayer:LocalCharacter = Course.course.localPlayer;
        private var reach:int = 29;
        private var shooterID:int;

        public function Slash(startX:int, startY:int, dir:String, tempID:int)
        {
            this.shooterID = tempID;
            super(startX, startY);
            addChild(this.m);
            scheduleRemove(6);
            if (dir == "left") {
                this.reach = -29;
                scaleX = -1;
            }
            this.hitAt(x, y - 14);
            this.hitAt(x, y + 14);
            this.hitAt(x + this.reach, y - 14);
            this.hitAt(x + this.reach, y + 14);
            this.hitAt(x + this.reach * 2, y - 14);
            this.hitAt(x + this.reach * 2, y + 14);
            SoundEffects.playGameSound(new SwishSound(), startX, startY);
        }

        private function hitAt(px:int, py:int)
        {
            var _local_3:Point = Data.rotatePoint(px, py, this.course.blockBackground.rotation);
            var _local_4:Block = this.course.blockBackground.getBlockFromPos(_local_3.x, _local_3.y);
            if (_local_4 != null && _local_4.isActive()) {
                _local_4.onDamage(this.reach);
            }
            if (this.localPlayer != null && this.localPlayer.tempID != this.shooterID && this.localPlayer.y > py - 14 && this.localPlayer.y < py + 74) {
                if (this.localPlayer.x > px - 14 && this.localPlayer.x < px + 14) {
                    this.localPlayer.hit(this.reach, -9);
                }
            }
        }

        override public function remove()
        {
            removeChild(this.m);
            this.course = null;
            this.localPlayer = null;
            this.m = null;
            super.remove();
        }


    }
}//package effects

