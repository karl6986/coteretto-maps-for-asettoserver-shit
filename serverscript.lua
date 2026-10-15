-- Server Chat / Vote Helper
-- M = toggle menu
-- A = /accept
--
-- Detects dynamic /vt numbers from server messages.
--
-- After "Vote for next track", ALL following messages
-- are scanned until voting ends.
--
-- If exactly ONE of the 6 normal tracks is missing,
-- that track becomes "Keep on current track" and uses /vt 0.
--
-- /vt 0 = Stay on current track


--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local settings = ac.storage({
    menuVisible = false
})


--------------------------------------------------
-- VARIABLES
--------------------------------------------------

local aWasDown = false
local mWasDown = false

local chatMessages = {}
local shutdownTimer = nil


--------------------------------------------------
-- CURRENT VOTE COMMANDS
--------------------------------------------------

local voteCommands = {
    Rally = nil,
    Gokart = nil,
    BurnoutParadise = nil,
    ["Brooklyn Park"] = nil,
    ["Union Island"] = nil,
    Drift = nil
}


--------------------------------------------------
-- VOTE SCANNING
--------------------------------------------------

local scanningVotes = false


--------------------------------------------------
-- VOTING AVAILABLE
--------------------------------------------------

local votingAvailable = false


--------------------------------------------------
-- /VT 0 DETECTED
--------------------------------------------------

local stayOnCurrentTrackDetected = false


--------------------------------------------------
-- WHICH TRACK IS ACTUALLY "KEEP CURRENT"?
--------------------------------------------------

local keepCurrentTrack = nil


--------------------------------------------------
-- VOTES
--------------------------------------------------

local votes = {
    { name = "Rally", commandName = "Rally" },
    { name = "Gokart", commandName = "Gokart" },
    { name = "BurnoutParadise", commandName = "BurnoutParadise" },
    { name = "Brooklyn Park", commandName = "Brooklyn Park" },
    { name = "Union Island", commandName = "Union Island" },
    { name = "Drift", commandName = "Drift" }
}


--------------------------------------------------
-- NORMALIZE TRACK NAME
--------------------------------------------------

local function normalizeTrackName(name)

    name = tostring(name):lower()

    -- Remove spaces
    name = name:gsub("%s+", "")

    -- Remove - and _
    name = name:gsub("[%-%_]", "")

    -- Remove .
    name = name:gsub("%.", "")

    return name

end


--------------------------------------------------
-- FIND WHICH TRACK THIS IS
--------------------------------------------------

local function getTrackName(name)

    local normalized = normalizeTrackName(name)


    if normalized == "rally" then
        return "Rally"
    end


    if normalized == "gokart" then
        return "Gokart"
    end


    if normalized == "gokarting" then
        return "Gokart"
    end


    if normalized == "burnoutparadise" then
        return "BurnoutParadise"
    end


    if normalized == "brooklynpark" then
        return "Brooklyn Park"
    end


    if normalized == "unionisland" then
        return "Union Island"
    end


    if normalized == "drift" then
        return "Drift"
    end


    return nil

end


--------------------------------------------------
-- GET MISSING TRACKS
--------------------------------------------------

local function getMissingTracks()

    local missing = {}


    for i = 1, #votes do

        local vote = votes[i]


        if voteCommands[vote.commandName] == nil then

            missing[#missing + 1] =
                vote.commandName

        end

    end


    return missing

end


--------------------------------------------------
-- SCAN ONE VOTE MESSAGE
--------------------------------------------------

local function scanVoteLine(message)

    message = tostring(message)


    ac.log(
        "[VOTE SCAN] Checking: "
        .. message
    )


    --------------------------------------------------
    -- LOOK FOR /VT NUMBER
    --
    -- Examples:
    --
    -- /vt 0 - Stay on current track.
    -- /vt 1 - Union Island
    -- /vt 3 Brooklyn Park
    -- /vt 4 GoKarting
    --------------------------------------------------

    local number, trackName =
        message:match(
            "/vt%s+(%d+)%s*[-:]?%s*(.*)"
        )


    --------------------------------------------------
    -- FALLBACK:
    --
    -- 1 - Rally
    --------------------------------------------------

    if not number then

        number, trackName =
            message:match(
                "(%d+)%s*%-%s*(.+)"
            )

    end


    --------------------------------------------------
    -- NOTHING FOUND
    --------------------------------------------------

    if not number then

        ac.log(
            "[VOTE SCAN] No vote number found"
        )

        return

    end


    number = tonumber(number)


    if not number then
        return
    end


    trackName = tostring(trackName or "")


    --------------------------------------------------
    -- /VT 0
    --------------------------------------------------

    if number == 0 then

        stayOnCurrentTrackDetected = true


        ac.log(
            "[VOTE DETECTED] /vt 0 = Stay on current track"
        )


        return

    end


    --------------------------------------------------
    -- FIND TRACK
    --------------------------------------------------

    local track =
        getTrackName(trackName)


    if not track then

        ac.log(
            "[VOTE SCAN] Number "
            .. tostring(number)
            .. " found, but track was not recognized: "
            .. trackName
        )

        return

    end


    --------------------------------------------------
    -- SAVE COMMAND
    --------------------------------------------------

    voteCommands[track] =
        "/vt " .. tostring(number)


    ac.log(
        "[VOTE DETECTED] "
        .. track
        .. " = /vt "
        .. tostring(number)
    )

end


--------------------------------------------------
-- FINISH VOTE SCAN
--------------------------------------------------

local function finishVoteScan()

    if not scanningVotes then
        return
    end


    scanningVotes = false


    --------------------------------------------------
    -- FIND MISSING NORMAL TRACKS
    --------------------------------------------------

    local missing =
        getMissingTracks()


    ac.log(
        "[VOTE] Missing normal tracks: "
        .. tostring(#missing)
    )


    --------------------------------------------------
    -- EXACTLY ONE TRACK MISSING
    --------------------------------------------------

    if #missing == 1 then

        keepCurrentTrack =
            missing[1]


        voteCommands[keepCurrentTrack] =
            "/vt 0"


        ac.log(
            "[VOTE] ========================================"
        )


        ac.log(
            "[VOTE] ONE TRACK WAS NOT DETECTED"
        )


        ac.log(
            "[VOTE] Current track detected as: "
            .. tostring(keepCurrentTrack)
        )


        ac.log(
            "[VOTE] "
            .. tostring(keepCurrentTrack)
            .. " = /vt 0"
        )


        ac.log(
            "[VOTE] ========================================"
        )


    --------------------------------------------------
    -- MORE THAN ONE TRACK MISSING
    --------------------------------------------------

    elseif #missing > 1 then

        keepCurrentTrack = nil


        ac.log(
            "[VOTE] More than one track is missing."
        )


        ac.log(
            "[VOTE] Cannot safely determine current track."
        )


    --------------------------------------------------
    -- NOTHING MISSING
    --------------------------------------------------

    else

        keepCurrentTrack = nil


        ac.log(
            "[VOTE] All normal tracks detected."
        )

    end


    --------------------------------------------------
    -- FINAL RESULTS
    --------------------------------------------------

    ac.log(
        "========================================"
    )


    ac.log(
        "[VOTE] FINAL RESULTS"
    )


    ac.log(
        "========================================"
    )


    for i = 1, #votes do

        local vote =
            votes[i]


        local command =
            voteCommands[
                vote.commandName
            ]


        if command then

            ac.log(
                "[VOTE RESULT] "
                .. vote.name
                .. " = "
                .. command
            )

        else

            ac.log(
                "[VOTE RESULT] "
                .. vote.name
                .. " = NOT FOUND"
            )

        end

    end


    ac.log(
        "========================================"
    )

end


--------------------------------------------------
-- SEND CHAT COMMAND
--------------------------------------------------

local function sendChat(command)

    if not command then

        ui.toast(
            ui.Icons.Warning,
            "Vote command has not been detected yet!"
        )


        ac.log(
            "Tried to vote, but command was not detected"
        )


        return

    end


    ac.sendChatMessage(command)


    ac.log(
        "Sent vote command: "
        .. command
    )

end


--------------------------------------------------
-- KEYBOARD
--------------------------------------------------

function script.update(dt)

    if shutdownTimer then
        shutdownTimer = shutdownTimer - dt
        if shutdownTimer <= 0 then
            shutdownTimer = nil
            ac.shutdownAssettoCorsa()
        end
    end

    --------------------------------------------------
    -- M = TOGGLE MENU
    --------------------------------------------------

    local mDown =
        ac.isKeyDown(
            string.byte("M")
        )


    if mDown
        and not mWasDown
    then

        settings.menuVisible =
            not settings.menuVisible

    end


    mWasDown = mDown


    --------------------------------------------------
    -- A = /ACCEPT
    --------------------------------------------------

    local aDown =
        ac.isKeyDown(
            string.byte("A")
        )


    if aDown
        and not aWasDown
    then

        sendChat("/accept")

    end


    aWasDown = aDown

end


--------------------------------------------------
-- CHAT MESSAGE
--------------------------------------------------

ac.onChatMessage(function(message, author)

    message = tostring(message)

    if message:find("Track will change in 3 second(s).", 1, true) then
        shutdownTimer = 2
    end


    --------------------------------------------------
    -- DETECT VOTE START
    --------------------------------------------------

    if message:find(
        "Vote for next track",
        1,
        true
    )
    then

        votingAvailable = true

        stayOnCurrentTrackDetected = false
        keepCurrentTrack = nil


        --------------------------------------------------
        -- CLEAR OLD COMMANDS
        --------------------------------------------------

        voteCommands.Rally = nil
        voteCommands.Gokart = nil
        voteCommands.BurnoutParadise = nil
        voteCommands["Brooklyn Park"] = nil
        voteCommands["Union Island"] = nil
        voteCommands.Drift = nil


        --------------------------------------------------
        -- START SCANNING
        --
        -- NO MESSAGE COUNTER.
        -- We scan until "voting ended".
        --------------------------------------------------

        scanningVotes = true


        ui.toast(
            ui.Icons.Confirm,
            "You can vote! Press M or click the button."
        )


        ac.setSystemMessage(
            "You can vote! Press M or click the button."
        )


        ac.log(
            "========================================"
        )


        ac.log(
            "[VOTE] Voting has started!"
        )


        ac.log(
            "[VOTE] Scanning server messages..."
        )


        ac.log(
            "========================================"
        )

    end


    --------------------------------------------------
    -- SCAN EVERY MESSAGE WHILE VOTING
    --------------------------------------------------

    if scanningVotes
        and not message:find(
            "Vote for next track",
            1,
            true
        )
    then

        --------------------------------------------------
        -- FIRST CHECK IF VOTING ENDED
        --------------------------------------------------

        local lowerMessage =
            message:lower()


        local votingEnded =
            lowerMessage:find(
                "voting has ended",
                1,
                true
            )
            or
            lowerMessage:find(
                "voting ended",
                1,
                true
            )
            or
            lowerMessage:find(
                "vote has ended",
                1,
                true
            )
            or
            lowerMessage:find(
                "vote ended",
                1,
                true
            )


        --------------------------------------------------
        -- IF THIS IS THE END MESSAGE
        --------------------------------------------------

        if votingEnded then

            ac.log(
                "[VOTE] Voting ended message detected."
            )


            finishVoteScan()


        else

            --------------------------------------------------
            -- OTHERWISE SCAN THE MESSAGE
            --------------------------------------------------

            scanVoteLine(message)

        end

    end


    --------------------------------------------------
    -- IGNORE BALLAST ERROR
    --------------------------------------------------

    local spamMessage =
        "SYNTAX ERROR: Use 'ballast [driver numeric id] [kg]'"


    if message:find(
        spamMessage,
        1,
        true
    )
    then

        return

    end


    --------------------------------------------------
    -- SAVE CHAT MESSAGE
    --------------------------------------------------

    local sender =
        tostring(author)


    if sender == "-1" then

        sender = "Server"

    end


    chatMessages[#chatMessages + 1] = {

        text =
            sender
            .. ": "
            .. message

    }


    if #chatMessages > 100 then

        table.remove(
            chatMessages,
            1
        )

    end

end)


--------------------------------------------------
-- UI
--------------------------------------------------

function script.drawUI()

    --------------------------------------------------
    -- BOTTOM CENTER VOTE BUTTON
    --------------------------------------------------

    if votingAvailable
        and not settings.menuVisible
    then

        local screenSize =
            ui.windowSize()


        local buttonWidth = 300
        local buttonHeight = 60


        local buttonX =
            (screenSize.x - buttonWidth) / 2


        local buttonY =
            screenSize.y
            - buttonHeight
            - 35


        ui.setCursorPos(
            vec2(
                buttonX,
                buttonY
            )
        )


        if ui.button(
            "CLICK HERE TO VOTE",
            vec2(
                buttonWidth,
                buttonHeight
            )
        )
        then

            settings.menuVisible = true

        end


        local text =
            "or press M"


        local textWidth =
            ui.measureText(text).x


        ui.setCursorPos(
            vec2(
                (screenSize.x - textWidth) / 2,
                buttonY + buttonHeight + 5
            )
        )


        ui.text(text)

    end


    --------------------------------------------------
    -- NORMAL MENU
    --------------------------------------------------

    if not settings.menuVisible then

        return

    end


    --------------------------------------------------
    -- WINDOW
    --------------------------------------------------

    ui.toolWindow(
        "Server Chat",

        vec2(
            500,
            300
        ),

        vec2(
            500,
            700
        ),

        false,
        true,

        function()

            --------------------------------------------------
            -- TITLE
            --------------------------------------------------

            ui.pushFont(
                ui.Font.Title
            )


            ui.text(
                "Server Menu"
            )


            ui.popFont()


            ui.separator()


            --------------------------------------------------
            -- ACCEPT
            --------------------------------------------------

            if ui.button(
                "Accept race",

                vec2(
                    ui.availableSpaceX(),
                    45
                )
            )
            then

                sendChat(
                    "/accept"
                )

            end


            ui.separator()


            --------------------------------------------------
            -- VOTES
            --------------------------------------------------

            ui.pushFont(
                ui.Font.Title
            )


            ui.text(
                "Vote For:"
            )


            ui.popFont()


            ui.separator()


            --------------------------------------------------
            -- VOTE BUTTONS
            --------------------------------------------------

            for i = 1, #votes do

                local vote =
                    votes[i]


                local command =
                    voteCommands[
                        vote.commandName
                    ]


                local buttonText


                --------------------------------------------------
                -- CURRENT TRACK
                --------------------------------------------------

                if keepCurrentTrack
                    == vote.commandName
                then

                    buttonText =
                        "Keep on current track  (/vt 0)"


                --------------------------------------------------
                -- NORMAL DETECTED TRACK
                --------------------------------------------------

                elseif command then

                    buttonText =
                        vote.name
                        .. "  ("
                        .. command
                        .. ")"


                --------------------------------------------------
                -- NOT DETECTED
                --------------------------------------------------

                else

                    buttonText =
                        vote.name
                        .. "  (not detected)"

                end


                --------------------------------------------------
                -- DRAW BUTTON
                --------------------------------------------------

                if ui.button(
                    buttonText,

                    vec2(
                        ui.availableSpaceX(),
                        38
                    )
                )
                then

                    sendChat(
                        command
                    )

                end

            end


            ui.separator()


            --------------------------------------------------
            -- CHAT
            --------------------------------------------------

            ui.pushFont(
                ui.Font.Main
            )


            ui.text(
                "Chat:"
            )


            ui.popFont()


            ui.separator()


            --------------------------------------------------
            -- SCROLLABLE CHAT
            --------------------------------------------------

            ui.childWindow(
                "ChatMessages",

                vec2(
                    ui.availableSpaceX(),
                    200
                ),

                true,

                function()

                    local wasAtBottom =
                        ui.getScrollY()
                        >=
                        ui.getScrollMaxY()
                        - 10


                    for i = 1, #chatMessages do

                        ui.text(
                            chatMessages[i].text
                        )

                    end


                    if wasAtBottom then

                        ui.setScrollY(
                            ui.getScrollMaxY()
                        )

                    end

                end
            )


            ui.separator()


            --------------------------------------------------
            -- CLOSE
            --------------------------------------------------

            if ui.button(
                "Close Menu",

                vec2(
                    ui.availableSpaceX(),
                    35
                )
            )
            then

                settings.menuVisible =
                    false

            end

        end
    )

end