// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.SafetyBlock = blocks.class_60

package blocks
{
    import com.jiggmin.data.Objects;
    import flash.geom.Point;
    import package_8.LocalPlayer;

    public class SafetyBlock extends Block 
    {

        public function SafetyBlock()
        {
            super(Objects.BLOCK_SAFETY);
            var_34 = false;
            active = false;
        }

        override public function onTouch(player:LocalPlayer)
        {
            super.onTouch(player);
            if (!frozen) {
                var _local_2:Point = getSeg();
                if (player.var_407 != _local_2.x || player.var_366 < _local_2.y || player.var_366 > _local_2.y + 2) {
                    player.method_216();
                }
            }
        }


    }
}
