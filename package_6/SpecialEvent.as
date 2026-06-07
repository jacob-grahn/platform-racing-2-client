// package_6.SpecialEvent = package_6.PlaceArtifact = package_6.class_99

package package_6
{
    import flash.display.Stage;
	import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.ui.Keyboard;
    import dialogs.MessagePopup;
    import page.GamePage;
    import flash.net.URLLoader;

    public class SpecialEvent
    {

        private var stageRef:Stage;
		private var gameRef:Game;

        public function SpecialEvent(stage:Stage, game:Game)
        {
            this.stageRef = stage;
            this.gameRef = game;
            stage.addEventListener(MouseEvent.CLICK, this.clickHandler, false, 0, true);
        }

        private function clickHandler(e:MouseEvent)
        {
            if (Main.group == 3 || Main.isSpecialUser || Main.isPrizer || (Main.group == 2 && !Main.isTempMod && !Main.isTrialMod)) {
                if (Keys.isPressed(Keyboard.G) && Keys.isPressed(Keyboard.C)) { // place artifact
                    var levelId:int = Game(GamePage.course).getCourseID();
                    var xPos:int = e.stageX - GamePage.course.posX - GamePage.course.x;
                    var yPos:int = e.stageY - GamePage.course.posY - GamePage.course.y;
                    var rot:int = Course.course.blockBackground.rotation;
                    new PlaceArtifact(levelId, xPos, yPos, rot);
                } else if (Keys.isPressed(Keyboard.C) && Keys.isPressed(Keyboard.X) && this.gameRef.prize !== null) {
                    Main.socket.write('cancel_prize`'); // cancel current prize
                }
            }
        }

        public function remove()
        {
            this.stageRef.removeEventListener(MouseEvent.CLICK, this.clickHandler);
            this.stageRef = null;
        }


    }
}
