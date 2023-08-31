-- sometimes, taking a connected FP in game is not the fastest route to the destination.
-- there are situations where its actually faster to manually fly to a different FP and then take the direct(or connected) FP from there.
-- an example would be the orgrimar -> winterspring FP.  if you are in orgrimar and want to get to winterspring, the fastest way is to fly to Azshara and then take the Azshara->WS FP.

-- This function will return the shortest flight path from the current location to the destination. The return value is a table with the nodes the user should click after arriving at the current node. The inital flight master you speak to is the first node in the table. The last node in the table is the flight master you should speak to to get to the destination. The table is in order of the flight path you should take.

-- as i see it, there are 2 main modules needed here
-- 0. Flight time data, we can use restedXP's
-- 1. The actual shortest path algorithm
-- 2. A way to get current location and destination from the game

-- The function takes two arguments. The first is the current node you are at. The second is the destination node you want to get
-- flight_data = {[faction] = { 
--      [node_id] = name, 
--      {[connected_node] = flight_time_seconds}
-- }}
local _flight_data = _G.RXP.FPDB
local flight_data = {
    ["Alliance"] = {
        [6] = {
            ["name"] = "Ironforge, Dun Morogh",
            [8] = 101,
            [66] = 294,
            [7] = 128,
            [14] = 265,
            [74] = 87,
            [4] = 274,
            [67] = 349,
            [45] = 373,
            [19] = 440,
            [5] = 201,
            [2] = 210,
            [71] = 173,
            [43] = 298,
            [12] = 260,
            [16] = 253,
        },
        [2] = {
            [16] = 450,
            [66] = 506,
            [7] = 343,
            [14] = 443,
            [74] = 247,
            [4] = 78,
            [8] = 317,
            [45] = 176,
            [19] = 245,
            [5] = 113,
            ["name"] = "Stormwind, Elwynn",
            [43] = 508,
            [71] = 157,
            [6] = 259,
            [12] = 116,
            [67] = 563,
        },
        [4] = {
            [7] = 414,
            [74] = 282,
            [8] = 389,
            [45] = 186,
            [5] = 130,
            [19] = 185,
            [2] = 86,
            [6] = 331,
            [12] = 97,
            ["name"] = "Sentinel Hill, Westfall",
        },
        [8] = {
            [7] = 153,
            [14] = 250,
            [74] = 152,
            [4] = 342,
            [16] = 164,
            [66] = 285,
            [5] = 267,
            ["name"] = "Thelsamar, Loch Modan",
            [2] = 279,
            [19] = 508,
            [6] = 109,
            [12] = 326,
            [45] = 441,
        },
        [16] = {
            [7] = 126,
            [14] = 86,
            [67] = 233,
            [45] = 547,
            [66] = 122,
            [19] = 614,
            [8] = 171,
            [43] = 72,
            [6] = 271,
            [12] = 485,
            ["name"] = "Refuge Pointe, Arathi",
        },
        [32] = {
            [73] = 354,
            [33] = 801,
            [26] = 620,
            [27] = 619,
            [28] = 387,
            [41] = 341,
            [37] = 334,
            [31] = 162,
            [65] = 518,
            [49] = 535,
            ["name"] = "Theramore, Dustwallow Marsh",
            [52] = 414,
            [64] = 235,
            [80] = 115,
            [39] = 157,
            [79] = 261,
        },
        [64] = {
            [73] = 588,
            [26] = 301,
            [52] = 178,
            [39] = 391,
            [32] = 241,
            [79] = 494,
            ["name"] = "Talrendis Point, Azshara",
            [65] = 283,
            [80] = 135,
            [28] = 153,
        },
        [66] = {
            [7] = 193,
            [14] = 85,
            [74] = 309,
            [4] = 495,
            [43] = 66,
            [71] = 395,
            ["name"] = "Chillwind Camp, Western Plaguelands",
            [19] = 662,
            [67] = 147,
            [6] = 261,
            [2] = 432,
            [16] = 138,
        },
        [19] = {
            nil, -- [1]
            220, -- [2]
            nil, -- [3]
            181, -- [4]
            230, -- [5]
            464, -- [6]
            548, -- [7]
            523, -- [8]
            [71] = 291,
            [66] = 712,
            ["name"] = "Booty Bay, Stranglethorn",
            [12] = 175,
            [14] = 649,
            [16] = 655,
            [45] = 266,
        },
        [73] = {
            [64] = 576,
            [31] = 329,
            ["name"] = "Cenarion Hold, Silithus",
            [32] = 342,
            [65] = 831,
            [41] = 175,
            [27] = 726,
            [79] = 92,
        },
        [37] = {
            [33] = 120,
            [26] = 282,
            [27] = 367,
            [39] = 464,
            [41] = 232,
            [31] = 472,
            [32] = 308,
            ["name"] = "Nijel's Point, Desolace",
            [80] = 422,
            [28] = 273,
        },
        [74] = {
            [71] = 96,
            [7] = 178,
            ["name"] = "Thorium Point, Searing Gorge",
            [8] = 152,
            [66] = 342,
            [67] = 398,
            [6] = 94,
            [45] = 265,
        },
        [39] = {
            [73] = 197,
            [33] = 692,
            [52] = 566,
            [28] = 540,
            [41] = 354,
            [31] = 177,
            [32] = 154,
            [79] = 104,
            ["name"] = "Gadgetzan, Tanaris",
            [27] = 772,
            [65] = 670,
            [80] = 262,
            [64] = 388,
            [37] = 480,
        },
        [65] = {
            [26] = 188,
            [52] = 121,
            [28] = 363,
            [41] = 660,
            [79] = 776,
            ["name"] = "Talonbranch Glade, Felwood",
            [27] = 272,
            [64] = 282,
            [37] = 478,
            [39] = 671,
        },
        [80] = {
            [73] = 459,
            [33] = 437,
            [52] = 310,
            [28] = 284,
            [41] = 446,
            [31] = 268,
            [32] = 106,
            [79] = 366,
            ["name"] = "Ratchet, The Barrens",
            [27] = 805,
            [64] = 132,
            [65] = 415,
            [37] = 439,
            [39] = 261,
        },
        [33] = {
            [27] = 261,
            [37] = 126,
            ["name"] = "Stonetalon Peak, Stonetalon Mountains",
            [32] = 434,
            [26] = 177,
            [28] = 154,
        },
        [43] = {
            [7] = 176,
            [14] = 68,
            [2] = 429,
            [4] = 492,
            [67] = 164,
            [16] = 75,
            [66] = 54,
            ["name"] = "Aerie Peak, The Hinterlands",
            [8] = 245,
            [19] = 658,
            [6] = 256,
            [12] = 531,
            [45] = 591,
        },
        [27] = {
            [73] = 714,
            [33] = 267,
            [26] = 86,
            [52] = 365,
            [39] = 774,
            [41] = 557,
            [37] = 376,
            [31] = 711,
            [32] = 617,
            [49] = 236,
            ["name"] = "Rut'theran Village, Teldrassil",
            [64] = 385,
            [65] = 274,
            [80] = 519,
            [28] = 261,
            [79] = 797,
        },
        [45] = {
            [7] = 467,
            [74] = 300,
            [67] = 687,
            [71] = 207,
            [5] = 150,
            [19] = 260,
            [66] = 631,
            [2] = 189,
            [6] = 382,
            [12] = 91,
            ["name"] = "Nethergarde Keep, Blasted Lands",
        },
        [12] = {
            [7] = 417,
            [14] = 517,
            [74] = 212,
            [4] = 93,
            [8] = 391,
            [16] = 524,
            [5] = 60,
            ["name"] = "Darkshire, Duskwood",
            [19] = 171,
            [2] = 88,
            [6] = 333,
            [43] = 582,
            [45] = 97,
        },
        [5] = {
            [7] = 441,
            [74] = 153,
            [4] = 133,
            [8] = 415,
            [71] = 61,
            [19] = 227,
            [67] = 540,
            [2] = 113,
            [6] = 357,
            [12] = 60,
            ["name"] = "Lakeshire, Redridge",
        },
        [71] = {
            [8] = 245,
            [7] = 270,
            [66] = 435,
            [74] = 104,
            [4] = 195,
            [67] = 491,
            [45] = 210,
            [19] = 288,
            [5] = 64,
            ["name"] = "Morgan's Vigil, Burning Steppes",
            [43] = 436,
            [2] = 151,
            [6] = 187,
            [12] = 121,
            [16] = 378,
        },
        [49] = {
            [73] = 771,
            [26] = 142,
            [52] = 131,
            [39] = 694,
            [41] = 614,
            [32] = 537,
            [64] = 305,
            ["name"] = "Nighthaven, Moonglade",
            [37] = 433,
            [65] = 61,
            [27] = 226,
            [28] = 318,
        },
        [67] = {
            [7] = 333,
            [14] = 226,
            [74] = 417,
            [43] = 163,
            [45] = 704,
            ["name"] = "Light's Hope Chapel, Eastern Plaguelands",
            [66] = 150,
            [6] = 369,
            [12] = 591,
            [71] = 503,
        },
        [26] = {
            [33] = 181,
            [37] = 291,
            [39] = 689,
            [41] = 473,
            [27] = 84,
            [32] = 675,
            [49] = 151,
            ["name"] = "Auberdine, Darkshore",
            [64] = 301,
            [52] = 281,
            [80] = 435,
            [28] = 176,
            [65] = 190,
        },
        [52] = {
            [26] = 262,
            [37] = 553,
            [39] = 564,
            [41] = 734,
            [31] = 572,
            [32] = 408,
            [49] = 122,
            ["name"] = "Everlook, Winterspring",
            [27] = 346,
            [80] = 309,
            [65] = 122,
            [28] = 327,
            [64] = 176,
        },
        [7] = {
            [19] = 490,
            [16] = 113,
            [66] = 186,
            [14] = 107,
            [74] = 135,
            [4] = 324,
            [8] = 163,
            [45] = 423,
            [71] = 221,
            [5] = 250,
            ["name"] = "Menethil Harbor, Wetlands",
            [2] = 261,
            [43] = 176,
            [6] = 89,
            [12] = 309,
            [67] = 324,
        },
        [14] = {
            ["name"] = "Southshore, Hillsbrad",
            [7] = 110,
            [2] = 367,
            [4] = 430,
            [67] = 219,
            [16] = 74,
            [8] = 244,
            [19] = 597,
            [66] = 81,
            [43] = 71,
            [6] = 206,
            [12] = 468,
            [45] = 530,
        },
        [28] = {
            ["name"] = "Astranaar, Ashenvale",
            [33] = 153,
            [26] = 148,
            [37] = 279,
            [41] = 511,
            [32] = 381,
            [64] = 150,
            [65] = 337,
            [27] = 231,
            [80] = 283,
        },
        [79] = {
            ["name"] = "Marshal's Refuge, Un'Goro Crater",
            [73] = 94,
            [52] = 670,
            [28] = 856,
            [41] = 258,
            [32] = 257,
            [27] = 809,
            [65] = 774,
            [80] = 364,
            [39] = 104,
        },
        [41] = {
            ["name"] = "Feathermoon, Feralas",
            [33] = 648,
            [26] = 468,
            [37] = 227,
            [39] = 326,
            [31] = 155,
            [32] = 314,
            [49] = 619,
            [27] = 551,
            [28] = 500,
            [52] = 748,
        },
        [31] = {
            ["name"] = "Thalanaar, Feralas",
            [27] = 729,
            [80] = 274,
            [39] = 171,
            [79] = 274,
            [41] = 179,
            [37] = 405,
            [32] = 159,
        },
    }
}

--14 southshore -> 45 nethergaurd 
local function get_shortest_flight_nodes(start_node_id, target_node_id)
    local shortest_flight_time = math.huge
    local shortest_flight_nodes = {}
    return shortest_flight_nodes
end

local function get_current_node_index()
    local taxi_nodes = C_TaxiMap.GetAllTaxiNodes(C_Map.GetBestMapForUnit("player") or 0)
    for _, node_info in pairs(taxi_nodes) do
        if node_info.state == Enum.FlightPathState.Current then
            -- return node_info.nodeID
            return node_info.slotIndex
        end
    end
end
local function coords_to_leatrix_table_format(x, y)
    return string.format("%0.2f", x) .. ":" .. string.format("%0.2f", y)
end
-- Function to get continent
local function getContinent()
    local mapID = C_Map.GetBestMapForUnit("player")
    if(mapID) then
        local info = C_Map.GetMapInfo(mapID)
        if(info) then
            while(info['mapType'] and info['mapType'] > 2) do
                info = C_Map.GetMapInfo(info['parentMapID'])
            end
            if(info['mapType'] == 2) then
                return info['mapID']
            end
        end
    end
end
hooksecurefunc("TaxiNodeOnButtonEnter", function(button)
    local faction = UnitFactionGroup("player")
    local continent getContinent()			

    local node_index = button:GetID();
    local src_x,src_y = TaxiNodePosition(get_current_node_index())
    local _src = coords_to_leatrix_table_format(src_x, src_y)
    local leatrix_table_query = _src .. ":"
    local num_connected_nodes = GetNumRoutes(node_index)
    for i = 2, num_connected_nodes do
        local connected_node_index = TaxiGetNodeSlot(node_index, i)
        local x, y = TaxiNodePosition(connected_node_index)
        local _connected = coords_to_leatrix_table_format(x, y)
        -- print(_src, _connected, _dest)
        leatrix_table_query = leatrix_table_query .. _connected .. ":"
    end
    local dest_x,dest_y = TaxiNodePosition(node_index)
    local _dest = coords_to_leatrix_table_format(dest_x, dest_y)
    leatrix_table_query = leatrix_table_query .. _dest

    local flight_data = LeatrixPlusFlightData[faction] and LeatrixPlusFlightData[faction][continent]

    local current_shortest_flight_time
    if flight_data then
        current_shortest_flight_time = flight_data[leatrix_table_query] or math.huge
    end

    -- iterate connected nodes
    
end)