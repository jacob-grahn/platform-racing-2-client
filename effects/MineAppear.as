// effects.MineAppear = effects.class_141

package effects
{
    import gameplay.Course;
    import com.jiggmin.data.Data;
    import flash.geom.Point;
    import sounds.SoundEffects;
    import com.jiggmin.data.Objects;

    public class MineAppear extends Effect 
    {

        private var m:MineAppearAnimation = new MineAppearAnimation();

        public function MineAppear(x:Number, y:Number)
        {
            rotation = Course.course.blockBackground.rotation;
            var point:Point = Data.rotatePoint(x, y, -rotation);
            super(point.x, point.y);
            addChild(this.m);
            scheduleRemove(33);
            SoundEffects.playGameSound(new MineAppearSound(), point.x, point.y);
        }

        override public function remove()
        {
            if (Course.course != null) {
                var target:Point = Data.rotatePoint(x, y, Course.course.blockBackground.rotation);
                if (Course.course.blockBackground.getBlockFromPos(target.x, target.y) == null) {
                    Course.course.blockBackground.placeBlock(Objects.BLOCK_MINE, target.x, target.y);
                }
            }
            this.m = null;
            super.remove();
        }


    }
}
