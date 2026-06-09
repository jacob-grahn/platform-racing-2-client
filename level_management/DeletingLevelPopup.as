
package level_management
{
    import dialogs.UploadingPopup;
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
            super();
            m.textBox.text = "Deleting level...";
            var vars:URLVariables = new URLVariables();
            vars.level_id = s;
            var request:URLRequest = new URLRequest(Main.baseURL + "/delete_level.php");
            request.method = URLRequestMethod.POST;
            request.data = vars;
            loader = new SuperLoader(true, 'json');
            loader.addEventListener(SuperLoader.d, this.onComplete, false, 0, true);
            loader.load(request);
        }

        override protected function onComplete(e:Event)
        {
            new GetLevels();
            super.onComplete(e);
            super.parsedDataHandler(e);
        }


    }
}
