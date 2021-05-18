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
        // _loc2 = blockAtDest
        // _loc3 = popX
        // _loc4 = popY
        override public function useItem()
        {
            var teleportDistance:int = character.scaleX > 0 ? 120 : -120;
            var blockAtDest:Block = Course.course.blockBackground.getBlockFromPos(character.x + teleportDistance, character.y - 5, true);
            if (blockAtDest == null || !blockAtDest.isActive()) {
                var popX:int = character.x;
                var popY:int = character.y - 25;
                new TeleportPop(popX, popY);
                Main.socket.write("add_effect`Teleport`" + popX + "`" + popY);
                character.x += teleportDistance;
                popX = character.x;
                popY = character.y - 25;
                new TeleportPop(popX, popY);
                Main.socket.write("add_effect`Teleport`" + popX + "`" + popY);
                super.useItem();
            }
        }


    }
}
