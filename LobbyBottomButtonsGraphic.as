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
            addEventListener(Event.FRAME_CONSTRUCTED, this.method_173, false, 0, true);
        }

        internal function method_781(_arg_1:int):*
        {
            if (this.logoutButton != null && _arg_1 >= 2 && _arg_1 <= 31 && (this.var_17[this.logoutButton] == undefined || int(this.var_17[this.logoutButton]) < 2) && int(this.var_17[this.logoutButton]) <= 31) {
                this.var_17[this.logoutButton] = _arg_1;
                try {
                    this.logoutButton["componentInspectorSetting"] = true;
                } catch(e:Error) {
                }
                this.logoutButton.emphasized = false;
                this.logoutButton.enabled = true;
                this.logoutButton.label = "Logout";
                this.logoutButton.labelPlacement = "right";
                this.logoutButton.selected = false;
                this.logoutButton.toggle = false;
                this.logoutButton.visible = true;
                try {
                    this.logoutButton["componentInspectorSetting"] = false;
                } catch(e:Error) {
                }
            }
        }

        internal function method_762(_arg_1:int):*
        {
            if (this.levelEditorButton != null && _arg_1 >= 2 && _arg_1 <= 31 && (this.var_17[this.levelEditorButton] == undefined || int(this.var_17[this.levelEditorButton]) < 2) && int(this.var_17[this.levelEditorButton]) <= 31) {
                this.var_17[this.levelEditorButton] = _arg_1;
                try {
                    this.levelEditorButton["componentInspectorSetting"] = true;
                } catch(e:Error) {
                }
                this.levelEditorButton.emphasized = false;
                this.levelEditorButton.enabled = true;
                this.levelEditorButton.label = "Level Editor";
                this.levelEditorButton.labelPlacement = "right";
                this.levelEditorButton.selected = false;
                this.levelEditorButton.toggle = false;
                this.levelEditorButton.visible = true;
                try {
                    this.levelEditorButton["componentInspectorSetting"] = false;
                } catch(e:Error) {
                }
            }
        }

        internal function method_650(_arg_1:int):*
        {
            if (this.optionsButton != null && _arg_1 >= 2 && _arg_1 <= 31 && (this.var_17[this.optionsButton] == undefined || int(this.var_17[this.optionsButton]) < 2) && int(this.var_17[this.optionsButton]) <= 31) {
                this.var_17[this.optionsButton] = _arg_1;
                try {
                    this.optionsButton["componentInspectorSetting"] = true;
                } catch(e:Error) {
                }
                this.optionsButton.emphasized = false;
                this.optionsButton.enabled = true;
                this.optionsButton.label = "Options";
                this.optionsButton.labelPlacement = "right";
                this.optionsButton.selected = false;
                this.optionsButton.toggle = false;
                this.optionsButton.visible = true;
                try {
                    this.optionsButton["componentInspectorSetting"] = false;
                } catch(e:Error) {
                }
            }
        }

        internal function method_722(_arg_1:int):*
        {
            if (this.creditsButton != null && _arg_1 >= 2 && _arg_1 <= 31 && (this.var_17[this.creditsButton] == undefined || int(this.var_17[this.creditsButton]) < 2) && int(this.var_17[this.creditsButton]) <= 31) {
                this.var_17[this.creditsButton] = _arg_1;
                try {
                    this.creditsButton["componentInspectorSetting"] = true;
                } catch(e:Error) {
                }
                this.creditsButton.emphasized = false;
                this.creditsButton.enabled = true;
                this.creditsButton.label = "Credits";
                this.creditsButton.labelPlacement = "right";
                this.creditsButton.selected = false;
                this.creditsButton.toggle = false;
                this.creditsButton.visible = true;
                try {
                    this.creditsButton["componentInspectorSetting"] = false;
                } catch(e:Error) {
                }
            }
        }

        internal function method_173(_arg_1:Object):*
        {
            var _local_2:int = currentFrame;
            if (this.var_284 == _local_2) {
                return;
            }
            this.var_284 = _local_2;
            /*this.method_781(_local_2);
            this.method_762(_local_2);
            this.method_650(_local_2);
            this.method_722(_local_2);*/
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
