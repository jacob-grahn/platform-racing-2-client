// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_14.Blocks

package package_14
{
    import package_19.ObjectDeleterButton;
    import package_19.class_228;
    import data.Objects;

    public class Blocks extends SideBar 
    {

        public function Blocks()
        {
            addItem(new ObjectDeleterButton(), "Delete Tool", "Click and drag the mouse to delete things with remarkable speed!");
            addItem(new class_228(Objects.Basic1BlockCode), "Basic Block 1", "Normal old every day run of the mill squarish thing that you can stand on.");
            addItem(new class_228(Objects.Basic2BlockCode), "Basic Block 2", "Normal old every day run of the mill squarish thing that you can stand on.");
            addItem(new class_228(Objects.Basic3BlockCode), "Basic Block 3", "Normal old every day run of the mill squarish thing that you can stand on.");
            addItem(new class_228(Objects.Basic4BlockCode), "Basic Block 4", "Normal old every day run of the mill squarish thing that you can stand on.");
            addItem(new class_228(Objects.BrickBlockCode), "Brick Block", "A block of poorly mortared bricks that will shatter if it is bumped from below.");
            addItem(new class_228(Objects.FinishBlockCode), "Finish Block", "Bumping this marks the end of the race.");
            addItem(new class_228(Objects.IceBlockCode), "Ice Block", "Sliperyyyyiiiee.");
            addItem(new class_228(Objects.ItemBlockCode), "Item Block", "A block that provides rather lovely and mischievous items when bumped. This can only be used once.");
            addItem(new class_228(Objects.InfItemBlockCode), "Infinite Item Block", "This is an item block that will never run out of items.");
            addItem(new class_228(Objects.LeftBlockCode), "Left Block", "Anyone standing on this will be pushed to the left.");
            addItem(new class_228(Objects.RightBlockCode), "Right Block", "Anyone standing on this will be pushed to the right.");
            addItem(new class_228(Objects.UpBlockCode), "Up Block", "Anyone who stands on this will be bumped upwards.");
            addItem(new class_228(Objects.DownBlockCode), "Down Block", "Anyone who stands on this will have difficulty jumping.");
            addItem(new class_228(Objects.MineBlockCode), "Mine Block", "Mines explode rather painfully if you touch them.");
            addItem(new class_228(Objects.CrumbleBlockCode), "Crumble Block", "This will crumble into pieces if it is hit too hard.");
            addItem(new class_228(Objects.VanishBlockCode), "Vanish Block", "Don't stand for too long, or you'll find yourself falling through the floor.");
            addItem(new class_228(Objects.MoveBlockCode), "Move Block", "Where will it end up? Nobody knows! Every so often, this will move one space in a random direction. Use sparingly, too many of these can slow the game down.");
            addItem(new class_228(Objects.WaterBlockCode), "Water Block", "Swim!");
            addItem(new class_228(Objects.RotateRightBlockCode), "Rotate Right Block", "The wheels on the bus go round and round, round and round, round and round.");
            addItem(new class_228(Objects.RotateLeftBlockCode), "Rotate Left Block", "The wheels on the bus go round and round, round and round, round and round.");
            addItem(new class_228(Objects.PushBlockCode), "Push Block", "This block can be pushed around.");
            addItem(new class_228(Objects.HappyBlockCode), "Happy Block", "Bump this to increase your stats for the rest of the race.");
            addItem(new class_228(Objects.SadBlockCode), "Sad Block", "Bumping one of these will decrease your stats for the rest of the race.");
            addItem(new class_228(Objects.SafetyBlockCode), "Safety Net", "Touching this will teleport you back to your last safe location. It's the same as falling off of the course.");
            addItem(new class_228(Objects.HeartBlockCode), "Heart Block", "This block grants you one extra heart in Deathmatch mode, and renders you invincible for five fantastic seconds.");
            addItem(new class_228(Objects.TimeBlockCode), "Time Block", "Adds 10 seconds to your timer.");
            addItem(new class_228(Objects.EggMinionBlockCode), "Egg Minion", "Romps about with evil intent.");
        }

    }
}//package package_14

