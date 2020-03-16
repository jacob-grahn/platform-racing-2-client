// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_19.ItemMenu = package_19.class_265

package package_19
{
    import fl.controls.CheckBox;
    import items.Items;
    import levelEditor.LevelEditor;
    import package_4.class_264;
    import page.GamePage;
    //import __AS3__.vec.Vector;
    //import __AS3__.vec.*;

    public class ItemMenu extends class_264 
    {
        private var m:ItemMenuGraphic = new ItemMenuGraphic();
        private var var_445:int = Items.method_188().length;

        public function ItemMenu(_arg_1:ItemMenuButton)
        {
            ItemMenu.instance = this;

            var _local_3:CheckBox;
            addChild(this.m);
            super(_arg_1);
            var _local_2:Vector.<int> = GamePage.course.var_86;
            var _local_4:int = 1;
            while (_local_4 <= this.var_445) {
                _local_3 = this.m["check" + _local_4];
                if (_local_2.indexOf(_local_4) != -1) {
                    _local_3.selected = true;
                }
                _local_4++;
            }
        }

        override public function remove()
        {
            if (GamePage.course != null) {
                var _local_1:CheckBox;
                GamePage.course.var_86 = new Vector.<int>();
                var _local_2:int = 1;
                while (_local_2 <= this.var_445) {
                    _local_1 = this.m["check" + _local_2];
                    if (_local_1.selected) {
                        GamePage.course.var_86.push(_local_2);
                    }
                    _local_2++;
                }
            }
            super.remove();
        }


    }
}
