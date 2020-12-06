// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.IceBlock = blocks.class_44

package blocks
{
    import com.jiggmin.data.Objects;
    import package_8.LocalCharacter;

    public class IceBlock extends Block 
    {

        public function IceBlock()
        {
            super(Objects.IceBlockCode);
        }

        override public function onStand(_arg_1:LocalCharacter)
        {
            super.onStand(_arg_1);
            _arg_1.var_147 = 0.05;
        }


    }
}//package blocks

