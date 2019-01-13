// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//levelEditor.class_224

package levelEditor
{
    import flash.display.Sprite;
    import package_8.Racer;
    import flash.events.MouseEvent;

    public class class_224 extends Sprite 
    {

        private var m:class_272;
        private var c:Racer;
        private var var_538:int = 1;
        private var var_620:int = 13;
        private var var_75:int = 2;

        public function class_224(_arg_1:Racer)
        {
            this.c = _arg_1;
            this.m = new class_272();
            this.m.var_173.var_333.addEventListener(MouseEvent.CLICK, this.method_372, false, 0, true);
            this.m.var_173.var_381.addEventListener(MouseEvent.CLICK, this.method_214, false, 0, true);
            addChild(this.m);
            this.display();
        }

        private function method_372(_arg_1:MouseEvent)
        {
            this.var_75--;
            if (this.var_75 < this.var_538) {
                this.var_75 = this.var_620;
            }
            this.display();
        }

        private function method_214(_arg_1:MouseEvent)
        {
            this.var_75++;
            if (this.var_75 > this.var_620) {
                this.var_75 = this.var_538;
            }
            this.display();
        }

        private function display()
        {
            this.m.hat.gotoAndStop(this.var_75);
            this.m.hat.colorMC.gotoAndStop(this.var_75);
            this.m.hat.colorMC2.visible = false;
            var _local_1:int = int(Math.round((Math.random() * 0xFFFFFF)));
            var _local_2:int = -1;
            var _local_3:Array = new Array(this.var_75, _local_1, _local_2);
            this.c.setHats(_local_3);
        }

        public function remove()
        {
            this.m.var_173.var_333.removeEventListener(MouseEvent.CLICK, this.method_372);
            this.m.var_173.var_381.removeEventListener(MouseEvent.CLICK, this.method_214);
            this.m = null;
            this.c = null;
        }


    }
}//package levelEditor

