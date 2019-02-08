// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// ui.LoginPageMenuButton = ui.class_70

package ui
{
    import flash.events.MouseEvent;

    public class LoginPageMenuButton extends class_7 
    {

        private var m:TextButtonGraphic = new TextButtonGraphic();
        private var clickHandler:Function;
        private var str:String;

        public function LoginPageMenuButton(buttonText:String, clickFn:Function)
        {
            this.str = buttonText;
            this.clickHandler = clickFn;
            this.m.textBox1.text = this.m.textBox2.text = this.str;
            this.m.textBox1.autoSize = (this.m.textBox2.autoSize = "center");
            this.m.alpha = 0.75;
            this.m.addEventListener(MouseEvent.MOUSE_OVER, this.overHandler);
            this.m.addEventListener(MouseEvent.MOUSE_OUT, this.outHandler);
            this.m.addEventListener(MouseEvent.CLICK, clickFn);
            addChild(this.m);
        }

        private function overHandler(e:MouseEvent)
        {
            this.m.textBox1.text = this.m.textBox2.text = "- " + this.str + " -";
            this.m.alpha = 1;
        }

        private function outHandler(e:MouseEvent)
        {
            if (this.m != null && this.str != null) {
                this.m.textBox1.text = this.m.textBox2.text = this.str;
                this.m.alpha = 0.75;
            }
        }

        override public function remove()
        {
            this.m.addEventListener(MouseEvent.MOUSE_OVER, this.overHandler);
            this.m.addEventListener(MouseEvent.MOUSE_OUT, this.outHandler);
            this.m.removeEventListener(MouseEvent.CLICK, this.clickHandler);
            removeChild(this.m);
            this.m.textBox1.text = this.m.textBox2.text = "";
            this.m = null;
            this.clickHandler = null;
            super.remove();
        }


    }
}
