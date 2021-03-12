// package_18.PresetListing = package_18.class_306

package package_18
{
    import package_8.Character;
    import ui.class_229;

    public class PresetListing extends class_229 
    {

        private var preset:Preset; // var_518
        private var character:Character; // var_5
        private var m:PresetListingGraphic;

        public function PresetListing(p:Preset)
        {
            this.preset = p;
            this.mouseChildren = false;
            this.doubleClickEnabled = true;
            this.m = new PresetListingGraphic();
            addChild(this.m);
            super(this.m);
            this.character = new Character(this.preset.hat, this.preset.head, this.preset.body, this.preset.feet);
            this.m.addChild(this.character);
            this.character.setColors(this.preset.hatColor, this.preset.hatColor2, this.preset.headColor, this.preset.headColor2, this.preset.bodyColor, this.preset.bodyColor2, this.preset.feetColor, this.preset.feetColor2);
            this.character.scaleX = this.character.scaleY = 0.13 * (1 / 0.15);
            this.character.x = 58;
            this.character.y = 61;
            this.m.loadoutSpeed.text = "Speed: " + this.preset.speed;
            this.m.loadoutAccel.text = "Acceleration: " + this.preset.acceleration;
            this.m.loadoutJump.text = "Jumping: " + this.preset.jumping;
            this.m.loadoutNum.text = this.preset.num.toString();
        }

        // method_239 = getPreset
        public function getPreset():Preset
        {
            return this.preset;
        }

        override public function remove()
        {
            this.character.remove();
            this.character = null;
            removeChild(this.m);
            this.m = null;
            super.remove();
        }


    }
}
