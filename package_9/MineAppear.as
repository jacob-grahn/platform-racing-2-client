// package_9.MineAppear = package_9.class_141

package package_9
{
    import package_6.Course;
    import data.class_28;
    import flash.geom.Point;
    import sounds.SoundEffects;
    import data.Objects;

    public class MineAppear extends Effect 
    {

        private var m:MineAppearAnimation = new MineAppearAnimation();

        // _loc3 = point
        public function MineAppear(x:Number, y:Number)
        {
            rotation = Course.course.blockBackground.rotation;
            var point:Point = class_28.method_9(x, y, -rotation);
            super(point.x, point.y);
            addChild(this.m);
            method_2(33);
            SoundEffects.playGameSound(new MineAppearSound(), point.x, point.y);
        }

        override public function remove()
        {
            if (Course.course != null) {
                var _local_1:Point = class_28.method_9(x, y, Course.course.blockBackground.rotation);
                if (Course.course.blockBackground.method_24(_local_1.x, _local_1.y) == null) {
                    Course.course.blockBackground.placeBlock(Objects.MineBlockCode, _local_1.x, _local_1.y);
                }
            }
            this.m = null;
            super.remove();
        }


    }
}
