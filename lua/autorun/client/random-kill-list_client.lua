
-- make changes here
local config = {
    SEND_KEY = "SHJKDGKASJDHSKLADG&@%&DSKLJAHLBDKBA<SBD",
    title = "RANDOM KILL LIST",
    webaddress = "http://rkl.semklauke.de"
}

local voteFrame = {}

local function sendTraitorVote(vote)
    if type(vote) == "boolean" then
        net.Start("RKL_TraitorVoted")
        net.WriteString(config.SEND_KEY)
        net.WriteBool(vote)
        net.SendToServer()
    end
end

local function sendUserVote(vote, steamid)
    if type(vote) == "boolean" then
        net.Start("RKL_UserVoted")
        net.WriteString(config.SEND_KEY)
        net.WriteString(steamid)
        net.WriteBool(vote)
        net.SendToServer()
    end
end

local function showTheListPanel()

    local frame = vgui.Create( "DFrame" )
    frame:SetSize( 330, 600 )
    frame:SetTitle(config.title)
    frame:SetVisible( true )
    frame:SetDraggable( true )
    frame:Center()
    --Fill the form with a html page
    local html = vgui.Create( "DHTML" , frame )
    html:Dock( FILL )
    html:OpenURL(config.webaddress)

    html:SetAllowLua( true )

    frame:MakePopup()
end

local function showTraitorVoteMenu()
    local frame = vgui.Create("DFrame")
    frame:SetSize(210, 90)
    frame:SetPos( ScrW() * 0.1, ScrH() * 0.3)
    frame:SetTitle(config.title)
    frame:SetVisible(true)
    frame:SetDraggable(true)
    frame:ShowCloseButton(false)
    frame.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, 300, 210, Color(115, 115, 115, 170))
    end
    frame:MakePopup()

    local DLabel = vgui.Create("DLabel", frame)
    DLabel:SetPos(16, 20)
    DLabel:SetColor(Color(255, 255, 255 ))
    DLabel:SetText("Did you get Random Killed ?")
    DLabel:SizeToContents()

    local YesButton = vgui.Create( "DButton", frame ) 
    YesButton:SetText( "YES" )                  
    YesButton:SetPos(15, 45)                    
    YesButton:SetSize(70, 30)
    YesButton:SetTextColor(Color(0, 135, 2))
    YesButton.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color( 37, 37, 37, 250))
    end             
    YesButton.DoClick = function()              
        sendTraitorVote(true)
        frame:Close()           
    end

    local NoButton = vgui.Create( "DButton", frame ) 
    NoButton:SetText( "NO" )                    
    NoButton:SetPos(100, 45)                    
    NoButton:SetSize(70, 30)
    NoButton:SetTextColor(Color(206, 0, 2))
    NoButton.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color( 37, 37, 37, 250))
    end                 
    NoButton.DoClick = function()               
        sendTraitorVote(false)
        frame:Close()           
    end

end

local function showUserVoteMenu(victim, steamid)
    voteFrame[steamid] = vgui.Create("DFrame")
    voteFrame[steamid]:SetSize(250, 90)
    voteFrame[steamid]:SetPos( ScrW() * 0.1, ScrH() * 0.4)
    voteFrame[steamid]:SetTitle(config.title)
    voteFrame[steamid]:SetVisible(true)
    voteFrame[steamid]:SetDraggable(true)
    voteFrame[steamid]:ShowCloseButton(false)
    voteFrame[steamid].Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(206, 0, 10, 180))
    end
    voteFrame[steamid]:MakePopup()

    local DLabel = vgui.Create("DLabel", voteFrame[steamid])
    DLabel:SetPos(16, 20)
    DLabel:SetColor(Color(255, 255, 255 ))
    local text = "Did " .. victim .. " get Random killed ?"
    DLabel:SetText(text)
    DLabel:SizeToContents()

    local YesButton = vgui.Create( "DButton", voteFrame[steamid] ) 
    YesButton:SetText( "YES" )                  
    YesButton:SetPos(15, 45)                    
    YesButton:SetSize(70, 30)
    YesButton:SetTextColor(Color(0, 135, 2))
    YesButton.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color( 37, 37, 37, 200))
    end             
    YesButton.DoClick = function()              
        sendUserVote(true, steamid)
        voteFrame[steamid]:Close()
        voteFrame[steamid] = nil;       
    end

    local NoButton = vgui.Create( "DButton", voteFrame[steamid] ) 
    NoButton:SetText( "NO" )                    
    NoButton:SetPos(100, 45)                    
    NoButton:SetSize(70, 30)
    NoButton:SetTextColor(Color(206, 0, 2))
    NoButton.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color( 37, 37, 37, 150))
    end                 
    NoButton.DoClick = function()               
        sendUserVote(false, steamid)
        voteFrame[steamid]:Close()
        voteFrame[steamid] = nil;           
    end

end

-- game hooks --

-- for debugging
hook.Add("OnPlayerChat", "HelloCommand", function( ply, strText, bTeam, bDead ) 
    if strText == "!rkl_uVote" then
        showUserVoteMenu("a", "b")
    elseif strText == "!rkl_tVote" then
        showTraitorVoteMenu()
    end
end )


-- network recives --

net.Receive("RKL_StopVote", function()
    local steamid = net.ReadString()
    if voteFrame[steamid] ~= nil then
        voteFrame[steamid]:Close()
    end
end )

net.Receive("RKL_AskTraitor", function()
     showTraitorVoteMenu()
end )

net.Receive("RKL_AskEverybody", function()
    local vicName = net.ReadString()
    local vicSteamID = net.ReadString()
    showUserVoteMenu(vicName, vicSteamID)
end )

net.Receive("RKL_TheListPanel", function()
     showTheListPanel()
end )