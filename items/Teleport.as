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

        public function Teleport(p:LocalCharacter)
        {
            super(p);
        }

        // _loc1 = teleportDistance
        override public function useItem()
        {
            var teleportDistance:int = player.scaleX > 0 ? 120 : -120;
            var _local_2:Block = Course.course.blockBackground.getBlockFromPos(player.x + teleportDistance, player.y - 5, true);
            if (_local_2 == null || !_local_2.isActive()) {
                var _local_3:int = player.x;
                var _local_4:int = player.y - 25;
                new TeleportPop(_local_3, _local_4);
                Main.socket.write("add_effect`Teleport`" + _local_3 + "`" + _local_4);
                player.x = player.x + teleportDistance;
                _local_3 = player.x;
                _local_4 = player.y - 25;
                new TeleportPop(_local_3, _local_4);
                Main.socket.write("add_effect`Teleport`" + _local_3 + "`" + _local_4);
                super.useItem();
            }
        }


    }
}//package items

