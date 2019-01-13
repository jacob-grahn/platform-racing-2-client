// OptionsPopupGraphic = class_256

package 
{
    import flash.display.MovieClip;
    import fl.controls.CheckBox;
    import flash.display.SimpleButton;
    import fl.controls.Button;
    import flash.text.TextField;

    public dynamic class OptionsPopupGraphic extends MovieClip 
    {

        public var toggleMusic:CheckBox; // var_172
        public var toggleBGs:CheckBox; // var_149
        public var toggleSwears:CheckBox; // var_170
        public var wasdUp:TextField; // var_237
        public var wasdRight:TextField; // var_230
        public var wasdDown:TextField; // var_251
        public var wasdLeft:TextField; // var_271
        public var wasdItem:TextField; // var_254
        public var changePass_bt:SimpleButton; // var_431
        public var changeEmail_bt:SimpleButton; // var_502
        public var guildLeave_bt:SimpleButton; // var_481
        public var guildCreate_bt:SimpleButton; // var_399
        public var guildEdit_bt:SimpleButton; // var_418
        public var close_bt:Button;

        public function OptionsPopupGraphic()
        {
            this.toggleMusic.label = "Play Music";
            this.toggleBGs.label = "Draw Backgrounds";
            this.toggleSwears.label = "Filter Swearing";
            this.close_bt.label = "Close";
        }

    }
}//package 

