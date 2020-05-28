// levelEditor.HatPicker = levelEditor.class_224

package levelEditor
{
    import flash.display.Sprite;
    import package_8.LocalCharacter;
    import flash.events.MouseEvent;

    public class HatPicker extends Sprite 
    {

        private var m:HatPickerGraphic;
        private var c:LocalCharacter;
        private var min:int = 1; // var_538
        private var max:int = 16; // var_620
        private var pickedHat:int = 2; // var_75

        public function HatPicker(l:LocalCharacter)
        {
            this.c = l;
            this.m = new HatPickerGraphic();
            this.m.var_173.left.addEventListener(MouseEvent.CLICK, this.method_372, false, 0, true);
            this.m.var_173.right.addEventListener(MouseEvent.CLICK, this.method_214, false, 0, true);
            addChild(this.m);
            this.display();
        }

        private function method_372(_arg_1:MouseEvent)
        {
            this.pickedHat--;
            if (this.pickedHat === 14) {
                this.pickedHat = 13;
            }
            if (this.pickedHat < this.min) {
                this.pickedHat = this.max;
            }
            this.display();
        }

        private function method_214(_arg_1:MouseEvent)
        {
            this.pickedHat++;
            if (this.pickedHat === 14) {
                this.pickedHat = 15;
            }
            if (this.pickedHat > this.max) {
                this.pickedHat = this.min;
            }
            this.display();
        }

        // _loc1 = colorMC
        // _loc2 = colorMC2
        // _loc3 = a
        private function display()
        {
            this.m.hat.gotoAndStop(this.pickedHat);
            this.m.hat.colorMC.gotoAndStop(this.pickedHat);
            this.m.hat.colorMC2.visible = this.pickedHat == 16;
            var colorMC:int = Math.round(Math.random() * 0xFFFFFF);
            var colorMC2:int = 0;
            var a:Array = new Array(this.pickedHat, colorMC, colorMC2);
            this.c.setHats(a);
        }

        public function remove()
        {
            this.m.var_173.left.removeEventListener(MouseEvent.CLICK, this.method_372);
            this.m.var_173.right.removeEventListener(MouseEvent.CLICK, this.method_214);
            this.m = null;
            this.c = null;
        }


    }
}//package levelEditor

