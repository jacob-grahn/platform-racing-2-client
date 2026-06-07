// player_profile.PresetListing = player_profile.class_306

package player_profile
{
    import package_8.Character;
    import ui.SelectableButton;

    public class PresetListing extends SelectableButton 
    {

        private var preset:Preset; // var_518
        private var character:Character; // var_5
        private var playerDisplay:PlayerDisplay;
        private var m:PresetListingGraphic;

        public function PresetListing(p:Preset, pd:PlayerDisplay)
        {
            this.preset = p;
            this.playerDisplay = pd;
            this.mouseChildren = false;
            this.doubleClickEnabled = true;
            this.m = new PresetListingGraphic();
            addChild(this.m);
            super(this.m);
            this.character = new Character(this.preset.hat, this.preset.head, this.preset.body, this.preset.feet);
            this.m.addChild(this.character);
            var hatColor2:int = this.playerDisplay.hatSelect.isPartEpic(this.preset.hat) ? this.preset.hatColor2 : -1;
            var headColor2:int = this.playerDisplay.headSelect.isPartEpic(this.preset.head) ? this.preset.headColor2 : -1;
            var bodyColor2:int = this.playerDisplay.bodySelect.isPartEpic(this.preset.body) ? this.preset.bodyColor2 : -1;
            var feetColor2:int = this.playerDisplay.feetSelect.isPartEpic(this.preset.feet) ? this.preset.feetColor2 : -1;
            this.character.setColors(this.preset.hatColor, hatColor2, this.preset.headColor, headColor2, this.preset.bodyColor, bodyColor2, this.preset.feetColor, feetColor2);
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
