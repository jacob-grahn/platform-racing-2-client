// player_profile.PresetListing = player_profile.class_306

package player_profile
{
    import character.Character;
    import ui.SelectableButton;

    public class PresetListing extends SelectableButton 
    {

        private var preset:Preset; // var_518
        private var charModel:Character; // var_5
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
            this.charModel = new Character(this.preset.hat, this.preset.head, this.preset.body, this.preset.feet);
            this.m.addChild(this.charModel);
            var hatColor2:int = this.playerDisplay.hatSelect.isPartEpic(this.preset.hat) ? this.preset.hatColor2 : -1;
            var headColor2:int = this.playerDisplay.headSelect.isPartEpic(this.preset.head) ? this.preset.headColor2 : -1;
            var bodyColor2:int = this.playerDisplay.bodySelect.isPartEpic(this.preset.body) ? this.preset.bodyColor2 : -1;
            var feetColor2:int = this.playerDisplay.feetSelect.isPartEpic(this.preset.feet) ? this.preset.feetColor2 : -1;
            this.charModel.setColors(this.preset.hatColor, hatColor2, this.preset.headColor, headColor2, this.preset.bodyColor, bodyColor2, this.preset.feetColor, feetColor2);
            this.charModel.scaleX = this.charModel.scaleY = 0.13 * (1 / 0.15);
            this.charModel.x = 58;
            this.charModel.y = 61;
            this.m.loadoutSpeed.text = "Speed: " + this.preset.speed;
            this.m.loadoutAccel.text = "Acceleration: " + this.preset.acceleration;
            this.m.loadoutJump.text = "Jumping: " + this.preset.jumping;
            this.m.loadoutNum.text = this.preset.num.toString();
        }

        public function getPreset():Preset
        {
            return this.preset;
        }

        override public function remove()
        {
            this.charModel.remove();
            this.charModel = null;
            removeChild(this.m);
            this.m = null;
            super.remove();
        }


    }
}
