// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_19.class_268

package package_19
{
    import package_4.class_264;
    import fl.controls.ComboBox;
    import levelEditor.LevelEditor;
    import flash.events.Event;
    import flash.display.DisplayObject;
    import flash.events.MouseEvent;

    public class class_268 extends class_264 
    {

        private var m:ModeMenuGraphic = new ModeMenuGraphic();
        private var var_63:ComboBox = m.var_131;
        private var open:Boolean = false;

        public function class_268(_arg_1:DisplayObject)
        {
            var _local_2:Object;
            var _local_3:int = this.var_63.length;
            var _local_4:String = LevelEditor.editor.gameMode;
            var _local_5:int;
            while (_local_5 < _local_3) {
                _local_2 = this.var_63.getItemAt(_local_5);
                if (_local_2.data == _local_4) {
                    this.var_63.selectedIndex = _local_5;
                    break;
                }
                _local_5++;
            }
            this.var_63.addEventListener(Event.OPEN, this.method_355, false, 0, true);
            this.var_63.addEventListener(Event.CHANGE, this.method_65, false, 0, true);
            this.var_63.addEventListener(Event.CLOSE, this.method_407, false, 0, true);
            addChild(this.m);
            super(_arg_1);
        }

        private function method_355(_arg_1:Event)
        {
            this.open = true;
        }

        private function method_407(_arg_1:Event)
        {
            this.open = false;
            this.method_65(_arg_1);
        }

        private function method_65(_arg_1:Event)
        {
            var _local_2:String = this.var_63.selectedItem.data;
            LevelEditor.editor.setGameMode(_local_2);
        }

        override protected function downHandler(_arg_1:MouseEvent)
        {
            if (!this.open) {
                super.downHandler(_arg_1);
            }
        }

        override public function remove()
        {
            this.var_63.removeEventListener(Event.OPEN, this.method_355);
            this.var_63.removeEventListener(Event.CHANGE, this.method_65);
            this.var_63.removeEventListener(Event.CLOSE, this.method_407);
            this.var_63 = null;
            Main.stage.focus = Main.stage;
            super.remove();
        }


    }
}//package package_19

