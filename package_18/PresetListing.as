// package_18.PresetListing = package_18.class_306

package package_18
{
    import ui.class_229;
    import package_8.Character;

    public class PresetListing extends class_229 
    {

        private var var_518:class_263;
        private var var_5:Character;
        private var m:PresetListingGraphic;

        public function PresetListing(_arg_1:class_263)
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
            this.var_5.scaleX = this.var_5.scaleY = 0.13 * (1 / 0.15);
            this.var_5.x = 58;
            this.var_5.y = 61;
            this.m.loadoutSpeed.text = "Speed: " + _arg_1.speed;
            this.m.loadoutAccel.text = "Acceleration: " + _arg_1.acceleration;
            this.m.loadoutJump.text = "Jumping: " + _arg_1.jumping;
            this.m.loadoutNum.text = _arg_1.num.toString();
        }

        public function method_239():class_263
        {
            return this.var_518;
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
}
