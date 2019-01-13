// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// levelEditor.GetLevelsPopupItem = levelEditor.class_232

package levelEditor
{
    import ui.class_229;

    public class GetLevelsPopupItem extends class_229 
    {

        public var id:String;
        public var version:int;
        public var title:String;
        private var m:GetLevelsPopupItemGraphic = new GetLevelsPopupItemGraphic();

        public function GetLevelsPopupItem(lId:String, lV:int, lTitle:String, lPub:String)
        {
            super(this.m);
            this.id = lId;
            this.version = lV;
            this.title = lTitle;
            this.doubleClickEnabled = true;
            if (lPub == "1") {
                this.m.statusBox.text = "Published";
            } else {
                this.m.statusBox.text = "Unpublished";
            }
            this.m.titleBox.text = lTitle;
            this.m.mouseEnabled = false;
            this.m.mouseChildren = false;
            addChild(this.m);
        }

    }
}
