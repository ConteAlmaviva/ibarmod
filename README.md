This is a modified version of the excellent `ibar` addon originally written by Vicrelant, which can be found [here](https://git.ashitaxi.com/Addons/ibar).  This version essentially combines ibar with the [checker](https://git.ashitaxi.com/Addons/checker) addon created by atom0s and Lolwutt.  It adds an automatic check function so in addition to the mob level range, you get the specific level of the mob you have targeted.  The original addon looks something like this:

![Original_example_shot](/screenshots/ex1.png)

The modified version looks like this:

![Modified_example_shot](/screenshots/ex2.png)

For NMs, it will only display (NM).

There's some logic built-in to the addon to send check packets when you change to a new target whose level isn't yet known (that is, you haven't checked it yet).  After a single check packet is sent, a block flag is put in place to prevent spamming the server with check packets.  The block is lifted after one second, by which time your client should have received the check response, and at that point, no further check packets should be sent until a new target is acquired.  This should generally get you specific level info on your current target, but if you are quickly cycling through targets it is possible to have the info from your previous target show up erroneously; swapping to a different target and back should correct this.

To prevent your chatlog from getting spammed every time your target changes, the addon blocks the check packet from the FFXI client so the strength and parameters message is suppressed.  If, however, you initiate a check in the game (either with a chat command `/check` or via the target menu), the chat message will not be suppressed.

If you use Byrth's Battlemod addon (originally for Windower, shimmed to Ashita by farmboy0), from what I can tell it doesn't respect the `blocked` parameter in Ashita's incoming packet function (this may be true for any Windower-shimmed addon).  As a result, you'll get the aforementioned chat spam.  To alleviate this, there's a modified `battlemod.lua` in this repo that ignores check messages.  Rename your existing `battlemod.lua` to something like `battlemod.lua.old` as a precaution, and put this one into the same folder.  Alternatively, if you just want to edit your existing `battlemod.lua`, comment out the `if` block of `if am.message_id > 169 and am.message_id <179 then` and add the following function below it:

```
            if (am.message_id > 169 and am.message_id <179) or (am.message_id == 249) then
                return false;
            end
``` 

![Modified_battlemod](/screenshots/battlemod_comment.png)

Finally, this also allows you to put the level of your current target in chat with %%level%%, similar to how \<t\> will put the name of your current target in chat.  This can be useful for EXP and merit parties, letting other party members know what to expect in terms of mob difficulty and EXP/LP gain.  See below:

![party_message](/screenshots/current_target_level.png)
