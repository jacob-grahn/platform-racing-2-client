

package editor_tools
{
    import blocks.ItemBlock;
    import fl.controls.CheckBox;
    import items.Items;
    import levelEditor.BlockObject;
    import levelEditor.LevelEditor;
    import dialogs.AutoDismissPopup;
    import page.GamePage;

    public class ItemMenu extends AutoDismissPopup 
    {
        private var m:ItemMenuGraphic = new ItemMenuGraphic();
        private var numItems:int = Items.getAllCodes().length; // var_445

        public function ItemMenu(button:ItemMenuButton)
        {
            addChild(this.m);
            super(button);
            var allowedItems:Vector.<int> = GamePage.course.allowedItems;
            var i:int = 1;
            while (i <= this.numItems) {
                var check:CheckBox = this.m["check" + i];
                if (allowedItems.indexOf(i) != -1) {
                    check.selected = true;
                }
                i++;
            }
        }

        override public function remove()
        {
            if (GamePage.course != null) {
                GamePage.course.allowedItems = new Vector.<int>();
                var i:int = 1;
                while (i <= this.numItems) {
                    var check:CheckBox = this.m["check" + i];
                    if (check.selected) {
                        GamePage.course.allowedItems.push(i);
                    }
                    i++;
                }
                if (LevelEditor.editor != null) {
                    var itemBlocks:Array = LevelEditor.editor.blockBG.getAllBlocksOfType(ItemBlock);
                    for each (var block:BlockObject in itemBlocks) {
                        block.m.updateGameItems();
                    }
                }
            }
            super.remove();
        }


    }
}
