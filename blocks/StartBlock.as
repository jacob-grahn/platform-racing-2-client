// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// blocks.StartBlock = class_51

package blocks
{
    public class StartBlock extends Block 
    {

        // _loc3 = block
        public function StartBlock(_arg_1:int, num:int)
        {
            super(_arg_1);
            var block:StartBlockText = new StartBlockText();
            block.textBox.text = num.toString();
            addChild(block);
        }

    }
}
