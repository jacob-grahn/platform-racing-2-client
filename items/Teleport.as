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

        public function Teleport(lc:LocalCharacter)
        {
            super(lc);
        }

        // _loc1 = teleportDistance
        override public function useItem()
        {
            var teleportDistance:int = character.scaleX > 0 ? 120 : -120;
            var _local_2:Block = Course.course.blockBackground.getBlockFromPos(character.x + teleportDistance, character.y - 5, true);
            if (_local_2 == null || !_local_2.isActive()) {
                var _local_3:int = character.x;
                var _local_4:int = character.y - 25;
                new TeleportPop(_local_3, _local_4);
                Main.socket.write("add_effect`Teleport`" + _local_3 + "`" + _local_4);
                character.x = character.x + teleportDistance;
                _local_3 = character.x;
                _local_4 = character.y - 25;
                new TeleportPop(_local_3, _local_4);
                Main.socket.write("add_effect`Teleport`" + _local_3 + "`" + _local_4);
                super.useItem();
            }
        }


    }
}//package items

