// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// ui.LobbyTab = ui.class_248

package ui
{
    import flash.events.MouseEvent;

    public class LobbyTab extends class_7 
    {

        private var m:LobbyTabGraphic = new LobbyTabGraphic();
        private var var_258:class_246;
        private var tabFunction:Function; // var_415 = tabFunction

        public function LobbyTab(tabFn:Function, tabText:String)
        {
            this.tabFunction = tabFn;
            this.m.textBox.text = tabText;
            this.m.textBox.autoSize = "left";
            this.m.bg.width = this.m.textBox.width + 10;
            addChild(this.m);
            this.activate();
        }

        internal function method_671(e:class_246)
        {
            this.var_258 = e;
        }

        private function onClick(e:MouseEvent)
        {
            this.select();
        }

        private function method_224(_arg_1:MouseEvent)
        {
            this.m.bg.gotoAndStop("over");
            this.var_258.method_100(this);
        }

        private function method_246(_arg_1:MouseEvent)
        {
            this.m.bg.gotoAndStop("up");
        }

        public function select()
        {
            this.var_258.select(this);
            this.tabFunction();
            this.deactivate();
            this.m.bg.gotoAndStop("selected");
        }

        public function activate()
        {
            this.deactivate();
            addEventListener(MouseEvent.CLICK, this.onClick);
            addEventListener(MouseEvent.MOUSE_OVER, this.method_224);
            addEventListener(MouseEvent.MOUSE_OUT, this.method_246);
        }

        private function deactivate()
        {
            this.m.bg.gotoAndStop("up");
            removeEventListener(MouseEvent.CLICK, this.onClick);
            removeEventListener(MouseEvent.MOUSE_OVER, this.method_224);
            removeEventListener(MouseEvent.MOUSE_OUT, this.method_246);
        }

        override public function remove()
        {
            this.deactivate();
            removeChild(this.m);
            this.m = null;
            this.var_258 = null;
            this.tabFunction = null;
            super.remove();
        }


    }
}//package ui

