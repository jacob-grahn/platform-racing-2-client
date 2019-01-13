// package_6.PlaceArtifact = package_6.class_99

package package_6
{
    import flash.display.Stage;
	import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.ui.Keyboard;
    import package_4.MessagePopup;
    import package_4.UploadingPopup;
    import page.GamePage;
    import flash.net.URLLoader;

    public class PlaceArtifact
    {

        private var stageRef:Stage;
        private var uploading:UploadingPopup;

        public function PlaceArtifact(stage:Stage)
        {
            this.stageRef = stage;
            stage.addEventListener(MouseEvent.CLICK, this.clickHandler, false, 0, true);
        }

        private function clickHandler(e:MouseEvent)
        {
            if (Keys.isPressed(Keyboard.G) && Keys.isPressed(Keyboard.C)) {
                var xPos:int = e.stageX - GamePage.course.posX - GamePage.course.x;
                var yPos:int = e.stageY - GamePage.course.posY - GamePage.course.y;
                var vars:URLVariables = new URLVariables();
                vars.x = xPos;
                vars.y = yPos;
                vars.level_id = Game(GamePage.course).method_206();
                var request:URLRequest = new URLRequest(Main.baseURL + "/place_artifact.php");
                request.data = vars;
                request.method = URLRequestMethod.POST;
                this.uploading = new UploadingPopup(request, 'json');
            }
        }

        /*private function onReturnData(e:Event)
        {
            var ret:Object = SuperLoader(e.target).parsedData;
            if (ret.success == true && ret.error == null) {
                new MessagePopup(ret.success);
            }
        }*/

        public function remove()
        {
            this.stageRef.removeEventListener(MouseEvent.CLICK, this.clickHandler);
            this.stageRef = null;
            this.uploading = null;
        }


    }
}
