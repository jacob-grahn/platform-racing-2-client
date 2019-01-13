// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// ForgotPassPopupGraphic = class_166

package 
{
    import flash.display.MovieClip;
    import fl.controls.Button;
    import fl.controls.TextInput;

    public dynamic class ForgotPassPopupGraphic extends MovieClip 
    {

        public var cancel_bt:Button; // var_1
        public var emailBox:TextInput; // var_311
        public var nameBox:TextInput;
        public var ok_bt:Button; // var_3

        public function ForgotPassPopupGraphic()
        {
            this.nameBox.maxChars = 20;
            this.cancel_bt.label = "Cancel";
            this.ok_bt.label = "OK";
        }

    }
}
