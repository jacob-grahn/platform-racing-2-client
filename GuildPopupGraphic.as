// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//GuildPopupGraphic

package 
{
    import flash.display.MovieClip;
    import fl.controls.Button;
    import flash.display.SimpleButton;
    import flash.text.TextField;
    import flash.utils.Dictionary;
    import flash.events.Event;

    public dynamic class GuildPopupGraphic extends MovieClip 
    {

        public var transfer_bt:SimpleButton;
        public var shadow:ShadowBG; // var_676
        public var close_bt:Button; // var_2
        public var edit_bt:SimpleButton;
        public var delete_bt:SimpleButton; // var_459
        public var gpTodayBox:TextField; // var_472
        public var gpTotalBox:TextField; // var_460
        public var membersHolder:MovieClip; // var_287
        public var listCover:MovieClip; // var_671 (listCover????)
        public var membersCount:TextField; // var_665
        public var messageButton:Button;
        public var guildProse:TextField; // var_324
        public var titleBox:TextField;
        public var dic:Dictionary = new Dictionary(true); // var_17
        public var givenFrame:int = -1; // var_284

        public function GuildPopupGraphic()
        {
            addEventListener(Event.FRAME_CONSTRUCTED, this.init, false, 0, true);
        }

        internal function method_815(_arg_1:int):*
        {
            if ((this.close_bt != null && _arg_1 >= 6 && _arg_1 <= 16 && this.dic[this.close_bt] == undefined) || (int(this.dic[this.close_bt]) < 6 && (int(this.dic[this.close_bt]) <= 16))) {
                this.dic[this.close_bt] = _arg_1;
                try {
                    this.close_bt["componentInspectorSetting"] = true;
                } catch(e:Error) {
                }
                this.close_bt.emphasized = false;
                this.close_bt.enabled = true;
                this.close_bt.label = "Close";
                this.close_bt.labelPlacement = "right";
                this.close_bt.selected = false;
                this.close_bt.toggle = false;
                this.close_bt.visible = true;
                try {
                    this.close_bt["componentInspectorSetting"] = false;
                } catch(e:Error) {
                }
            }
        }

        internal function method_732(_arg_1:int):*
        {
            if ((this.messageButton != null && _arg_1 >= 6 && _arg_1 <= 16 && this.dic[this.messageButton] == undefined) || (int(this.dic[this.messageButton]) < 6 && (int(this.dic[this.messageButton]) <= 16))) {
                this.dic[this.messageButton] = _arg_1;
                try {
                    this.messageButton["componentInspectorSetting"] = true;
                } catch(e:Error) {
                }
                this.messageButton.emphasized = false;
                this.messageButton.enabled = true;
                this.messageButton.label = "PM Everyone";
                this.messageButton.labelPlacement = "right";
                this.messageButton.selected = false;
                this.messageButton.toggle = false;
                this.messageButton.visible = true;
                try {
                    this.messageButton["componentInspectorSetting"] = false;
                } catch(e:Error) {
                }
            }
        }

        // _loc2 = frame
        private function init(_arg_1:Object):*
        {
            var _local_2:int = currentFrame;
            if (this.givenFrame == _local_2) {
                return;
            }
            this.givenFrame = _local_2;
            this.method_815(_local_2);
            this.method_732(_local_2);
        }


    }
}//package 

