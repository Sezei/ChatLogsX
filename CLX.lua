-- This is a script for SynapseX that will log the chat of the game you are in.
-- The chat will be saved as a file in SynapseX > workspace > CLX > gameid > chat-dd-mm-yyyy-hh-mm-ss.log
-- This uses the readfile, writefile, os.date, and os.time functions.

-- The logs support the 'ml' markdown in Discord!
-- To use it, paste the chat log into your message, and surround it with ```ml
-- Example:
--[[
```ml
[12:00:00] Player1 (123456789): Hello!
[12:00:01] Player2 (987654321): Hi!
```
]]

local Version = "1.1.1";

local Settings = {
    File = {
        NamePrefix = "chat-"; -- The prefix of the file name
        NameSuffix = ""; -- The suffix of the file name
        NameExtension = ".log"; -- The extension of the file name
    };
    Logging = {
        LogWhispers = false; -- Whether or not to log whispers (private messages; prefixed with /w)
        LogJoinLeave = false; -- Whether or not to log when players join and leave the game
    };
    Formatting = {
        -- Available placeholders: time, name, displayname, userid, message
        Chat = "[<time>] <name> (<userid>): <message>";

        -- Available placeholders: time, name, displayname, userid, message, target_name, target_displayname, target_userid
        Whisper = "[<time>] <name> (<userid>) -> <target_name> (<target_userid>): <message>";

        -- Available placeholders: time, name, displayname, userid
        Join = "[<time>] SYSTEM: <name> (<userid>) has joined the game.";
        Leave = "[<time>] SYSTEM: <name> (<userid>) has left the game.";
    };

    FileGeneration = {
        -- This message will be written to the file when it is created
        -- Available placeholders: localname, localuserid, gamename, gameid, filename, chatformat
        Message = "This chatlog has been generated with CLX "..Version.." by Sezei\nTIP: As a game admin, any message here could be edited, so please do take everything logged here with a grain of salt.\n\nLog generated by <name> (<userid>) in <gamename> (<gameid>)\n\nChat format used: <chatformat>\n";

        -- The character limit of the file
        -- The safe character limit is 20K if the player lags
        -- It is not recommended to go above 50K
        CharacterLimit = 20000;

        -- The following do not use any placeholders
        Continuation = "\nThis is a continuation of a previous file.\n"; -- This message will be written to the file when it is created as a continuation of a previous file (due to the character limit)
        EndOfFile = "\n\n== LOG CLOSED DUE TO REACH OF CHARACTER LIMIT =="; -- This message will be written to the file when it reaches the character limit
    };
};

function Format(Original,ReplacementData) -- Taken from Redefine:A5's PlaceholderAPI.
    local s:string = tostring(Original);

    for old,new in pairs(ReplacementData) do
        s = s:gsub("<"..old..">",tostring(new));
    end

    return s;
end

local Path = "CLX/"..game.PlaceId.."/"..Settings.File.NamePrefix..os.date("%d-%m-%Y-%H-%M-%S")..Settings.File.NameSuffix..Settings.File.NameExtension;

local function LogChat(Line) -- @message: The message to log (string)
    local Time = os.date("%H:%M:%S");

    -- Write the line to the file
    local str = readfile(Path);
    writefile(Path, str.."\n"..Line);

    -- Check if the string is too long (The safe character limit is 20K if the player lags)
    if #str > Settings.FileGeneration.CharacterLimit then
        -- Write the end of file message to the file
        writefile(Path, str..Settings.FileGeneration.EndOfFile);

        -- Create a new file
        Path = "CLX/"..game.PlaceId.."/"..Settings.File.NamePrefix..os.date("%d-%m-%Y-%H-%M-%S")..Settings.File.NameSuffix..Settings.File.NameExtension;
        game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
            Text = "[CLX] Previous file reached character limit, creating new file\n"..Path;
            Color = Color3.fromRGB(255, 127, 0);
        });

        -- Write the generation message to the file
        local str = Format(Settings.FileGeneration.Message, {
            localname = game:GetService("Players").LocalPlayer.Name;
            localuserid = game:GetService("Players").LocalPlayer.UserId;
            gamename = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name;
            gameid = game.PlaceId;
            filename = Path;
            chatformat = Settings.Formatting.Chat;
        });

        str ..= Settings.FileGeneration.Continuation;
        writefile(Path, str);
    end;
end

-- Create the path if it doesn't exist
if not isfolder("CLX") then
    makefolder("CLX");
end;
if not isfolder("CLX/"..game.PlaceId) then
    makefolder("CLX/"..game.PlaceId);
end;

-- Create the file if it doesn't exist
if not isfile(Path) then
    -- Create the file
    writefile(Path, "");

    -- Write the generation message to the file
    local str = Format(Settings.FileGeneration.Message, {
        localname = game:GetService("Players").LocalPlayer.Name;
        localuserid = game:GetService("Players").LocalPlayer.UserId;
        gamename = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name;
        gameid = game.PlaceId;
        filename = Path;
        chatformat = Settings.Formatting.Chat;
    });
    writefile(Path, str);
end;

-- Bind to the chat
local boundplayers = {};

game:GetService("Players").PlayerAdded:Connect(function(player)
    if boundplayers[player.UserId] then return end
    boundplayers[player.UserId] = true
    local Name = player.Name;
    local DisplayName = player.DisplayName;
    local UserId = player.UserId;
    player.Chatted:Connect(function(message)
        -- Check if the message is a whisper (starts with /w)
        if Settings.Logging.LogWhispers and message:sub(1, 2) == "/w" then
            -- Get the target
            local Target = message:sub(4):split(" ")[1];
            local TargetPlayer = game:GetService("Players"):FindFirstChild(Target);
            if TargetPlayer then
                -- Get the target's name and display name
                local TargetName = TargetPlayer.Name;
                local TargetDisplayName = TargetPlayer.DisplayName;
                local TargetUserId = TargetPlayer.UserId;

                -- Log the message
                LogChat(Format(Settings.Formatting.Whisper, {
                    time = os.date("%H:%M:%S");
                    name = Name;
                    displayname = DisplayName;
                    userid = UserId;
                    message = message:sub(4 + #Target + 1);
                    target_name = TargetName;
                    target_displayname = TargetDisplayName;
                    target_userid = TargetUserId;
                }));
            end;
        else
            -- Log the message
            LogChat(Format(Settings.Formatting.Chat, {
                time = os.date("%H:%M:%S");
                name = Name;
                displayname = DisplayName;
                userid = UserId;
                message = message;
            }));
        end;
    end);

    -- Log the join if enabled
    if Settings.Logging.LogJoinLeave then
        LogChat(Format(Settings.Formatting.LogJoinLeave, {
            time = os.date("%H:%M:%S");
            name = Name;
            displayname = DisplayName;
            userid = UserId;
        }));
    end;
end);

for _,player in pairs(game:GetService("Players"):GetPlayers()) do
    if boundplayers[player.UserId] then return end
    boundplayers[player.UserId] = true
    local Name = player.Name;
    local DisplayName = player.DisplayName;
    local UserId = player.UserId;
    player.Chatted:Connect(function(message)
        -- Check if the message is a whisper (starts with /w)
        if Settings.Logging.LogWhispers and message:sub(1, 2) == "/w" then
            -- Get the target
            local Target = message:sub(4):split(" ")[1];
            local TargetPlayer = game:GetService("Players"):FindFirstChild(Target);
            if TargetPlayer then
                -- Get the target's name and display name
                local TargetName = TargetPlayer.Name;
                local TargetDisplayName = TargetPlayer.DisplayName;
                local TargetUserId = TargetPlayer.UserId;

                -- Log the message
                LogChat(Format(Settings.Formatting.Whisper, {
                    time = os.date("%H:%M:%S");
                    name = Name;
                    displayname = DisplayName;
                    userid = UserId;
                    message = message:sub(4 + #Target + 1);
                    target_name = TargetName;
                    target_displayname = TargetDisplayName;
                    target_userid = TargetUserId;
                }));
            end;
        else
            -- Log the message
            LogChat(Format(Settings.Formatting.Chat, {
                time = os.date("%H:%M:%S");
                name = Name;
                displayname = DisplayName;
                userid = UserId;
                message = message;
            }));
        end;
    end);

    -- No need to log the join, the player is already in the game
end;

game:GetService("Players").PlayerRemoving:Connect(function(player)
    boundplayers[player.UserId] = nil;

    -- Log the leave if enabled
    if Settings.Logging.LogJoinLeave then
        LogChat(Format(Settings.Formatting.LogJoinLeave, {
            time = os.date("%H:%M:%S");
            name = player.Name;
            displayname = player.DisplayName;
            userid = player.UserId;
        }));
    end;
end);

-- Notify the user that the script is running using a chat message
game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
    Text = "[CLX] Running! Chat will be saved to\n"..Path.."\nCLX Version: "..Version;
    Color = Color3.fromRGB(255, 255, 0);
});

local function ChangeSetting(settingtochange, newvalue)
    -- Search all the settings to match the setting to change
    -- Split the setting into 2 with '.' as the delimiter
    local set = settingtochange:split(".");
    local category = set[1];
    local setting = set[2];

    -- Check if the category exists
    if Settings[category] then
        -- Check if the setting exists
        if type(Settings[category][setting]) ~= "nil" then
            -- Change the setting
            Settings[category][setting] = newvalue;
        else
            -- Notify the user that the setting doesn't exist
            game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                Text = "[CLX] Setting "..settingtochange.." doesn't exist!";
                Color = Color3.fromRGB(255, 0, 0);
            });
        end;
    else
        game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
            Text = "[CLX] Category "..Category[1].." doesn't exist!";
            Color = Color3.fromRGB(255, 0, 0);
        });
    end;

    return ChangeSetting; -- Return the function so it can be used like ChangeSetting("Category.Setting", true)("Category.Setting", false);
end

return ChangeSetting;
