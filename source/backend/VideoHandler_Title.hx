package backend;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import hxvlc.flixel.FlxVideoSprite;
import openfl.events.Event;

class VideoHandler_Title
{
    public var video:FlxVideoSprite;
    public var canSkip:Bool = true;
    public var canUseSound:Bool = true;
    public var canUseAutoResize:Bool = true;

    public var openingCallback:Void->Void = null;
    public var finishCallback:Void->Void = null;

    public var isPlaying(get, never):Bool;
    public var bitmapData(get, never):openfl.display.BitmapData;
    public var volume(get, set):Int;
    public var alpha(get, set):Float;
    public var width(get, set):Float;
    public var height(get, set):Float;
    public var x(get, set):Float;
    public var y(get, set):Float;

    private var pauseMusic:Bool = false;
    private var videoWidth:Int = 0;
    private var videoHeight:Int = 0;
    private var isAdded:Bool = false;

    public function new(IndexModifier:Int = 0):Void
    {
        video = new FlxVideoSprite();
        video.antialiasing = true;
        
        video.bitmap.onFormatSetup.add(function()
        {
            trace("the video is opening!");
            if (video.bitmap != null && video.bitmap.bitmapData != null)
            {
                videoWidth = video.bitmap.bitmapData.width;
                videoHeight = video.bitmap.bitmapData.height;
                
                if (canUseAutoResize)
                {
                    var scale:Float = Math.min(FlxG.width / videoWidth, FlxG.height / videoHeight);
                    video.setGraphicSize(Std.int(videoWidth * scale), Std.int(videoHeight * scale));
                    video.updateHitbox();
                    video.screenCenter();
                }
            }
            
            if (openingCallback != null)
                openingCallback();
        });
        
        video.bitmap.onEndReached.add(function()
        {
            if (FlxG.sound.music != null && pauseMusic)
                FlxG.sound.music.resume();

            if (finishCallback != null)
                finishCallback();
                
            video.destroy();
        });

        video.bitmap.onEncounteredError.add(function(err:String)
        {
            trace("VLC Error: " + err);
            if (finishCallback != null)
                finishCallback();
            video.destroy();
        });

        FlxG.stage.addEventListener(Event.ENTER_FRAME, update);
    }

    public function playVideo(Path:String, Loop:Bool = false, PauseMusic:Bool = false, Width:Int = 0, Height:Int = 0):Void
    {
        this.pauseMusic = PauseMusic;

        if (!isAdded)
        {
            FlxG.state.add(video);
            isAdded = true;
        }

        if (FlxG.sound.music != null && PauseMusic)
            FlxG.sound.music.pause();

        if (video.load(Path))
        {
            video.play();
        }
        else
        {
            trace("Failed to load video: " + Path);
        }
    }

    private function update(?E:Event):Void
    {
        #if FLX_KEYBOARD
        if (canSkip && FlxG.keys.justPressed.SPACE && video.bitmap != null && video.bitmap.isPlaying)
        {
            if (FlxG.sound.music != null && pauseMusic)
                FlxG.sound.music.resume();
            video.destroy();
            if (finishCallback != null)
                finishCallback();
        }
        #end

        #if FLX_SOUND_SYSTEM
        if (video.bitmap != null)
            video.bitmap.volume = Std.int(((FlxG.sound.muted || !canUseSound) ? 0 : 1) * (FlxG.sound.volume * 100));
        #else
        if (video.bitmap != null)
            video.bitmap.volume = FlxG.sound.volume * 100;
        #end
    }

    public function resume():Void
    {
        if (video.bitmap != null)
            video.resume();
    }

    public function pause():Void
    {
        if (video.bitmap != null)
            video.pause();
    }

    public function dispose():Void
    {
        video.destroy();
        isAdded = false;
    }

    public function finishVideo():Void
    {
        video.destroy();
        isAdded = false;
    }

    private function get_isPlaying():Bool 
    {
        if (video.bitmap != null)
            return video.bitmap.isPlaying;
        return false;
    }
    
    private function get_bitmapData():openfl.display.BitmapData 
    {
        if (video.bitmap != null)
            return video.bitmap.bitmapData;
        return null;
    }
    
    private function get_volume():Int 
    {
        if (video.bitmap != null)
            return Std.int(video.bitmap.volume);
        return 0;
    }
    
    private function set_volume(v:Int):Int 
    {
        if (video.bitmap != null)
            video.bitmap.volume = v;
        return v;
    }
    
    private function get_alpha():Float return video.alpha;
    private function set_alpha(v:Float):Float return video.alpha = v;
    private function get_width():Float return video.width;
    private function set_width(v:Float):Float return video.width = v;
    private function get_height():Float return video.height;
    private function set_height(v:Float):Float return video.height = v;
    private function get_x():Float return video.x;
    private function set_x(v:Float):Float return video.x = v;
    private function get_y():Float return video.y;
    private function set_y(v:Float):Float return video.y = v;
}

class VideoSprite extends FlxSprite
{
    public var bitmap:VideoHandler_Title;
    public var openingCallback:Void->Void = null;
    public var finishCallback:Void->Void = null;
    
    public var newWidth:Int = 0;
    public var newHeight:Int = 0;
    
    public function new(X:Float = 0, Y:Float = 0, Width:Int = 1280, Height:Int = 720)
    {
        super(X, Y);
        
        newWidth = Width;
        newHeight = Height;
        
        makeGraphic(1, 1, FlxColor.TRANSPARENT);

        bitmap = new VideoHandler_Title();
        bitmap.alpha = 0;
        bitmap.openingCallback = function()
        {
            bitmap.alpha = 1;
            if (openingCallback != null)
                openingCallback();
        };
        bitmap.finishCallback = function()
        {
            if (finishCallback != null)
                finishCallback();
            kill();
        };
    }

    override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (bitmap.isPlaying && bitmap.bitmapData != null)
        {
            pixels = bitmap.bitmapData;
            
            var size:Float = Math.min(newWidth / bitmap.bitmapData.width, newHeight / bitmap.bitmapData.height);
            scale.set(size, size);
            updateHitbox();
        }
    }

    public function playVideo(Path:String, Loop:Bool = false, PauseMusic:Bool = false):Void
    {
        bitmap.playVideo(Path, Loop, PauseMusic, newWidth, newHeight);
    }
}