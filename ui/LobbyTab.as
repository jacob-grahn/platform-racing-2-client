// ui.LobbyTab = ui.class_248

package ui
{
    import flash.events.MouseEvent;

    public class LobbyTab extends Removable 
    {

        private var m:LobbyTabGraphic = new LobbyTabGraphic();
        private var tabsHolder:TabsHolder;
        private var tabFunction:Function;

        public function LobbyTab(tabFn:Function, tabText:String)
        {
            this.tabFunction = tabFn;
            this.m.textBox.text = tabText;
            this.m.textBox.autoSize = "left";
            this.m.bg.width = this.m.textBox.width + 10;
            addChild(this.m);
            this.activate();
        }

        internal function setTabsHolder(h:TabsHolder)
        {
            this.tabsHolder = h;
        }

        private function onClick(e:MouseEvent)
        {
            this.select();
        }

        private function onHover(e:MouseEvent)
        {
            this.m.bg.gotoAndStop("over");
            this.tabsHolder.moveToFront(this);
        }

        private function onHoverOut(e:MouseEvent)
        {
            this.m.bg.gotoAndStop("up");
        }

        public function select()
        {
            this.tabsHolder.select(this);
            this.tabFunction();
            this.deactivate();
            this.m.bg.gotoAndStop("selected");
        }

        public function activate()
        {
            this.deactivate();
            addEventListener(MouseEvent.CLICK, this.onClick);
            addEventListener(MouseEvent.MOUSE_OVER, this.onHover);
            addEventListener(MouseEvent.MOUSE_OUT, this.onHoverOut);
        }

        private function deactivate()
        {
            this.m.bg.gotoAndStop("up");
            removeEventListener(MouseEvent.CLICK, this.onClick);
            removeEventListener(MouseEvent.MOUSE_OVER, this.onHover);
            removeEventListener(MouseEvent.MOUSE_OUT, this.onHoverOut);
        }

        override public function remove()
        {
            this.deactivate();
            removeChild(this.m);
            this.m = null;
            this.tabsHolder = null;
            this.tabFunction = null;
            super.remove();
        }


    }
}//package ui

