// package_9.MineAppear = package_9.class_141

package package_9
{
    import package_6.Course;
    import com.jiggmin.data.Data;
    import flash.geom.Point;
    import sounds.SoundEffects;
    import com.jiggmin.data.Objects;

    public class MineAppear extends Effect 
    {

        private var m:MineAppearAnimation = new MineAppearAnimation();

        // _loc3 = point
        public function MineAppear(x:Number, y:Number)
        {
            rotation = Course.course.blockBackground.rotation;
            var point:Point = Data.method_9(x, y, -rotation);
            super(point.x, point.y);
            addChild(this.m);
            method_2(33);
            SoundEffects.playGameSound(new MineAppearSound(), point.x, point.y);
        }

        // _loc1 = target
        override public function remove()
        {
            if (Course.course != null) {
                var target:Point = Data.method_9(x, y, Course.course.blockBackground.rotation);
                if (Course.course.blockBackground.getBlockFromPos(target.x, target.y) == null) {
                    Course.course.blockBackground.placeBlock(Objects.BLOCK_MINE, target.x, target.y);
                }
            }
            this.m = null;
            super.remove();
        }


    }
}
