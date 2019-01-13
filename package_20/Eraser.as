// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_20.Eraser

package package_20
{
    import levelEditor.LevelEditor;

    public class Eraser extends Brush 
    {

        public function Eraser()
        {
            color = 0xFFFFFF;
            mode = "erase";
        }

        override protected function stopDrawing()
        {
            drawing = false;
            LevelEditor.editor.var_220.erase();
        }


    }
}//package package_20

