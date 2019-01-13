// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//items.Mine

package items
{
    import background.Map;
    import blocks.Block;
    import data.class_28;
    import flash.geom.Point;
    import package_6.Course;
    import package_8.Racer;
    import package_9.MineAppear;

    public class Mine extends Item 
    {

        public function Mine(r:Racer)
        {
            super(r);
        }

        // _loc1 = map
        // _loc2 = playerPos
        // removed _loc3, _loc6 (condensed)
        override public function useItem()
        {
            var map:Map = Course.course.blockBackground;
            var playerPos:Point = method_37();
            playerPos.x = Math.round(playerPos.x + 15);
            playerPos.y = Math.round(playerPos.y + 10);
            if (map.method_24(playerPos.x, playerPos.y, true) == null) { // if block isn't occupied
                var _local_4:Point = map.method_52(playerPos.x, playerPos.y);
                var _local_5:Point = map.method_497(_local_4.x, _local_4.y);
                _local_5.x = _local_5.x + 15;
                _local_5.y = _local_5.y + 15;
                _local_5 = class_28.method_9(_local_5.x, _local_5.y, Course.course.blockBackground.rotation);
                Main.socket.write("add_effect`Mine`" + _local_5.x + "`" + _local_5.y + "`" + Course.course.blockBackground.rotation);
                new MineAppear(_local_5.x, _local_5.y);
                super.useItem();
            }
        }


    }
}//package items

