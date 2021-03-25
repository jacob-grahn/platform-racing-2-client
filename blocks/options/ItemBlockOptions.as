package blocks.options
{
    import blocks.Block;
    import fl.controls.CheckBox;
    import items.Items;
    import page.GamePage;

    public class ItemBlockOptions extends BlockOptions
    {
        
        private const NUM_ITEMS:int = Items.getAllCodes().length;

        public function ItemBlockOptions(block:Block)
        {
            m = new ItemBlockOptionsGraphic();
            super(block);
            var allowedItems:Vector.<int> = new Vector.<int>;
            if (block.options == '') {
                allowedItems = GamePage.course.allowedItems;
            } else if (block.options != 'none') {
                allowedItems = Vector.<int>(block.options.split('-'));
            }
            var itemId:int = 1;
            while (itemId <= this.NUM_ITEMS) {
                var itemChk:CheckBox = this.m["check" + itemId];
                itemChk.selected = allowedItems.indexOf(itemId) != -1;
                itemId++;
            }
        }

        override public function remove()
        {
            var allowedItems:Vector.<int> = new Vector.<int>;
            var itemId:int = 1;
            while (itemId <= this.NUM_ITEMS) {
                var itemChk:CheckBox = this.m["check" + itemId];
                if (itemChk.selected) {
                    allowedItems.push(itemId);
                }
                itemId++;
            }
            block.applyOptions(allowedItems.length > 0 ? allowedItems.join('-') : 'none');
            super.remove();
        }
    }
}
