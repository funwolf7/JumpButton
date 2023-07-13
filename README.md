[ReleasesPage]: https://github.com/funwolf7/JumpButton/releases
[ModelPage]: https://www.roblox.com/library/14052977941

# JumpButton
A simple library for detecting when the local player is holding the jump button in Roblox, with support for buffered inputs.

- [Download the latest release][ReleasesPage]
- [Installation steps](#installation)
- [Recommended usage](#usage)
- [View the api](#api)

## Why JumpButton?
Roblox does not provide a good API method to listen for the jump button being held. Popular (but flawed) methods include:
- Listening for spacebar presses
	- This doesn't support mobile or gamepad devices
- `UserInputService.JumpRequest`
	- This fires several times after a jump, leading to the implementation of a debounce, which can be infuriating when rapidly pressing jump
	- The amount of time it fires afterwards is random, leading to inconsistent "jump buffering"

JumpButton instead uses the `Humanoid.Jump` property. This is a viable option because it is what the ControlModule sets every frame. JumpButton reads this property every frame right after the ControlModule runs and checks if the property has changed since the last frame.

**Note:** JumpButton does not listen for changes with an event, as `Humanoid.Jump` rapidly changes when the user jumps, which would ruin the library.

JumpButton also includes support for consistent jump buffering. Input buffering is something that many games will do to make the game easier or more enjoyable. Specifically, if you press a button when it would do nothing, then it changes and would now do an action upon pressing it, it will automatically do the action. The window in which you are allowed to press the button early varies from game to game, from almost no window to unlimited time.

## Downsides
JumpButton has a few minor downsides:
- It only works when a humanoid exists. When no humanoid exists, JumpButton will remain in the state it last was.
- It will not detect inputs where the player pressed and released the jump button in the same frame.
	- `UserInputService.JumpRequest` has the same issue, so this likely isn't too big of a problem.

## Installation
**Note:** JumpButton can only run on the client
> ### In studio:
> Insert the [model][ModelPage] into some place accessible to the client.

> ### External Editor:
> Download the `JumpButton.luau` file from the [latest release][ReleasesPage] and insert it into your project in a place accessible to the client.

Once installed, regardless of method, simply `require` the ModuleScript, and you now have access to the functions it provides.

## Usage

### Basic usage
If you do not wish to use buffering, using the library is simple. You will only need a few functions.
- [`JumpButton.OnPress`](#jumpbuttononpress) is an `RBXScriptSignal` that you can Connect to which will fire whenever the jump button is pressed.
- [`JumpButton.OnRelease`](#jumpbuttononrelease) is an `RBXScriptSignal` that you can Connect to which will fire whenever the jump button is released.
- [`JumpButton.isPressed()`](#jumpbuttonispressed) can tell you if the jump button is currently being held.

### Advanced usage (buffering)
When using buffering, it gets a bit more complicated.

Every time the jump button is pressed, JumpButton stores the timestamp (using `os.clock`), at which it was last pressed. This timestamp is set to nil when the jump button is released or when the buffer is killed (more on killing the buffer below).

When an action that uses the jump button gets enabled, you should retrieve the buffer start using [`JumpButton.useBufferStart()`](#jumpbuttonusebufferstart), which returns the stored timestamp. (**Note:** only call this function once per action, and store the value if needed, as it will return nil the second time it is called. More information on why this occurs in the "Killing the buffer" section.)

If there is an unlimited buffer window (the button press can happen an unlimited amount of time before the action), then simply checking if the timestamp exists is enough. If there is a limit to the amount of time after the press, you must check first that it exists, and also that less time has passed since the buffer than the buffer duration.
```lua
local BufferDuration = 0.1

local currentBufferStart = JumpButton.useBufferStart()
if currentBufferStart and os.clock() - currentBufferStart <= BufferDuration then
	print("buffered, immediately perform the action")
else
	print("not buffered, wait for a jump press to perform the action")
end
```
If the check passes, then you should immediately perform whatever action was just enabled.

When using JumpButton, you may find yourself using the same time window for most actions. If this is the case, then you can use [`JumpButton.setDefaultBufferDuration(newBufferDuration)`](#jumpbuttonsetdefaultbufferduration) to set a default duration, and then use [`JumpButton.useIsBuffered()`](#jumpbuttonuseisbuffered), which will automatically perform the time check based on the default buffer duration that has been set, returning true if it passes and false if not. If the default buffer duration is set to nil, then it will only check if the buffer start exists, allowing for an unlimited buffer duration.

#### Killing the buffer:
An important idea with buffering is that one press of the button should only trigger one action. To allow for this, JumpButton implements ways to "kill" the buffer. This simply sets the buffer timestamp to nil, making it so that further checks of the buffer start will not cause more actions. You can manually kill the buffer by calling [`JumpButton.killBuffer()`](#jumpbuttonkillbuffer).

In order to make it easier for developers, all `use` functions (`JumpButton.useBufferStart` and `JumpButton.useIsBuffered`) automatically kill the buffer when called. The idea behind this is that if an action is checking the buffer, then most likely it will perform an action if the buffer timestamp exists, thus the buffer should be killed. If you wish to check the buffer timestamp without killing it, you can use `peek` functions ([`JumpButton.peekBufferStart()`](#jumpbuttonpeekbufferstart) and [`JumpButton.peekIsBuffered()`](#jumpbuttonpeekisbuffered)), which return the same things as their counterparts but without killing the buffer.

This also has the side effect that the `use` functions will return nil the second time if called twice in a row. If you need to use the result of these functions in multiple places, you should store the result as a variable and use the variable instead.

#### Automatic buffer killing:
The humanoid jumping is an action triggered by the jump button, so JumpButton automatically listens for `Humanoid.Jumping` and kills the buffer whenever it fires. If this is not desireable, you can call [`JumpButton.setAutoKillOnJump(false)`](#jumpbuttonsetautokillonjump) to disable this feature.

## API

### JumpButton.OnPress
```
JumpButton.OnPress: RBXScriptSignal
```
An `RBXScriptSignal` that fires whenever the result of [`JumpButton.isPressed`](#jumpbuttonispressed) changes from false to true.

### JumpButton.OnRelease
```
JumpButton.OnRelease: RBXScriptSignal
```
An `RBXScriptSignal` that fires whenever the result of [`JumpButton.isPressed`](#jumpbuttonispressed) changes from true to false.

### JumpButton.isPressed
```
JumpButton.isPressed(): boolean
```
Returns true if the jump button is currently being held down, false otherwise.

### JumpButton.useIsBuffered
```
JumpButton.useIsBuffered(): boolean
```
Returns whether or not there is a buffer, based on the default buffer duration. Specifically, if the time since the buffer began is less than or equal to the default buffer duration. If there is no default buffer duration, it will return true if there is a buffer start, false otherwise.

This function will automatically kill the buffer. If you do not wish to do so, use [`JumpButton.peekIsBuffered`](#jumpbuttonpeekisbuffered).

### JumpButton.peekIsBuffered
```
JumpButton.peekIsBuffered(): boolean
```
Returns whether or not there is a buffer, based on the default buffer duration. Specifically, if the time since the buffer began is less than or equal to the default buffer duration. If there is no default buffer duration, it will return true if there is a buffer start, false otherwise.

This function will not affect the buffer start. If you want to automatically kill the buffer, use [`JumpButton.useIsBuffered`](#jumpbuttonuseisbuffered).

### JumpButton.useBufferStart
```
JumpButton.useBufferStart(): number?
```
Returns the current buffer start, if any. The buffer start is a timestamp from `os.clock`. It is not affected by the default buffer duration.

This function will automatically kill the buffer. If you do not wish to do so, use [`JumpButton.peekBufferStart`](#jumpbuttonpeekbufferstart).

### JumpButton.peekBufferStart
```
JumpButton.peekBufferStart(): number?
```
Returns the current buffer start, if any. The buffer start is a timestamp from `os.clock`. It is not affected by the default buffer duration.

This function will not affect the buffer start. If you want to automatically kill the buffer, use [`JumpButton.useBufferStart`](#jumpbuttonusebufferstart).

### JumpButton.killBuffer
```
JumpButton.killBuffer(): ()
```
Sets the current buffer start to nil, effectively preventing code from detecting a buffer. It will be set to a number when the jump button is pressed again.

### JumpButton.setDefaultBufferDuration
```
JumpButton.setDefaultBufferDuration(newBufferDuration: number?): ()
```
Sets the default buffer duration for the library. The default buffer duration is used for [`JumpButton.useIsBuffered`](#jumpbuttonuseisbuffered) and [`JumpButton.peekIsBuffered`](#jumpbuttonpeekisbuffered). If `newBufferDuration` is nil, these functions will not have a maximum time.

### JumpButton.setAutoKillOnJump
```
JumpButton.setAutoKillOnJump(shouldAutoKill: boolean): ()
```
Sets if JumpButton should automatically kill the buffer when `Humanoid.Jumping` fires on the local player's humanoid. Defaults to true.