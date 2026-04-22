# stops.py — All bus/rail stops in Bellevue, WA
# Stop IDs use OneBusAway Puget Sound format (agency_stopCode)
# Prefix 1_ = King County Metro, 3_ = Sound Transit bus, 29_ = Community Transit
# Prefix 40_ = Sound Transit Link Light Rail stations

BELLEVUE_STOPS = [
    # --- Bellevue Transit Center (BTC) ---
    "1_67652",  # BTC Bay 9
    "1_68007",  # BTC Bay 12
    "1_68001",  # BTC Bay 11
    "1_68006",  # BTC Bay 6
    "1_69021",  # BTC Bay 10
    "3_12339",  # BTC Bay 7 (Sound Transit)
    "3_8468",   # BTC Bay 6 (Sound Transit)

    # --- Downtown Bellevue ---
    "1_67640",  # Bellevue Way SE & Main St
    "1_67650",  # Bellevue Way SE & SE 3rd St
    "1_67720",  # Bellevue Way SE & SE 16th St
    "1_67960",  # Bellevue Way SE & SE 16th St
    "1_68035",  # Bellevue Way NE & Main St
    "1_68042",  # NE 4th St & 105th Ave NE
    "1_80571",  # 116th Ave NE & NE 2nd Pl
    "1_82810",  # Main St & 112th Ave NE
    "1_85489",  # 108th Ave NE & NE 2nd St
    "1_85669",  # NE 8th St & 102nd Ave NE
    "29_2856",  # NE 10th St & 102nd Ave NE
    "29_3339",  # NE 8th St & 108th Ave NE

    # --- West Bellevue / Bellevue Way NE ---
    "1_68950",  # Bellevue Way NE & NE 26th St
    "1_69380",  # Bellevue Way NE & NE 26th St
    "1_68960",  # Bellevue Way NE & NE 24th St
    "1_69400",  # Bellevue Way NE & NE 30th Pl
    "1_69402",  # Bellevue Way NE & 103rd Ave NE
    "1_70600",  # Bellevue Way SE & 108th Ave SE
    "1_84270",  # Bellevue Way SE & 113th Ave SE
    "1_84280",  # I-405 & Lake Washington Blvd SE
    "1_82780",  # I-405 & Lake Washington Blvd SE
    "1_82718",  # I-405 & SE 8th St

    # --- Lake Washington Blvd / Lakeview ---
    "1_69465",  # Lakeview Dr NE & Lake Washington Blvd NE
    "1_68871",  # Lake Washington Blvd NE & Lakeview Dr NE
    "1_69420",  # Lake Washington Blvd NE & NE 43rd St
    "1_69475",  # Lakeview Dr NE & NE 59th St
    "1_69485",  # Lakeview Dr NE & NE 64th St
    "1_72950",  # Lake Washington Blvd NE & NE 10th St
    "1_73040",  # NE 1st St & Lake Washington Blvd NE
    "1_74437",  # NE 38th Pl & Lake Washington Blvd NE

    # --- NE Bellevue / Medina border ---
    "1_72960",  # NE 12th St & 84th Ave NE
    "1_72980",  # 84th Ave NE & NE 24th St
    "1_73020",  # 84th Ave NE & NE 20th St
    "1_73042",  # NE 8th St & 92nd Ave NE
    "1_73043",  # NE 8th St & 95th Ave NE
    "1_73044",  # NE 8th St & 94th Ave NE

    # --- NE 8th St Corridor ---
    "1_67500",  # NE 8th St & 148th Ave NE
    "1_67510",  # NE 8th St & 143rd Ave NE
    "1_67520",  # NE 8th St & 140th Ave NE
    "1_67580",  # NE 8th St & 120th Ave NE
    "1_67938",  # 108th Ave SE & SE 12th St
    "1_67939",  # 108th Ave SE & SE 14th St
    "1_68094",  # NE 8th St & 120th Ave NE
    "1_68100",  # NE 8th St & 124th Ave NE
    "1_68150",  # NE 8th St & 140th Ave NE
    "1_68180",  # NE 8th St & 148th Ave NE
    "1_68470",  # NE 8th St & 156th Ave NE (NE 1st St)
    "1_68467",  # NE 8th St & 156th Ave NE
    "1_68710",  # 156th Ave NE & NE 1st St
    "1_68740",  # 156th Ave NE & NE 8th St
    "1_69015",  # 110th Ave NE & NE 10th St
    "1_69026",  # NE 10th St & 110th Ave NE
    "1_84940",  # 148th Ave NE & NE 8th St

    # --- 116th Ave NE / NE 20th-24th Corridor ---
    "1_68348",  # 116th Ave NE & NE 20th St
    "1_68349",  # 116th Ave NE & NE 20th St
    "1_68355",  # 116th Ave NE & Northup Way
    "1_73047",  # 116th Ave NE & NE 24th St
    "1_74463",  # 112th Ave NE & NE 19th St
    "1_82760",  # 112th Ave SE & SE 4th St
    "1_82790",  # 112th Ave SE & SE 4th St - Bay 2

    # --- Northup Way ---
    "1_74447",  # Northup Way & NE 30th St
    "1_74448",  # Northup Way & NE 33rd Pl
    "1_74451",  # Northup Way & NE 33rd Pl
    "1_74452",  # Northup Way & NE 24th St
    "1_74453",  # Northup Way & NE 28th St
    "1_74455",  # Northup Way & NE 28th St

    # --- Bel-Red Corridor / NE 24th St ---
    "1_68370",  # NE 24th St & 156th Ave NE
    "1_68372",  # NE 24th St & 160th Ave NE
    "1_68390",  # 156th Ave NE & NE 24th St
    "1_71300",  # NE 24th St & 162nd Ave NE
    "1_71310",  # NE 24th St & 160th Ave NE
    "1_71320",  # NE 24th St & 156th Ave NE
    "1_71322",  # NE 24th St & NE Bel-Red Rd
    "1_71370",  # NE 24th St & 152nd Ave NE
    "1_71866",  # NE 20th St & NE Bel-Red Rd
    "1_74525",  # NE 20th St & 156th Ave NE
    "1_84788",  # NE 24th St & 152nd Ave NE
    "1_84810",  # 148th Ave NE & NE 24th St

    # --- 156th Ave NE Corridor ---
    "1_66871",  # NE 31st St & 156th Ave NE
    "1_68400",  # 156th Ave NE & NE 20th St
    "1_68410",  # 156th Ave NE & NE 15th St
    "1_68411",  # 156th Ave NE & NE 33rd St
    "1_68415",  # 156th Ave NE & NE 33rd St
    "1_68420",  # 156th Ave NE & NE 15th Pl
    "1_68435",  # 156th Ave NE & NE 13th St
    "1_68460",  # 156th Ave NE & NE 4th St
    "1_68463",  # 156th Ave NE & NE 45th St
    "1_68700",  # 156th Ave NE & Main St
    "1_68720",  # 156th Ave NE & NE 4th St
    "1_68750",  # 156th Ave NE & NE 10th St
    "1_68784",  # 156th Ave NE & NE 28th St
    "1_68786",  # 156th Ave NE & NE 28th St
    "1_68788",  # 156th Ave NE & NE 24th St

    # --- 148th Ave NE Corridor ---
    "1_67320",  # 164th Ave NE & NE 24th St
    "1_68063",  # NE Bellevue Redmond Rd & 148th Ave NE
    "1_68067",  # NE Bellevue Redmond Rd & 132nd Ave NE
    "1_68068",  # NE Bellevue Redmond Rd & 140th Ave NE
    "1_68070",  # NE Bellevue Redmond Rd & 136th Ave NE
    "1_73130",  # 148th Ave NE & NE Old Redmond Rd
    "1_73246",  # 148th Ave NE & NE 43rd Pl
    "1_73248",  # 148th Ave NE & NE 40th St
    "1_73340",  # 148th Ave NE & NE 37th Pl
    "1_73342",  # 148th Ave NE & NE 40th St
    "1_73350",  # 148th Ave NE & NE 51st St
    "1_74482",  # 148th Ave NE & NE 20th St
    "1_84820",  # 148th Ave NE & NE 20th St
    "1_84825",  # NE Bellevue Redmond Rd & 148th Ave NE
    "1_84826",  # Bellevue Redmond Rd & 132nd Ave NE
    "1_84827",  # Bellevue Redmond Rd & 130th Ave NE
    "1_84828",  # NE 12th St & 124th Ave NE
    "1_84830",  # 148th Ave NE & NE 16th St
    "1_84831",  # NE Bellevue Redmond Rd & 136th Ave NE
    "1_84970",  # 148th Ave NE & NE 15th St

    # --- 152nd Ave NE / Overlake area ---
    "1_55566",  # 152nd Ave NE & Da Vinci Ave NE - Bay 1
    "1_66874",  # 152nd Ave NE & NE 36th St
    "1_66875",  # 152nd Ave NE & NE 31st St
    "1_68394",  # NE 36th St & 150th Ave NE
    "1_71323",  # 152nd Ave NE & NE Shen St - Bay 2
    "1_71325",  # NE 40th St & 152nd Ave NE
    "1_71326",  # 152nd Ave NE & Overlake Park & Ride
    "1_71327",  # NE 40th St & 150th Ave NE
    "1_71329",  # NE 40th St & 152nd Ave NE
    "1_71331",  # Overlake Park & Ride
    "1_71390",  # NE 24th St & 167th Ave NE
    "1_73152",  # 148th Ave NE & NE 61st St
    "1_73167",  # NE 51st St & 148th Ave NE
    "1_73419",  # NE 51st St & SR 520
    "1_84821",  # NE Bellevue Redmond Rd & 152nd Ave NE
    "1_84940",  # 148th Ave NE & NE 8th St

    # --- 164th Ave NE Corridor ---
    "1_66710",  # 164th Ave NE & NE 24th St
    "1_66730",  # 164th Ave NE & NE 20th St
    "1_66790",  # 164th Ave NE & NE 6th St
    "1_66800",  # 164th Ave NE & NE 4th St
    "1_67220",  # 164th Ave NE & NE 2nd St
    "1_67280",  # 164th Ave NE & NE 16th Pl
    "1_67300",  # 164th Ave NE & NE 20th St
    "1_68064",  # NE 12th St & 120th Ave NE
    "1_71290",  # NE 24th St & 164th Ave NE
    "1_71380",  # NE 24th St & 164th Ave NE

    # --- 108th Ave NE (north) ---
    "1_74439",  # 120th Ave NE & NE Spring Blvd - Bay 2
    "1_74540",  # 108th Ave NE & NE 47th St
    "1_74550",  # 108th Ave NE & NE 53rd St
    "1_74560",  # 108th Ave NE & NE 58th St

    # --- Main St / Bellevue-Redmond Rd ---
    "1_68471",  # Main St & 155th Ave NE
    "1_68472",  # Main St & 152nd Pl SE
    "1_68475",  # Main St & 143rd Ave SE
    "1_68476",  # Main St & 150th Ave NE
    "1_70835",  # Main St & 148th Ave SE
    "1_70837",  # Main St & 152nd Pl SE

    # --- Lake Hills ---
    "1_68502",  # 156th Ave SE & Lake Hills Blvd
    "1_68510",  # Lake Hills Blvd & 154th Ave SE
    "1_68530",  # Lake Hills Blvd & SE 12th Pl
    "1_68540",  # 148th Ave SE & Lake Hills Blvd
    "1_68582",  # Landerholm Cir SE & 148th Ave SE
    "1_68590",  # 148th Ave SE & SE 28th St
    "1_68592",  # 145th Pl SE & SE 22nd St
    "1_68593",  # 145th Pl SE & SE 16th St
    "1_68594",  # 145th Pl SE & SE 16th St
    "1_68595",  # 145th Pl SE & SE 22nd St
    "1_68596",  # 145th Pl SE & Lake Hills Blvd
    "1_68597",  # 140th Ave SE & Lake Hills Connector
    "1_68598",  # Lake Hills Connector & 140th Ave SE
    "1_68599",  # 145th Pl SE & 144th Ave SE
    "1_68611",  # 145th Pl SE & Lake Hills Blvd
    "1_68612",  # SE 24th St & 148th Ave SE
    "1_68613",  # SE 24th St & 145th Pl SE
    "1_68620",  # 148th Ave SE & SE 22nd St
    "1_68640",  # Lake Hills Blvd & 148th Ave SE
    "1_68650",  # Lake Hills Blvd & SE 12th Pl
    "1_68670",  # Lake Hills Blvd & 154th Ave SE
    "1_68690",  # 156th Ave SE & SE 4th St
    "1_68700",  # 156th Ave NE & Main St
    "1_68889",  # SE 22nd St & 150th Ave SE
    "1_70802",  # 140th Ave SE & SE 1st St
    "1_70803",  # Lake Hills Connector & 134th Ave SE
    "1_70813",  # Lake Hills Connector & SE 8th St
    "1_70823",  # 145th Pl SE & SE 10th St
    "1_70826",  # 140th Ave SE & SE 7th St
    "1_70828",  # 140th Ave SE & SE 5th St
    "1_70832",  # 140th Ave SE & SE 1st St
    "1_70841",  # Lake Hills Connector & Richards Rd
    "1_70843",  # Lake Hills Connector & Richards Rd
    "1_71660",  # SE 24th St & 158th Ave SE
    "1_71675",  # SE 24th St & 161st Ave SE
    "1_71678",  # SE 24th St & 158th Ave SE
    "1_71680",  # SE 24th St & 156th Ave SE
    "1_84584",  # 148th Ave SE & SE 28th St
    "1_68584",  # 148th Ave SE & SE 28th St

    # --- Eastgate / I-90 Corridor ---
    "1_65320",  # SE Eastgate Way & 150th Ave SE
    "1_65322",  # SE Eastgate Way & 139th Ave SE
    "1_65328",  # SE Eastgate Way & 158th Ave SE
    "1_65329",  # SE Eastgate Way & 158th Ave SE
    "1_65335",  # SE Eastgate Way & SE 35th Pl
    "1_65402",  # SE Eastgate Way & 139th Ave SE
    "1_67013",  # I-90 Expressway Ramp & 142nd Pl SE - Bay 4
    "1_67014",  # Eastgate Park & Ride - Bay 1
    "1_67021",  # 142nd Pl SE & SE 36th St
    "1_67022",  # 142nd Pl SE & SE 32nd St
    "1_67028",  # SE 36th St & 132nd Ave SE
    "1_72880",  # 150th Ave SE & SE Eastgate Way
    "1_72869",  # 150th Ave SE & SE 38th St
    "1_72871",  # 150th Ave SE & SE 38th St
    "1_72983",  # Kelsey Creek Rd & Tye River Rd (southbound)
    "1_72984",  # Kelsey Creek Rd & Tye River Rd (northbound)
    "1_79862",  # SE 36th St & 131st Ave SE
    "1_79864",  # SE 36th St & 132nd Ave SE
    "1_79868",  # Factoria Blvd SE & SE 38th St
    "1_79871",  # SE 37th St & 150th Ave SE
    "1_79877",  # SE 37th St & I-90
    "1_85410",  # I-90 & Richards Rd

    # --- Factoria ---
    "1_64840",  # Factoria Blvd SE & Coal Creek Pkwy SE
    "1_79880",  # Factoria Blvd SE & SE 40th Ln
    "1_79890",  # Factoria Blvd SE & SE 42nd St
    "1_79900",  # Factoria Blvd SE & SE Newport Way
    "1_80380",  # Factoria Blvd SE & SE Newport Way
    "1_80390",  # Factoria Blvd SE & SE 41st Ln
    "1_80400",  # Factoria Blvd SE & SE 40th Ln
    "1_80412",  # Factoria Blvd SE & SE 38th St

    # --- Newport Hills / SE Bellevue ---
    "1_64630",  # SE Newport Way & 163rd Ave SE
    "1_64640",  # SE Newport Way & 161st Ave SE
    "1_64650",  # SE Newport Way & 156th Ave SE
    "1_64660",  # SE Newport Way & 152nd Ave SE
    "1_64768",  # SE Newport Way & SE 42nd Pl
    "1_64769",  # SE Newport Way & SE 42nd Pl
    "1_64780",  # SE Newport Way & 129th Pl SE
    "1_64870",  # SE Allen Rd & SE Newport Way
    "1_64980",  # SE Newport Way & 156th Ave SE
    "1_64990",  # SE Newport Way & 161st Ave SE
    "1_65000",  # SE Newport Way & 163rd Ave SE
    "3_13432",  # Newport Hills Freeway Station

    # --- Coal Creek / SE Bellevue ---
    "1_64830",  # Coal Creek Pkwy SE & 124th Ave SE
    "1_65460",  # 123rd Ave SE & SE 64th Pl
    "1_65530",  # 119th Ave SE & SE 49th Pl
    "1_65560",  # 119th Ave SE & Coal Creek Pkwy SE
    "1_65570",  # 119th Ave SE & Coal Creek Pkwy SE
    "1_65590",  # 119th Ave SE & SE 47th St
    "1_65600",  # 119th Ave SE & SE 49th Pl
    "1_65610",  # 119th Ave SE & SE 52nd St
    "1_65640",  # SE 60th St & 119th Ave SE
    "1_65652",  # 123rd Ave SE & SE 60th St
    "1_65670",  # 123rd Ave SE & SE 64th Pl

    # --- 164th Ave SE Corridor ---
    "1_66840",  # 164th Ave SE & Lake Hills Blvd
    "1_66850",  # 164th Ave SE & SE 7th St
    "1_66900",  # 168th Ave SE & SE 16th St
    "1_67100",  # 168th Ave SE & SE 23rd Pl
    "1_67140",  # SE 14th St & 167th Ave SE
    "1_67160",  # 164th Ave SE & SE 12th St
    "1_67180",  # 164th Ave SE & SE 7th St
    "1_67190",  # 164th Ave SE & Lake Hills Blvd
    "1_67200",  # 164th Ave SE & SE 2nd St

    # --- South Bellevue / SE 16th St area ---
    "1_84263",  # South Bellevue Station Bus Plaza - Bay 1
    "1_84264",  # South Bellevue Station Bus Plaza - Bay 2

    # --- Link Light Rail Stations ---
    "40_E09",    # South Bellevue Station
    "40_E09-T2", # South Bellevue Station (platform 2)
    "40_E15-T2", # Bellevue Downtown Station
    "40_E19-T1", # Wilburton Station
    "40_E25",    # Overlake Village Station
    "40_E25-T2", # Overlake Village Station (platform 2)
]
