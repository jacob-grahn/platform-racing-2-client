// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//SetEmailPopupGraphic

package 
{
    import flash.display.MovieClip;
    import fl.controls.Button;
    import fl.controls.TextInput;

    public dynamic class SetEmailPopupGraphic extends MovieClip 
    {

        public var ok_bt:Button; // var_3
        public var cancel_bt:Button; // var_1
        public var passBox:TextInput;
        public var email1Box:TextInput;
        public var email2Box:TextInput;

        public function SetEmailPopupGraphic()
        {
            this.ok_bt.label = "OK";
            this.cancel_bt.label = "Cancel";
            this.passBox.displayAsPassword = true;
            this.passBox.maxChars = this.email1Box.maxChars = this.email2Box.maxChars = 100;
        }

        internal function method_632():*
        {
            try {
                this.var_3["componentInspectorSetting"] = true;
            } catch(e:Error) {
            }
            this.var_3.emphasized = false;
            this.var_3.enabled = true;
            this.var_3.label = "OK";
            this.var_3.labelPlacement = "right";
            this.var_3.selected = false;
            this.var_3.toggle = false;
            this.var_3.visible = true;
            try {
                this.var_3["componentInspectorSetting"] = false;
            } catch(e:Error) {
            }
        }

        internal function __setProp_email1Box_SetEmailPopupGraphic_Layer1_0():*
        {
            try {
                this.email1Box["componentInspectorSetting"] = true;
            } catch(e:Error) {
            }
            this.email1Box.displayAsPassword = false;
            this.email1Box.editable = true;
            this.email1Box.enabled = true;
            this.email1Box.maxChars = 100;
            this.email1Box.restrict = "";
            this.email1Box.text = "";
            this.email1Box.visible = true;
            try {
                this.email1Box["componentInspectorSetting"] = false;
            } catch(e:Error) {
            }
        }

        internal function method_542():*
        {
            try {
                this.var_1["componentInspectorSetting"] = true;
            } catch(e:Error) {
            }
            this.var_1.emphasized = false;
            this.var_1.enabled = true;
            this.var_1.label = "Cancel";
            this.var_1.labelPlacement = "right";
            this.var_1.selected = false;
            this.var_1.toggle = false;
            this.var_1.visible = true;
            try {
                this.var_1["componentInspectorSetting"] = false;
            } catch(e:Error) {
            }
        }

        internal function __setProp_email2Box_SetEmailPopupGraphic_Layer1_0():*
        {
            try {
                this.email2Box["componentInspectorSetting"] = true;
            } catch(e:Error) {
            }
            this.email2Box.displayAsPassword = false;
            this.email2Box.editable = true;
            this.email2Box.enabled = true;
            this.email2Box.maxChars = 100;
            this.email2Box.restrict = "";
            this.email2Box.text = "";
            this.email2Box.visible = true;
            try {
                this.email2Box["componentInspectorSetting"] = false;
            } catch(e:Error) {
            }
        }

        internal function method_792():*
        {
            try {
                this.passBox["componentInspectorSetting"] = true;
            } catch(e:Error) {
            }
            this.passBox.displayAsPassword = true;
            this.passBox.editable = true;
            this.passBox.enabled = true;
            this.passBox.maxChars = 100;
            this.passBox.restrict = "";
            this.passBox.text = "";
            this.passBox.visible = true;
            try {
                this.passBox["componentInspectorSetting"] = false;
            } catch(e:Error) {
            }
        }


    }
}//package 

