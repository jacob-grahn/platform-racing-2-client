package dialogs
{
    import fl.controls.CheckBox;
    import items.Items;
    import flash.display.DisplayObject;

    public class ItemMenu extends InfoPopup 
    {
        private var m:ItemMenuGraphic = new ItemMenuGraphic();
        private var numItems:int = Items.getAllCodes().length;

        public function ItemMenu(itemsStr:String, d:DisplayObject)
        {
            this.parseItems(itemsStr);
            for (var i = 1; i <= numItems; i++) {
                this.m["check" + i].enabled = false;
            }
            addChild(this.m);
            super(d);
        }

        private function parseItems(itemsStr:String)
        {
            var itemsArr:Vector.<int>;
            if (itemsStr == "") {
                itemsArr = new Vector.<int>();
            } else if (itemsStr == "all" || itemsStr == null) {
                itemsArr = Items.getAllCodes();
            } else {
                itemsArr = new Vector.<int>();
                var itemNames:Array = itemsStr.split("`");
                for (var i = 0; i < itemNames.length; i++) {
                    var itemName:String = itemNames[i];
                    var itemCode:int;
                    if (itemName.length > 1) {
                        itemCode = Items.getCodeFromName(itemName);
                    } else {
                        itemCode = Number(itemName);
                    }
                    if (!isNaN(itemCode) && itemCode >= 1 && itemCode <= Items.getAllCodes().length) {
                        this.m["check" + itemCode].selected = true;
                    }
                }
            }
        }

        override public function remove()
        {
            super.remove();
        }


    }
}
