// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//lobby.class_196

package lobby
{
    import page.PageHolder;
    import ui.class_246;
    import page.Page;

    public class class_196 extends PageHolder 
    {

        private var bg:HalfSquareBG = new HalfSquareBG();
        private var var_258:class_246;
        private var var_167:Page;

        public function class_196(tabs:Array, _arg_2:Number=100, _arg_3:Number=100, _arg_4:Number=0, _arg_5:String="")
        {
            this.bg.y = 15;
            addChild(this.bg);
            this.var_258 = new class_246(tabs, _arg_4, _arg_2, _arg_5);
            addChild(this.var_258);
            this.var_258 = this.var_258;
            this.setSize(_arg_2, _arg_3);
            super();
        }

        public function setSize(_arg_1:Number, _arg_2:Number)
        {
            this.bg.height = _arg_2 - 15;
            this.bg.width = _arg_1;
            this.var_258.populateTabs(_arg_1);
        }

        override public function changePage(_arg_1:Page)
        {
            super.changePage(_arg_1);
            if (_arg_1 != null) {
                _arg_1.x = 4;
                _arg_1.y = 20;
            }
        }

        override public function remove()
        {
            this.var_258.remove();
            super.remove();
        }


    }
}//package lobby

