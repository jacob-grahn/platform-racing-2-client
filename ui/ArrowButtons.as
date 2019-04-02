// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// ui.ArrowButtons = ui.class_311

package ui
{
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.events.Event;

    public class ArrowButtons extends Sprite 
    {

        private var m:ArrowButtonsGraphic = new ArrowButtonsGraphic();
        private var array:Array;
        private var index:int = 0;
        public var value:int;

        public function ArrowButtons(_arg_1:Array, _arg_2:int)
        {
            this.array = _arg_1;
            this.setValue(_arg_2);
            addChild(this.m);
            this.m.var_333.addEventListener(MouseEvent.CLICK, this.method_462);
            this.m.var_381.addEventListener(MouseEvent.CLICK, this.method_361);
        }

        private function method_462(_arg_1:MouseEvent)
        {
            this.index--;
            this.method_402();
        }

        private function method_361(_arg_1:MouseEvent)
        {
            this.index++;
            this.method_402();
        }

        private function method_402()
        {
            if (this.index < 0) {
                this.index = (this.array.length - 1);
            }
            if (this.index > (this.array.length - 1)) {
                this.index = 0;
            }
            this.value = this.array[this.index];
            var _local_1:Event = new Event(Event.CHANGE);
            dispatchEvent(_local_1);
        }

        public function setValue(_arg_1:int)
        {
            var _local_2:int = -1;
            var _local_3:int;
            while (_local_3 < this.array.length) {
                if (_arg_1 == this.array[_local_3]) {
                    _local_2 = _local_3;
                    break;
                }
                _local_3++;
            }
            if (_local_2 == -1) {
                _local_2 = 0;
            } else {
                this.value = _arg_1;
                this.index = _local_2;
            }
        }

        public function remove()
        {
            this.m.var_333.removeEventListener(MouseEvent.CLICK, this.method_462);
            this.m.var_381.removeEventListener(MouseEvent.CLICK, this.method_361);
            removeChild(this.m);
            this.m = null;
            parent.removeChild(this);
        }


    }
}//package ui

