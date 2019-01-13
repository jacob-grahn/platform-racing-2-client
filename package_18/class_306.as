// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_18.class_306

package package_18
{
    import ui.class_229;
    import package_8.Character;

    public class class_306 extends class_229 
    {

        private var var_518:class_263;
        private var var_5:Character;
        private var m:PresetListingGraphic;

        public function class_306(_arg_1:class_263)
        {
            this.var_518 = _arg_1;
            this.mouseChildren = false;
            this.doubleClickEnabled = true;
            this.m = new PresetListingGraphic();
            addChild(this.m);
            super(this.m);
            this.var_5 = new Character(_arg_1.hat, _arg_1.head, _arg_1.body, _arg_1.feet);
            this.m.addChild(this.var_5);
            this.var_5.setColors(_arg_1.hatColor, _arg_1.hatColor2, _arg_1.headColor, _arg_1.headColor2, _arg_1.bodyColor, _arg_1.bodyColor2, _arg_1.feetColor, _arg_1.feetColor2);
            this.var_5.scaleX = (this.var_5.scaleY = (0.13 * (1 / 0.15)));
            this.var_5.x = 58;
            this.var_5.y = 61;
            this.m.var_650.text = ("Speed: " + _arg_1.speed);
            this.m.var_642.text = ("Acceleration: " + _arg_1.acceleration);
            this.m.var_641.text = ("Jumping: " + _arg_1.jumping);
            this.m.var_633.text = _arg_1.num.toString();
        }

        public function method_239():class_263
        {
            return (this.var_518);
        }

        override public function remove()
        {
            this.var_5.remove();
            this.var_5 = null;
            removeChild(this.m);
            this.m = null;
            super.remove();
        }


    }
}//package package_18

