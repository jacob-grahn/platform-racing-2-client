

package editor_tools
{
    import package_4.class_264;
    import fl.controls.ComboBox;
    import levelEditor.LevelEditor;
    import flash.events.Event;
    import flash.display.DisplayObject;
    import flash.events.MouseEvent;

    public class ModeMenu extends class_264 
    {

        private var m:ModeMenuGraphic = new ModeMenuGraphic();
        private var modeSelect:ComboBox = m.modeSelect; // var_63
        private var open:Boolean = false;

        // _loc2 = mode
        // _loc3 = this.modeSelect.length
        // _loc4 = LevelEditor.editor.gameMode
        // _loc5 = i
        public function ModeMenu(d:DisplayObject)
        {
            var i:int = 0;
            while (i < this.modeSelect.length) {
                var mode:Object = this.modeSelect.getItemAt(i);
                if (mode.data == LevelEditor.editor.gameMode) {
                    this.modeSelect.selectedIndex = i;
                    break;
                }
                i++;
            }
            this.modeSelect.addEventListener(Event.OPEN, this.onOpen, false, 0, true);
            this.modeSelect.addEventListener(Event.CHANGE, this.onChange, false, 0, true);
            this.modeSelect.addEventListener(Event.CLOSE, this.onClose, false, 0, true);
            addChild(this.m);
            super(d);
        }

        // method_355 = onOpen
        private function onOpen(e:Event)
        {
            this.open = true;
        }

        // method_407 = onClose
        private function onClose(e:Event)
        {
            this.open = false;
            this.onChange(e);
        }

        // _loc2 = this.modeSelect.selectedItem.data
        // method_65 = onChange
        private function onChange(e:Event)
        {
            LevelEditor.editor.setGameMode(this.modeSelect.selectedItem.data);
        }

        override protected function downHandler(e:MouseEvent)
        {
            if (!this.open) {
                super.downHandler(e);
            }
        }

        override public function remove()
        {
            this.modeSelect.removeEventListener(Event.OPEN, this.onOpen);
            this.modeSelect.removeEventListener(Event.CHANGE, this.onChange);
            this.modeSelect.removeEventListener(Event.CLOSE, this.onClose);
            this.modeSelect = null;
            Main.stage.focus = Main.stage;
            super.remove();
        }


    }
}

