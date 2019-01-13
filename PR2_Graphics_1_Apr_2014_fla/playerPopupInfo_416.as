// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//PR2_Graphics_1_Apr_2014_fla.playerPopupInfo_416

package PR2_Graphics_1_Apr_2014_fla
{
    import flash.display.MovieClip;
    import flash.text.TextField;
    import fl.controls.Button;
    import flash.display.SimpleButton;

    public dynamic class playerPopupInfo_416 extends MovieClip 
    {

        public var dateBox:TextField;
        public var friendButton:Button;
        public var groupBox:TextField;
        public var guildBox:TextField;
        public var hatBox:TextField;
        public var ignoreButton:Button;
        public var inviteButton:SimpleButton;
        public var kickBg:ShadowBG;
        public var kickButton:SimpleButton;
        public var lastLoginBox:TextField;
        public var levelsButton:Button;
        public var messageButton:Button;
        public var rankBox:TextField;
        public var statusBox:TextField;

        public function playerPopupInfo_416()
        {
            this.method_734();
            this.method_813();
            this.method_652();
            this.method_543();
        }

        internal function method_734():*
        {
            try {
                this.messageButton["componentInspectorSetting"] = true;
            } catch(e:Error) {
            }
            this.messageButton.emphasized = false;
            this.messageButton.enabled = true;
            this.messageButton.label = "Send PM";
            this.messageButton.labelPlacement = "right";
            this.messageButton.selected = false;
            this.messageButton.toggle = false;
            this.messageButton.visible = true;
            try {
                this.messageButton["componentInspectorSetting"] = false;
            } catch(e:Error) {
            }
        }

        internal function method_813():*
        {
            try {
                this.friendButton["componentInspectorSetting"] = true;
            } catch(e:Error) {
            }
            this.friendButton.emphasized = false;
            this.friendButton.enabled = true;
            this.friendButton.label = "Add to Friends";
            this.friendButton.labelPlacement = "right";
            this.friendButton.selected = false;
            this.friendButton.toggle = false;
            this.friendButton.visible = true;
            try {
                this.friendButton["componentInspectorSetting"] = false;
            } catch(e:Error) {
            }
        }

        internal function method_652():*
        {
            try {
                this.ignoreButton["componentInspectorSetting"] = true;
            } catch(e:Error) {
            }
            this.ignoreButton.emphasized = false;
            this.ignoreButton.enabled = true;
            this.ignoreButton.label = "Ignore";
            this.ignoreButton.labelPlacement = "right";
            this.ignoreButton.selected = false;
            this.ignoreButton.toggle = false;
            this.ignoreButton.visible = true;
            try {
                this.ignoreButton["componentInspectorSetting"] = false;
            } catch(e:Error) {
            }
        }

        internal function method_543():*
        {
            try {
                this.levelsButton["componentInspectorSetting"] = true;
            } catch(e:Error) {
            }
            this.levelsButton.emphasized = false;
            this.levelsButton.enabled = true;
            this.levelsButton.label = "View Levels";
            this.levelsButton.labelPlacement = "right";
            this.levelsButton.selected = false;
            this.levelsButton.toggle = false;
            this.levelsButton.visible = true;
            try {
                this.levelsButton["componentInspectorSetting"] = false;
            } catch(e:Error) {
            }
        }


    }
}//package PR2_Graphics_1_Apr_2014_fla

