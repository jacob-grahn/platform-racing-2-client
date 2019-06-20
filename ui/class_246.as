// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//ui.class_246

package ui
{
    import flash.events.MouseEvent;

    public class class_246 extends Removable 
    {

        private static var memory:Object = new Object();

        public var tabArr:Array; // var_43
        private var selected:Number;
        private var var_239:Number;
        private var var_405:String;

        // _loc6 = tab
        // _loc7 = i
        public function class_246(tabs:Array, _arg_2:Number=0, _arg_3:Number=100, _arg_4:String="")
        {
            super();
            this.tabArr = tabs;
            this.selected = _arg_2;
            this.var_239 = _arg_3;
            this.var_405 = _arg_4;
            var _local_5:Number = class_246.method_700(_arg_4);
            if (!isNaN(_local_5) && _local_5 < tabs.length) {
                _arg_2 = _local_5;
            }
            var tab:LobbyTab;
            var i:int = 0;
            while (i < tabs.length) {
                tab = tabs[i];
                tab.method_671(this);
                addChild(tab);
                i++;
            }
            this.populateTabs(_arg_3);
            tabs[_arg_2].select();
            addEventListener(MouseEvent.MOUSE_OUT, this.method_246);
        }

        public static function method_438(_arg_1:String, _arg_2:Number)
        {
            class_246.memory[_arg_1] = _arg_2;
        }

        public static function method_700(_arg_1:String):Number
        {
            return class_246.memory[_arg_1];
        }

        // _loc2 = tab
        // _loc3 = tabX
        // _loc4 = i
        // _loc5 = tabW
        // method_342 = populateTabs
        public function populateTabs(_arg_1:Number)
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
            if (width > _arg_1) {
                var tabW:Number = (width - _arg_1) / (this.tabArr.length - 1);
                i = 1;
                while (i < this.tabArr.length) {
                    this.tabArr[i].x = this.tabArr[i].x - (tabW * i);
                    i++;
                }
            }
        }

        private function method_246(_arg_1:MouseEvent)
        {
            this.method_282(this.selected);
        }

        private function method_282(_arg_1:Number)
        {
            var _local_2:Number;
            _local_2 = 0;
            while (_local_2 < _arg_1) {
                this.method_100(this.tabArr[_local_2]);
                _local_2++;
            }
            _local_2 = (this.tabArr.length - 1);
            while (_local_2 > _arg_1) {
                this.method_100(this.tabArr[_local_2]);
                _local_2--;
            }
            this.method_100(this.tabArr[_arg_1]);
        }

        internal function select(_arg_1:LobbyTab)
        {
            var _local_2:LobbyTab;
            var _local_3:Number = 0;
            while (_local_3 < this.tabArr.length) {
                _local_2 = this.tabArr[_local_3];
                if (_local_2 == _arg_1) {
                    this.selected = _local_3;
                } else {
                    _local_2.activate();
                }
                _local_3++;
            }
            this.method_282(this.selected);
        }

        internal function method_100(_arg_1:LobbyTab)
        {
            addChildAt(_arg_1, (numChildren - 1));
        }

        override public function remove()
        {
            removeEventListener(MouseEvent.MOUSE_OUT, this.method_246);
            var _local_1:Number = 0;
            while (_local_1 < this.tabArr.length) {
                this.tabArr[_local_1].remove();
                _local_1++;
            }
            if (this.var_405 != "") {
                method_438(this.var_405, this.selected);
            }
            super.remove();
        }


    }
}//package ui

