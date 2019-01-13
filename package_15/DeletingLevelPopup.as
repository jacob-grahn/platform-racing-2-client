// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_15.DeletingLevelPopup = package_15.class_231

package package_15
{
    import package_4.UploadingPopup;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.events.Event;

    public class DeletingLevelPopup extends UploadingPopup 
    {

        // _loc2 = vars
        // _loc3 = request
        public function DeletingLevelPopup(s:String)
        {
            m.textBox.text = "Deleting...";
            var vars:URLVariables = new URLVariables();
            vars.level_id = s;
            var request:URLRequest = new URLRequest(Main.baseURL + "/delete_level.php");
            request.method = URLRequestMethod.POST;
            request.data = vars;
            loader = new SuperLoader(true, 'json');
            loader.load(request);
        }

        override protected function onComplete(e:Event)
        {
            new GetLevels();
            super.onComplete(e);
        }


    }
}
