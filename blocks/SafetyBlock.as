// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.SafetyBlock = blocks.class_60

package blocks
{
    import com.jiggmin.data.Objects;
    import flash.geom.Point;
    import character.LocalCharacter;

    public class SafetyBlock extends Block 
    {

        public function SafetyBlock()
        {
            super(Objects.BLOCK_SAFETY);
            safeStand = false;
            active = false;
        }

        override public function onTouch(player:LocalCharacter)
        {
            super.onTouch(player);
            if (!frozen) {
                var _local_2:Point = getSeg();
                if (player.standingSegX != _local_2.x || player.standingSegY < _local_2.y || player.standingSegY > _local_2.y + 2) {
                    player.returnToLastSafeSpot();
                }
            }
        }


    }
}
