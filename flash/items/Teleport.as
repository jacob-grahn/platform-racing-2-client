//items.Teleport

package items
{
    import character.LocalCharacter;
    import gameplay.Course;
    import blocks.Block;
    import effects.TeleportPop;

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
            var teleportDistance:int = this.localChar.scaleX > 0 ? 120 : -120;
            var blockAtDest:Block = Course.course.blockBackground.getBlockFromPos(this.localChar.x + teleportDistance, this.localChar.y - 5, true);
            if (blockAtDest == null || !blockAtDest.isActive()) {
                var popX:int = this.localChar.x;
                var popY:int = this.localChar.y - 25;
                new TeleportPop(popX, popY);
                Main.socket.write("add_effect`Teleport`" + popX + "`" + popY);
                this.localChar.x += teleportDistance;
                popX = this.localChar.x;
                popY = this.localChar.y - 25;
                new TeleportPop(popX, popY);
                Main.socket.write("add_effect`Teleport`" + popX + "`" + popY);
                super.useItem();
            }
        }


    }
}
