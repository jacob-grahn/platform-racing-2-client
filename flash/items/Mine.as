//items.Mine

package items
{
    import background.Map;
    import blocks.Block;
    import com.jiggmin.data.Data;
    import flash.geom.Point;
    import gameplay.Course;
    import character.LocalCharacter;
    import effects.MineAppear;

    public class Mine extends Item 
    {

        public function Mine(lc:LocalCharacter)
        {
            super(lc);
        }

        // removed _loc3, _loc6 (condensed)
        override public function useItem()
        {
            var map:Map = Course.course.blockBackground;
            var playerPos:Point = getWeaponEffectPos();
            playerPos.x = Math.round(playerPos.x + 15);
            playerPos.y = Math.round(playerPos.y + 10);
            if (map.getBlockFromPos(playerPos.x, playerPos.y, true) == null) { // if block isn't occupied
                var _local_4:Point = map.getSegFromPos(playerPos.x, playerPos.y);
                var _local_5:Point = map.getPosFromSeg(_local_4.x, _local_4.y);
                _local_5.x = _local_5.x + 15;
                _local_5.y = _local_5.y + 15;
                _local_5 = Data.rotatePoint(_local_5.x, _local_5.y, Course.course.blockBackground.rotation);
                Main.socket.write("add_effect`Mine`" + _local_5.x + "`" + _local_5.y + "`" + Course.course.blockBackground.rotation);
                new MineAppear(_local_5.x, _local_5.y);
                super.useItem();
            }
        }


    }
}//package items

