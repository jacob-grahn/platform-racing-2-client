// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//items.Teleport

package items
{
    import package_8.LocalCharacter;
    import package_6.Course;
    import blocks.Block;
    import package_9.TeleportPop;

    public class Teleport extends Item 
    {

        public function Teleport(r:LocalCharacter)
        {
            super(r);
        }

        // _loc1 = teleportDistance
        override public function useItem()
        {
            var teleportDistance:int = racer.scaleX > 0 ? 120 : -120;
            var _local_2:Block = Course.course.blockBackground.getBlockFromPos(racer.x + teleportDistance, racer.y - 5, true);
            if (_local_2 == null || !_local_2.isActive()) {
                var _local_3:int = racer.x;
                var _local_4:int = racer.y - 25;
                new TeleportPop(_local_3, _local_4);
                Main.socket.write("add_effect`Teleport`" + _local_3 + "`" + _local_4);
                racer.x = racer.x + teleportDistance;
                _local_3 = racer.x;
                _local_4 = racer.y - 25;
                new TeleportPop(_local_3, _local_4);
                Main.socket.write("add_effect`Teleport`" + _local_3 + "`" + _local_4);
                super.useItem();
            }
        }


    }
}//package items

