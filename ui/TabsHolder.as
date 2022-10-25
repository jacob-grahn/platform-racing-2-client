// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// ui.TabsHolder = ui.class_246

package ui
{
    import flash.events.MouseEvent;

    public class TabsHolder extends Removable 
    {

        private static var memory:Object = new Object();

        public var tabArr:Array; // var_43
        private var selected:Number;
        //private var maxWidth:Number; // var_239 // removed -- using local var from constructor
        private var holderId:String; // var_405

        // _loc5 = tabNum
        // _loc6 = tab
        // _loc7 = i
        public function TabsHolder(tabs:Array, hId:String = "", sel:Number = 0, maxW:Number = 100)
        {
            super();
            this.tabArr = tabs;
            this.holderId = hId;
            var tabNum:Number = TabsHolder.getLastTab(this.holderId);
            this.selected = !isNaN(tabNum) && tabNum < tabs.length ? tabNum : sel;
            var tab:LobbyTab;
            var i:int = 0;
            while (i < tabs.length) {
                tab = tabs[i];
                tab.setTabsHolder(this);
                addChild(tab);
                i++;
            }
            this.populateTabs(maxW);
            tabs[this.selected].select();
            addEventListener(MouseEvent.MOUSE_OUT, this.resetTabPositions);
        }

        // method_438 = setLastTab
        public static function setLastTab(holderId:String, tabNum:Number)
        {
            TabsHolder.memory[holderId] = tabNum;
        }

        // method_700 = getLastTab
        public static function getLastTab(holderId:String):Number
        {
            return TabsHolder.memory[holderId];
        }

        // _loc2 = tab
        // _loc3 = tabX
        // _loc4 = i
        // _loc5 = tabW
        // method_342 = populateTabs
        public function populateTabs(maxW:Number)
        {
            var tab:LobbyTab;
            var tabX:Number = 0;
            var i:int = 0;
            while (i < this.tabArr.length) {
                tab = this.tabArr[i];
                tab.x = tabX;
                tabX = tabX + tab.width;
                i++;
            }
            if (width > maxW) {
                var tabW:Number = (width - maxW) / (this.tabArr.length - 1);
                i = 1;
                while (i < this.tabArr.length) {
                    this.tabArr[i].x = this.tabArr[i].x - (tabW * i);
                    i++;
                }
            }
        }

        // unnecessary; replaced with resetTabPositions
        /*private function method_246(e:MouseEvent)
        {
            this.resetTabPositions();
        }*/

        // _loc2 = i
        // removed _arg1, replaced with this.selected
        // method_282 = resetTabPositions
        private function resetTabPositions(e:MouseEvent = null)
        {
            var i:Number = 0;
            while (i < this.selected) {
                this.moveToFront(this.tabArr[i]);
                i++;
            }
            i = this.tabArr.length - 1;
            while (i > this.selected) {
                this.moveToFront(this.tabArr[i]);
                i--;
            }
            this.moveToFront(this.tabArr[this.selected]);
        }

        // _loc2 = tab
        // _loc3 = i
        internal function select(target:LobbyTab)
        {
            var tab:LobbyTab;
            var i:Number = 0;
            while (i < this.tabArr.length) {
                tab = this.tabArr[i];
                if (tab == target) {
                    this.selected = i;
                } else {
                    tab.activate();
                }
                i++;
            }
            this.resetTabPositions();
        }

        // method_100 = moveToFront
        internal function moveToFront(tab:LobbyTab)
        {
            addChildAt(tab, numChildren - 1);
        }

        // _loc1 = i
        override public function remove()
        {
            removeEventListener(MouseEvent.MOUSE_OUT, this.resetTabPositions);
            var i:Number = 0;
            while (i < this.tabArr.length) {
                this.tabArr[i].remove();
                i++;
            }
            if (this.holderId != "") {
                setLastTab(this.holderId, this.selected);
            }
            super.remove();
        }


    }
}
