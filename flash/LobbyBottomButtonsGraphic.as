// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// LobbyBottomButtonsGraphic = class_202

package
{
    import flash.display.MovieClip;
    import fl.controls.Button;
    import flash.utils.Dictionary;
    import flash.events.Event;

    public dynamic class LobbyBottomButtonsGraphic extends MovieClip
    {

        public var creditsButton:Button;
        public var levelEditorButton:Button;
        public var logoutButton:Button;
        public var moreGamesButton:MovieClip;
        public var optionsButton:Button;
        public var vaultButton:MovieClip;
        public var var_17:Dictionary = new Dictionary(true);
        public var var_284:int = -1;

        public function LobbyBottomButtonsGraphic()
        {
            addFrameScript(1, this.frame2);
            addEventListener(Event.FRAME_CONSTRUCTED, this.onFrameConstructed, false, 0, true);
        }

        internal function onFrameConstructed(_arg_1:Object):*
        {
            var _local_2:int = currentFrame;
            if (this.var_284 == _local_2) {
                return;
            }
            this.var_284 = _local_2;
            this.logoutButton.label = "Logout";
            this.levelEditorButton.label = "Level Editor";
            this.optionsButton.label = "Options";
            this.creditsButton.label = "Credits";
            this.moreGamesButton.label = "";
            this.vaultButton.label = "";
        }

        private function frame2()
        {
            stop();
        }


    }
}//package
