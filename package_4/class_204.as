// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_4.class_204

package package_4
{
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.display.DisplayObject;
    import flash.text.TextFieldAutoSize;
    import flash.text.AntiAliasType;

    public class class_204 extends InfoPopup 
    {

        // _loc4 = titleBox
        // _loc5 = contentBox
        // _loc6 = bg
        public function class_204(title:String, content:String, d:DisplayObject)
        {
            if (title != "" || content != "") {
                var titleBox:TextField = this.generateTextBox();
                titleBox.htmlText = "<b>" + title + "</b>";
                titleBox.y = 5;
                contentBox = this.generateTextBox();
                contentBox.htmlText = content;
                contentBox.y = titleBox.height + titleBox.y + 5;
                var bg:ShadowBG = new ShadowBG();
                bg.width = width + 10;
                bg.height = height + 12;
                addChildAt(bg, 0);
                super(d);
                Main.stage.addChild(this);
            }
        }

        // method_423 = generateTextBox
        private function generateTextBox():TextField
        {
            var t:TextField = new TextField();
            var f:TextFormat = new TextFormat();
            f.font = "Arial";
            t.defaultTextFormat = f;
            t.width = 150;
            t.height = 1;
            t.x = 5;
            t.multiline = true;
            t.wordWrap = true;
            t.selectable = false;
            t.autoSize = TextFieldAutoSize.LEFT;
            t.antiAliasType = AntiAliasType.ADVANCED;
            addChild(t);
            return t;
        }


    }
}//package package_4

