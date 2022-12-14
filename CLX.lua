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

local Path = "CLX/"..game.PlaceId.."/chat-"..os.date("%d-%m-%Y-%H-%M-%S")..".log";

local function LogChat(player, message) -- @player: The player who sent the message (PlayerInstance); @message: The message that was sent (string); @channel: The channel that the message was sent in (string)
    local Time = os.date("%H:%M:%S");
    local Name = player.Name;

    -- Capitalise the first letter of the name
    Name = Name:sub(1, 1):upper()..Name:sub(2);

    local UserId = player.UserId;
    local Message = message;
    local Line = "["..Time.."] "..Name.." ("..UserId.."): "..Message;

    -- Write the line to the file
    local str = readfile(Path);
    writefile(Path, str.."\n"..Line);

    -- Check if the string is too long (Character limit is 40000)
    if #str > 40000 then
        -- Create a new file
        Path = "CLX/"..game.PlaceId.."/chat-"..os.date("%d-%m-%Y-%H-%M-%S")..".log";
        game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
            Text = "[CLX] Previous file reached character limit, creating new file\n"..Path;
            Color = Color3.fromRGB(255, 127, 0);
        });

        -- Write the generation message to the file
        local str = "This chatlog has been generated with CLX 1.0.3 by Sezei#3061\nTIP: As a game admin, any message here could be edited, so please do take everything logged here with a grain of salt.\n\nThis is a continuation of a previous file.\n\nLog generated by "..game:GetService("Players").LocalPlayer.Name.." ("..game:GetService("Players").LocalPlayer.UserId..") in "..game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name.." ("..game.PlaceId..")\n\nChat format: [HH:MM:SS] PlayerName (UserId): Message\n";
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
    local str = "This chatlog has been generated with CLX 1.0.3 by Sezei#3061\nTIP: As a game admin, any message here could be edited, so please do take everything logged here with a grain of salt.\n\nLog generated by "..game:GetService("Players").LocalPlayer.Name.." ("..game:GetService("Players").LocalPlayer.UserId..") in "..game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name.." ("..game.PlaceId..")\n\nChat format: [HH:MM:SS] PlayerName (UserId): Message\n";
    writefile(Path, str);
end;

-- Bind to the chat
local boundplayers = {};

game:GetService("Players").PlayerAdded:Connect(function(player)
    if boundplayers[player.UserId] then return end
    boundplayers[player.UserId] = true
    player.Chatted:Connect(function(message)
        LogChat(player, message, "All");
    end);
end);

for _,v in pairs(game:GetService("Players"):GetPlayers()) do
    if boundplayers[v.UserId] then return end
    boundplayers[v.UserId] = true
    v.Chatted:Connect(function(message, receiver)
        if receiver then
            LogChat(v, message, "Whisper to "..receiver.Name .. " ("..receiver.UserId..")");
        else
            LogChat(v, message, "All");
        end;
    end);
end;

game:GetService("Players").PlayerRemoving:Connect(function(player)
    boundplayers[player.UserId] = nil;
end);

-- Notify the user that the script is running using a chat message
game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
    Text = "[CLX] Running! Chat will be saved to\n"..Path;
    Color = Color3.fromRGB(255, 255, 0);
});
