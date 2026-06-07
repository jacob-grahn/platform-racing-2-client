// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// effects.Slash = effects.class_134

package effects
{
    import package_6.Course;
    import package_8.LocalCharacter;
    import sounds.SoundEffects;
    import com.jiggmin.data.Data;
    import flash.geom.Point;
    import blocks.Block;

    public class Slash extends Effect 
    {

        private var m:SlashAnimation = new SlashAnimation();
        private var course:Course = Course.course;
        private var character:LocalCharacter = Course.course.var_9;
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
            var _local_3:Point = Data.method_9(px, py, this.course.blockBackground.rotation);
            var _local_4:Block = this.course.blockBackground.getBlockFromPos(_local_3.x, _local_3.y);
            if (_local_4 != null && _local_4.isActive()) {
                _local_4.onDamage(this.reach);
            }
            if (this.character != null && this.character.tempID != this.shooterID && this.character.y > py - 14 && this.character.y < py + 74) {
                if (this.character.x > px - 14 && this.character.x < px + 14) {
                    this.character.hit(this.reach, -9);
                }
            }
        }

        override public function remove()
        {
            removeChild(this.m);
            this.course = null;
            this.character = null;
            this.m = null;
            super.remove();
        }


    }
}//package effects

