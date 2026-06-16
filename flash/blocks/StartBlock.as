// blocks.StartBlock = class_51

package blocks
{
    public class StartBlock extends Block 
    {

        // _loc3 = blockText
        public function StartBlock(blockId:int, num:int)
        {
            super(blockId);
            var blockText:StartBlockText = new StartBlockText();
            blockText.textBox.text = num.toString();
            addChild(blockText);
        }

    }
}
