// levelEditor.HatPicker = levelEditor.class_224

package levelEditor
{
    import com.jiggmin.data.Settings;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import character.LocalCharacter;

    public class HatPicker extends Sprite 
    {

        private var m:HatPickerGraphic;
        private var c:LocalCharacter;
        private var min:int = 1;
        private var max:int = 16;
        private var pickedHat:int = 2;

        public function HatPicker(player:LocalCharacter)
        {
            this.c = player;
            this.m = new HatPickerGraphic();
            this.m.var_173.left.addEventListener(MouseEvent.CLICK, this.clickLeft, false, 0, true);
            this.m.var_173.right.addEventListener(MouseEvent.CLICK, this.clickRight, false, 0, true);
            addChild(this.m);
            this.pickedHat = Settings.getValue(Settings.LE_TEST_HAT, 2);
            this.display();
        }

        private function clickLeft(e:MouseEvent)
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

        private function clickRight(e:MouseEvent)
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

        private function display()
        {
            this.m.hat.gotoAndStop(this.pickedHat);
            this.m.hat.colorMC.gotoAndStop(this.pickedHat);
            this.m.hat.colorMC2.gotoAndStop(this.pickedHat);
            this.m.hat.colorMC2.visible = this.pickedHat == 16;
            var colorMC:int = Math.round(Math.random() * 0xFFFFFF);
            var colorMC2:int = 0;
            var a:Array = new Array(this.pickedHat, colorMC, colorMC2);
            this.c.setHats(a);
            Settings.setValue(Settings.LE_TEST_HAT, this.pickedHat);
        }

        public function resetHat()
        {
            var colorMC:int = this.c.hat1Color;
            var colorMC2:int = this.c.hat1Color2;
            this.c.setHats([]);
            this.c.setHats([this.pickedHat, colorMC, colorMC2]);
        }

        public function remove()
        {
            this.m.var_173.left.removeEventListener(MouseEvent.CLICK, this.clickLeft);
            this.m.var_173.right.removeEventListener(MouseEvent.CLICK, this.clickRight);
            this.m = null;
            this.c = null;
        }


    }
}//package levelEditor
