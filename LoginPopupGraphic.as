// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// LoginPopupGraphic = class_120

package 
{
    import flash.display.MovieClip;
    import fl.controls.Button;
    import flash.display.SimpleButton;
    import fl.controls.TextInput;
    import fl.controls.CheckBox;

    public dynamic class LoginPopupGraphic extends MovieClip 
    {

        public var nameBox:TextInput;
        public var passBox:TextInput;
        public var forgotPass:SimpleButton; // var_554
        public var rememberMe_chk:CheckBox; // var_175
        public var cancel_bt:Button; // var_1
        public var login_bt:Button; // var_22

        public function LoginPopupGraphic()
        {
            this.nameBox.maxChars = 20;
            this.passBox.displayAsPassword = true;
            this.rememberMe_chk.label = "Remember Me";
            this.cancel_bt.label = "Cancel";
            this.login_bt.label = "Log In";
        }

    }
}
