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

        public function ArrowButtons(a:Array, val:int)
        {
            this.array = a;
            this.setValue(val);
            addChild(this.m);
            this.m.left.addEventListener(MouseEvent.CLICK, this.clickLeft);
            this.m.right.addEventListener(MouseEvent.CLICK, this.clickRight);
        }

        private function clickLeft(e:MouseEvent)
        {
            this.index--;
            this.wrapCheck();
        }

        private function clickRight(e:MouseEvent)
        {
            this.index++;
            this.wrapCheck();
        }

        private function wrapCheck()
        {
            var lastKey:int = this.array.length - 1;
            this.index = this.index < 0 ? lastKey : (this.index > lastKey ? 0 : this.index);
            this.value = this.array[this.index];
            dispatchEvent(new Event(Event.CHANGE));
        }

        public function setValue(val:int)
        {
            var arrayPos:int = -1;
            var i:int = 0;
            while (i < this.array.length) {
                if (val == this.array[i]) {
                    arrayPos = i;
                    break;
                }
                i++;
            }
            if (arrayPos == -1) {
                arrayPos = 0;
            } else {
                this.value = val;
                this.index = arrayPos;
            }
            dispatchEvent(new Event(Event.CHANGE));
        }

        public function remove()
        {
            this.m.left.removeEventListener(MouseEvent.CLICK, this.clickLeft);
            this.m.right.removeEventListener(MouseEvent.CLICK, this.clickRight);
            removeChild(this.m);
            this.m = null;
            parent.removeChild(this);
        }


    }
}//package ui

