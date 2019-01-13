// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//ValueMenuGraphic

package 
{
    import flash.display.MovieClip;
    import flash.text.TextField;
    import fl.controls.TextInput;

    public dynamic class ValueMenuGraphic extends MovieClip 
    {

        public var var_283:TextField;
        public var titleBox:TextField;
        public var var_18:TextInput;

        public function ValueMenuGraphic()
        {
            this.method_646();
        }

        internal function method_646():*
        {
            try {
                this.var_18["componentInspectorSetting"] = true;
            } catch(e:Error) {
            }
            this.var_18.displayAsPassword = false;
            this.var_18.editable = true;
            this.var_18.enabled = true;
            this.var_18.maxChars = 3;
            this.var_18.restrict = "0-9";
            this.var_18.text = "";
            this.var_18.visible = true;
            try {
                this.var_18["componentInspectorSetting"] = false;
            } catch(e:Error) {
            }
        }


    }
}//package 

