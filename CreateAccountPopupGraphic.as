// CreateAccountPopupGraphic = class_118

package 
{
    import flash.display.MovieClip;
    import fl.controls.Button;
    import fl.controls.TextInput;

    public dynamic class CreateAccountPopupGraphic extends MovieClip 
    {

        public var createAccount_bt:Button;
        public var cancel_bt:Button;
        public var nameBox:TextInput;
        public var passBox1:TextInput;
        public var passBox2:TextInput;
        public var emailBox:TextInput;

        public function CreateAccountPopupGraphic()
        {
            this.nameBox.maxChars = 20;
            this.passBox1.displayAsPassword = true;
            this.passBox2.displayAsPassword = true;
            this.createAccount_bt.label = "Create Account";
            this.cancel_bt.label = "Cancel";
        }

    }
}
