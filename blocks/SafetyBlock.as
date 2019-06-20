// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.SafetyBlock = blocks.class_60

package blocks
{
    import data.Objects;
    import flash.geom.Point;
    import package_8.LocalCharacter;

    public class SafetyBlock extends Block 
    {

        public function SafetyBlock()
        {
            super(Objects.SafetyBlockCode);
            var_34 = false;
            var_71 = false;
        }

        override public function onTouch(_arg_1:LocalCharacter)
        {
            var _local_2:Point;
            super.onTouch(_arg_1);
            if (!var_37) {
                _local_2 = getSeg();
                if (_arg_1.var_407 != _local_2.x || _arg_1.var_366 < _local_2.y || _arg_1.var_366 > (_local_2.y + 2)) {
                    _arg_1.method_216();
                }
            }
        }


    }
}
