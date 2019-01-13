// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//ui.class_229

package ui
{
    import flash.display.Sprite;
    import flash.display.MovieClip;
    import flash.events.MouseEvent;

    public class class_229 extends Sprite 
    {

        private var m:MovieClip;
        private var selected:Boolean = false;
        private var hovering:Boolean = false; // var_428

        public function class_229(mc:MovieClip)
        {
            this.m = mc;
            addEventListener(MouseEvent.MOUSE_OVER, this.overHandler, false, 0, true);
            addEventListener(MouseEvent.MOUSE_OUT, this.outHandler, false, 0, true);
            this.display();
        }

        public function method_368(b:Boolean)
        {
            this.selected = b;
            this.display();
        }

        public function method_321():Boolean
        {
            return this.selected;
        }

        private function overHandler(e:MouseEvent)
        {
            this.hovering = true;
            this.display();
        }

        private function outHandler(e:MouseEvent)
        {
            this.hovering = false;
            this.display();
        }

        private function display()
        {
            if (this.selected) {
                this.m.gotoAndStop("selected");
            } else {
                if (this.hovering) {
                    this.m.gotoAndStop("over");
                } else {
                    this.m.gotoAndStop("up");
                }
            }
        }

        public function remove()
        {
            removeEventListener(MouseEvent.MOUSE_OVER, this.overHandler);
            removeEventListener(MouseEvent.MOUSE_OUT, this.outHandler);
            this.m = null;
            if (parent != null) {
                parent.removeChild(this);
            }
        }


    }
}
