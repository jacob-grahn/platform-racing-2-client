// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//TempModMenuGraphic

package 
{
    import flash.display.MovieClip;
    import fl.controls.Button;

    public dynamic class TempModMenuGraphic extends MovieClip 
    {

        public var kickButton:Button;
        public var warning1Button:Button;
        public var warning2Button:Button;
        public var warning3Button:Button;

        public function TempModMenuGraphic()
        {
            this.__setProp_warning1Button_TempModMenuGraphic_Layer1_0();
            this.__setProp_warning2Button_TempModMenuGraphic_Layer1_0();
            this.__setProp_warning3Button_TempModMenuGraphic_Layer1_0();
            this.method_628();
        }

        internal function __setProp_warning1Button_TempModMenuGraphic_Layer1_0():*
        {
            try {
                this.warning1Button["componentInspectorSetting"] = true;
            } catch(e:Error) {
            }
            this.warning1Button.emphasized = false;
            this.warning1Button.enabled = true;
            this.warning1Button.label = "Warning 1";
            this.warning1Button.labelPlacement = "right";
            this.warning1Button.selected = false;
            this.warning1Button.toggle = false;
            this.warning1Button.visible = true;
            try {
                this.warning1Button["componentInspectorSetting"] = false;
            } catch(e:Error) {
            }
        }

        internal function __setProp_warning2Button_TempModMenuGraphic_Layer1_0():*
        {
            try {
                this.warning2Button["componentInspectorSetting"] = true;
            } catch(e:Error) {
            }
            this.warning2Button.emphasized = false;
            this.warning2Button.enabled = true;
            this.warning2Button.label = "Warning 2";
            this.warning2Button.labelPlacement = "right";
            this.warning2Button.selected = false;
            this.warning2Button.toggle = false;
            this.warning2Button.visible = true;
            try {
                this.warning2Button["componentInspectorSetting"] = false;
            } catch(e:Error) {
            }
        }

        internal function __setProp_warning3Button_TempModMenuGraphic_Layer1_0():*
        {
            try {
                this.warning3Button["componentInspectorSetting"] = true;
            } catch(e:Error) {
            }
            this.warning3Button.emphasized = false;
            this.warning3Button.enabled = true;
            this.warning3Button.label = "Warning 3";
            this.warning3Button.labelPlacement = "right";
            this.warning3Button.selected = false;
            this.warning3Button.toggle = false;
            this.warning3Button.visible = true;
            try {
                this.warning3Button["componentInspectorSetting"] = false;
            } catch(e:Error) {
            }
        }

        internal function method_628():*
        {
            try {
                this.kickButton["componentInspectorSetting"] = true;
            } catch(e:Error) {
            }
            this.kickButton.emphasized = false;
            this.kickButton.enabled = true;
            this.kickButton.label = "30 Minute Kick";
            this.kickButton.labelPlacement = "right";
            this.kickButton.selected = false;
            this.kickButton.toggle = false;
            this.kickButton.visible = true;
            try {
                this.kickButton["componentInspectorSetting"] = false;
            } catch(e:Error) {
            }
        }


    }
}//package 

