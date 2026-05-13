# stops.py — All bus/rail stops in Bellevue and Seattle, WA
# Stop IDs use OneBusAway Puget Sound format (agency_stopCode)
# Prefix 1_ = King County Metro, 3_ = Sound Transit bus, 29_ = Community Transit
# Prefix 40_ = Sound Transit Link Light Rail stations

BELLEVUE_STOPS = [
    "1_67652",
    "1_68007",
    "1_68001",
    "1_68006",
    "1_69021",
    "3_12339",
    "3_8468",
    "1_67640",
    "1_67650",
    "1_67720",
    "1_67960",
    "1_68035",
    "1_68042",
    "1_80571",
    "1_82810",
    "1_85489",
    "1_85669",
    "29_2856",
    "29_3339",
    "1_68950",
    "1_69380",
    "1_68960",
    "1_69400",
    "1_69402",
    "1_70600",
    "1_84270",
    "1_84280",
    "1_82780",
    "1_82718",
    "1_69465",
    "1_68871",
    "1_69420",
    "1_69475",
    "1_69485",
    "1_72950",
    "1_73040",
    "1_74437",
    "1_72960",
    "1_72980",
    "1_73020",
    "1_73042",
    "1_73043",
    "1_73044",
    "1_67500",
    "1_67510",
    "1_67520",
    "1_67580",
    "1_67938",
    "1_67939",
    "1_68094",
    "1_68100",
    "1_68150",
    "1_68180",
    "1_68470",
    "1_68467",
    "1_68710",
    "1_68740",
    "1_69015",
    "1_69026",
    "1_84940",
    "1_68348",
    "1_68349",
    "1_68355",
    "1_73047",
    "1_74463",
    "1_82760",
    "1_82790",
    "1_74447",
    "1_74448",
    "1_74451",
    "1_74452",
    "1_74453",
    "1_74455",
    "1_68370",
    "1_68372",
    "1_68390",
    "1_71300",
    "1_71310",
    "1_71320",
    "1_71322",
    "1_71370",
    "1_71866",
    "1_74525",
    "1_84788",
    "1_84810",
    "1_66871",
    "1_68400",
    "1_68410",
    "1_68411",
    "1_68415",
    "1_68420",
    "1_68435",
    "1_68460",
    "1_68463",
    "1_68700",
    "1_68720",
    "1_68750",
    "1_68784",
    "1_68786",
    "1_68788",
    "1_67320",
    "1_68063",
    "1_68067",
    "1_68068",
    "1_68070",
    "1_73130",
    "1_73246",
    "1_73248",
    "1_73340",
    "1_73342",
    "1_73350",
    "1_74482",
    "1_84820",
    "1_84825",
    "1_84826",
    "1_84827",
    "1_84828",
    "1_84830",
    "1_84831",
    "1_84970",
    "1_55566",
    "1_66874",
    "1_66875",
    "1_68394",
    "1_71323",
    "1_71325",
    "1_71326",
    "1_71327",
    "1_71329",
    "1_71331",
    "1_71390",
    "1_73152",
    "1_73167",
    "1_73419",
    "1_84821",
    "1_66710",
    "1_66730",
    "1_66790",
    "1_66800",
    "1_67220",
    "1_67280",
    "1_67300",
    "1_68064",
    "1_71290",
    "1_71380",
    "1_74439",
    "1_74540",
    "1_74550",
    "1_74560",
    "1_68471",
    "1_68472",
    "1_68475",
    "1_68476",
    "1_70835",
    "1_70837",
    "1_68502",
    "1_68510",
    "1_68530",
    "1_68540",
    "1_68582",
    "1_68590",
    "1_68592",
    "1_68593",
    "1_68594",
    "1_68595",
    "1_68596",
    "1_68597",
    "1_68598",
    "1_68599",
    "1_68611",
    "1_68612",
    "1_68613",
    "1_68620",
    "1_68640",
    "1_68650",
    "1_68670",
    "1_68690",
    "1_68889",
    "1_70802",
    "1_70803",
    "1_70813",
    "1_70823",
    "1_70826",
    "1_70828",
    "1_70832",
    "1_70841",
    "1_70843",
    "1_71660",
    "1_71675",
    "1_71678",
    "1_71680",
    "1_84584",
    "1_68584",
    "1_65320",
    "1_65322",
    "1_65328",
    "1_65329",
    "1_65335",
    "1_65402",
    "1_67013",
    "1_67014",
    "1_67021",
    "1_67022",
    "1_67028",
    "1_72880",
    "1_72869",
    "1_72871",
    "1_72983",
    "1_72984",
    "1_79862",
    "1_79864",
    "1_79868",
    "1_79871",
    "1_79877",
    "1_85410",
    "1_64840",
    "1_79880",
    "1_79890",
    "1_79900",
    "1_80380",
    "1_80390",
    "1_80400",
    "1_80412",
    "1_64630",
    "1_64640",
    "1_64650",
    "1_64660",
    "1_64768",
    "1_64769",
    "1_64780",
    "1_64870",
    "1_64980",
    "1_64990",
    "1_65000",
    "3_13432",
    "1_64830",
    "1_65460",
    "1_65530",
    "1_65560",
    "1_65570",
    "1_65590",
    "1_65600",
    "1_65610",
    "1_65640",
    "1_65652",
    "1_65670",
    "1_66840",
    "1_66850",
    "1_66900",
    "1_67100",
    "1_67140",
    "1_67160",
    "1_67180",
    "1_67190",
    "1_67200",
    "1_84263",
    "1_84264",
    "40_E09",
    "40_E09-T2",
    "40_E15-T2",
    "40_E19-T1",
    "40_E25",
    "40_E25-T2",
]

SEATTLE_STOPS = [
    "1_10005",  # 40th Ave NE & NE 51st St
    "1_10010",  # NE 55th St & 39th Ave NE
    "1_10020",  # NE 55th St & 37th Ave NE
    "1_10030",  # NE 55th St & 35th Ave NE
    "1_10040",  # NE 55th St & 33rd Ave NE
    "1_10050",  # NE 55th St & 30th Ave NE
    "1_10060",  # NE 55th St & 27th Ave NE
    "1_10070",  # NE 55th St & 25th Ave NE
    "1_10083",  # Ravenna Ave NE & Ravenna Pl NE
    "1_1010",  # Howell St & Minor Ave
    "1_10100",  # NE Ravenna Blvd & Park Rd NE
    "1_10110",  # 20th Ave NE & NE 55th St
    "1_10130",  # NE 50th St & 19th Ave NE
    "1_10145",  # NE 50th St & 16th Ave NE
    "1_103",  # Spring St & 8th Ave
    "1_10325",  # Fairview Ave N & Valley St
    "1_10370",  # NE 50th St & University Way NE
    "1_10380",  # NE 50th St & 16th Ave NE
    "1_1040",  # Olive Way & 6th Ave
    "1_10400",  # 20th Ave NE & NE 50th St
    "1_10410",  # 20th Ave NE & NE 52nd St
    "1_10430",  # NE Ravenna Blvd & 21st Ave NE
    "1_10445",  # Ravenna Ave NE & NE 54th St
    "1_10460",  # NE 55th St & 25th Ave NE
    "1_10480",  # NE 55th St & 30th Ave NE
    "1_10490",  # NE 55th St & 33rd Ave NE
    "1_10500",  # NE 55th St & 35th Ave NE
    "1_10513",  # 40th Ave NE & NE 46th St
    "1_10515",  # 40th Ave NE & NE 50th St
    "1_10525",  # NE 55th St & 40th Ave NE
    "1_10550",  # NE 55th St & 45th Ave NE
    "1_10560",  # NE 55th St & Princeton Ave NE
    "1_10561",  # Sand Point Way NE & 38th Ave NE
    "1_10562",  # Sand Point Way NE & 40th Ave NE
    "1_10564",  # Sand Point Way NE & NE 50th St
    "1_10566",  # Sand Point Way NE & NE 52nd St
    "1_10568",  # Sand Point Way NE & Princeton Ave NE
    "1_10680",  # Sand Point Way NE & Inverness Dr NE
    "1_10700",  # Sand Point Way NE & Matthews Pl NE
    "1_10710",  # Sand Point Way NE & NE 93rd St
    "1_10720",  # Sand Point Way NE & NE 95th St
    "1_10730",  # Sand Point Way NE & NE 97th St
    "1_10750",  # Sand Point Way NE & NE 103rd St
    "1_10760",  # Sand Point Way NE & NE 106th St
    "1_10780",  # Sand Point Way NE & NE 110th St
    "1_108",  # E Madison St & 22nd Ave E
    "1_10820",  # Sand Point Way NE & NE 120th St
    "1_10830",  # Sand Point Way NE & NE 123rd St
    "1_10840",  # NE 125th St & 39th Ave NE
    "1_1085",  # Pine St & 9th Ave
    "1_10860",  # NE 125th St & 35th Ave NE
    "1_10870",  # NE 125th St & 33rd Ave NE
    "1_109",  # E Madison St & 24th Ave E
    "1_10910",  # 12th Ave NE & NE 47th St
    "1_10911",  # U District Station - Bay 3
    "1_10912",  # 15th Ave NE & NE 43rd St
    "1_10915",  # Harvard Ave E & Eastlake Ave E
    "1_10916",  # Harvard Ave E & Eastlake Ave E
    "1_10917",  # 15th Ave NE & NE 40th St
    "1_10940",  # 10th Ave E & E Roanoke St
    "1_10970",  # 10th Ave E & E Newton St
    "1_11012",  # E Aloha St & Broadway  E
    "1_11075",  # Boren Ave & Seneca St
    "1_11087",  # Boren Ave & Columbia St
    "1_111",  # E Madison St & Martin L King Jr Way E
    "1_1110",  # Pine St & 5th Ave
    "1_11191",  # 10th Ave E & E Mercer St
    "1_11300",  # E Roanoke St & Broadway  E
    "1_11330",  # Harvard Ave E & E Shelby St
    "1_11352",  # 15th Ave NE & NE 42nd St
    "1_11356",  # NE 45th St & 17th Ave NE
    "1_11357",  # NE 45th St & 20th Ave NE
    "1_11358",  # U District Station - Bay 2
    "1_11520",  # E Pine St & 12th Ave
    "1_11690",  # Mount Rainier Dr S & S Ridgeway Pl
    "1_11960",  # S Jackson St & Rainier Ave S
    "1_120",  # E Madison St & Martin L King Jr Way E
    "1_121",  # E Madison St & 23rd Ave E
    "1_122",  # E Madison St & 22nd Ave E
    "1_12200",  # Mount Rainier Dr S & 37th Pl S
    "1_12210",  # E Mcgilvra St & 42nd Ave E
    "1_12220",  # 42nd Ave E & E Lynn St
    "1_12230",  # 42nd Ave E & E Newton St
    "1_12240",  # 42nd Ave E & E Madison St
    "1_12250",  # E Madison St & 41st Ave E
    "1_12260",  # E Madison St & E Garfield St
    "1_12290",  # E Madison St & 34th Ave E
    "1_12310",  # E Madison St & Lake Washington Blvd
    "1_12353",  # E Madison St & 19th Ave
    "1_12400",  # E Madison St & Lake Washington Blvd
    "1_12410",  # E Madison St & 33rd Ave E
    "1_12420",  # E Madison St & 36th Ave E
    "1_12430",  # E Madison St & 38th Ave E
    "1_12440",  # E Madison St & 39th Ave E
    "1_12450",  # E Madison St & 41st Ave E
    "1_12460",  # 43rd Ave E & E Blaine St
    "1_12470",  # 43rd Ave E & E Madison St
    "1_12480",  # 43rd Ave E & E Lynn St
    "1_12690",  # 34th Ave & E Union St
    "1_12820",  # E Jefferson St & 15th Ave
    "1_12890",  # James St & 8th Ave
    "1_13190",  # Interlaken Turnback Loop & 19th Ave E
    "1_13200",  # 19th Ave E & E Galer St
    "1_13210",  # 19th Ave E & E Highland Dr
    "1_13220",  # 19th Ave E & E Prospect St
    "1_13230",  # 19th Ave E & E Aloha St
    "1_13240",  # 19th Ave E & E Mercer St
    "1_13250",  # 19th Ave E & E Harrison St
    "1_13260",  # 19th Ave E & E John St
    "1_13266",  # Madison St & Boren Ave
    "1_13270",  # 19th Ave & E Denny Way
    "1_13310",  # 19th Ave E & E Denny Way
    "1_13330",  # 19th Ave E & E Thomas St
    "1_13340",  # 19th Ave E & E Harrison St
    "1_13350",  # 19th Ave E & E Republican St
    "1_13370",  # 19th Ave E & E Aloha St
    "1_13380",  # 19th Ave E & E Prospect St
    "1_13381",  # 19th Ave E & E Highland Dr
    "1_13410",  # Bellevue Ave E & E Republican St
    "1_13460",  # Bellevue Ave & E Olive St
    "1_1480",  # S Jackson St & Maynard Ave S
    "1_1510",  # S Jackson St & Maynard Ave S
    "1_1540",  # James St & 5th Ave
    "1_1550",  # James St & 4th Ave
    "1_1562",  # Alaskan Way S & S Jackson St
    "1_1610",  # Prefontaine Pl S & Yesler Way
    "1_16160",  # Meridian Ave N & N 198th St
    "1_16170",  # Meridian Ave N & N 194th St
    "1_1619",  # Westlake And 7th
    "1_16190",  # Meridian Ave N & N 188th St
    "1_16200",  # Meridian Ave N & N 185th St
    "1_16220",  # Meridian Ave N & N 180th St
    "1_16250",  # Meridian Ave N & N 170th St
    "1_16270",  # Meridian Ave N & N 165th St
    "1_16280",  # Meridian Ave N & N 163rd St
    "1_16290",  # Meridian Ave N & N 160th St
    "1_16327",  # Meridian Ave N & N 155th St
    "1_16329",  # Meridian Ave N & N 150th St
    "1_16390",  # NE Ravenna Blvd & Woodlawn Ave NE
    "1_16400",  # NE Ravenna Blvd & NE 68th St
    "1_16416",  # NE 65th St & 8th Ave NE
    "1_16419",  # 8th Ave NE & NE 64th St
    "1_16430",  # Roosevelt Station - Bay 1
    "1_16440",  # Roosevelt Station - Bay 5
    "1_16460",  # Roosevelt Way NE & NE Ravenna Blvd
    "1_16480",  # Roosevelt Way NE & NE 55th St
    "1_1651",  # 5th & Jackson
    "1_16515",  # NE Ravenna Blvd & NE 68th St
    "1_16520",  # NE Ravenna Blvd & Woodlawn Ave NE
    "1_16610",  # Meridian Ave N & N 155th St
    "1_16640",  # Meridian Ave N & N 163rd St
    "1_16670",  # Meridian Ave N & N 170th St
    "1_16690",  # Meridian Ave N & N 178th St
    "1_16700",  # Meridian Ave N & N 180th St
    "1_16710",  # Meridian Ave N & N 183rd St
    "1_16740",  # Meridian Ave N & N 190th St
    "1_16750",  # Meridian Ave N & N 193rd St
    "1_1681",  # 14th & Washington
    "1_16900",  # Densmore Ave N & N 122nd St
    "1_16920",  # Meridian Ave N & N 120th St
    "1_16940",  # Meridian Ave N & N 115th St
    "1_16980",  # Meridian Ave N & N 105th St
    "1_16990",  # College Way N & N 103rd St
    "1_17022",  # N 92nd St & Corliss Ave N
    "1_17024",  # 1st Ave NE & NE 95th St
    "1_17040",  # Wallingford Ave N & N 90th St
    "1_17070",  # Wallingford Ave N & N 82nd St
    "1_17080",  # Wallingford Ave N & N 80th St
    "1_17081",  # Wallingford Ave N & East Green Lake Dr N
    "1_17170",  # Woodlawn Ave NE & 5th Ave NE
    "1_17209",  # Woodlawn Ave N & N 63rd St
    "1_17250",  # N 56th St & Keystone Pl N
    "1_17280",  # Meridian Ave N & N 50th St
    "1_17410",  # N 45th St & Wallingford Ave N
    "1_17420",  # Meridian Ave N & N 45th St
    "1_17510",  # Woodlawn Ave N & N 63rd St
    "1_17530",  # Woodlawn Ave NE & Sunnyside Ave N
    "1_17640",  # Wallingford Ave N & N 80th St
    "1_17650",  # Wallingford Ave N & N 82nd St
    "1_17651",  # Wallingford Ave N & N 85th St
    "1_17680",  # Wallingford Ave N & N 90th St
    "1_17694",  # North Seattle College
    "1_17695",  # North Seattle College
    "1_17697",  # 1st Ave NE & NE 95th St
    "1_17698",  # N 92nd St & Corliss Ave N
    "1_17710",  # College Way N & N 97th St
    "1_17730",  # College Way N & N 103rd St
    "1_17740",  # Meridian Ave N & N 105th St
    "1_17755",  # N Northgate Way & Meridian Ave N
    "1_17780",  # Meridian Ave N & N 115th St
    "1_17820",  # N 122nd St & Burke Ave N
    "1_18455",  # Dexter Ave N & Harrison St
    "1_18465",  # Dexter Ave N & Roy St
    "1_1920",  # Lenora St & 4th Ave
    "1_19440",  # Denny Way & Queen Anne Ave N
    "1_20600",  # West Viewmont Way W & 42nd Ave W
    "1_20610",  # West Viewmont Way W & W Parkmont Pl
    "1_20620",  # West Viewmont Way W & Montavista Pl W
    "1_20630",  # West Viewmont Way W & Constance Dr W
    "1_20640",  # Viewmont Way W & Edgemont Pl W
    "1_20650",  # 35th Ave W & W Mcgraw St
    "1_20670",  # W Mcgraw St & 32nd Ave W
    "1_20680",  # Condon Way W & W Crockett St
    "1_20700",  # 28th Ave W & W Blaine St
    "1_20710",  # 28th Ave W & W Eaton St
    "1_20720",  # W Galer St & Thorndyke Ave W
    "1_20880",  # Thorndyke Ave W & W Hayes St
    "1_20890",  # 28th Ave W & W Blaine St
    "1_20910",  # Condon Way W & W Crockett St
    "1_20940",  # Viewmont Way W & 35th Ave W
    "1_20950",  # Viewmont Way W & Edgemont Pl W
    "1_20960",  # West Viewmont Way W & Constance Dr W
    "1_20970",  # West Viewmont Way W & Montavista Pl W
    "1_20980",  # West Viewmont Way W & W Parkmont Pl
    "1_20990",  # West Viewmont Way W & Westmont Way W
    "1_2150",  # W Roy St & 2nd Ave W
    "1_21690",  # Airport Way S & S Stevens St
    "1_21850",  # Airport Way S & S Royal Brougham Way
    "1_21910",  # Airport Way S & S Stevens St
    "1_21920",  # Airport Way S & Diagonal Ave S
    "1_2220",  # 3rd Ave & Cedar St
    "1_2291",  # Denny Way & Westlake Ave
    "1_2320",  # 1st Ave & Broad St
    "1_23250",  # 5th Ave NE & NE 106th St
    "1_23260",  # 5th Ave NE & NE 103rd St
    "1_23273",  # NE 100th St & 4th Ave NE
    "1_23276",  # NE 100th St & 4th Ave NE
    "1_23370",  # Roosevelt Way NE & NE 80th St
    "1_23390",  # Roosevelt Way NE & NE 75th St
    "1_23420",  # Roosevelt Way NE & NE 69th St
    "1_23421",  # Roosevelt Station - Bay 4
    "1_23500",  # 11th Ave NE & NE 50th St
    "1_23520",  # 11th Ave NE & NE 55th St
    "1_23530",  # 11th Ave NE & NE Ravenna Blvd
    "1_23540",  # 12th Ave NE & NE 61st St
    "1_23561",  # Roosevelt Station - Bay 3
    "1_23580",  # 12th Ave NE & NE 70th St
    "1_23600",  # NE 75th St & 12th Ave NE
    "1_23610",  # Roosevelt Way NE & NE 75th St
    "1_23750",  # 5th Ave NE & NE 103rd St
    "1_23895",  # 25th Ave NE & NE 75th St
    "1_23905",  # 25th Ave NE & NE 65th St
    "1_23910",  # 25th Ave NE & NE 60th St
    "1_23915",  # 25th Ave NE & NE 55th St
    "1_23920",  # 25th Ave NE & NE Blakeley St
    "1_23925",  # 25th Ave NE & NE 47th St
    "1_24250",  # 34th Ave W & W Mcgraw St
    "1_24260",  # 34th Ave W & W Mcgraw St
    "1_24490",  # 28th Ave W & W Smith St
    "1_24500",  # 28th Ave W & W Lynn St
    "1_24510",  # 28th Ave W & W Crockett St
    "1_24540",  # 28th Ave W & W Crockett St
    "1_24544",  # 28th Ave W & W Lynn St
    "1_24560",  # 28th Ave W & W Halladay St
    "1_24910",  # 35th Ave NE & NE 123rd St
    "1_24920",  # 35th Ave NE & NE 120th St
    "1_24940",  # 35th Ave NE & NE 115th St
    "1_24950",  # 35th Ave NE & NE 110th St
    "1_24960",  # 35th Ave NE & NE 105th St
    "1_24980",  # 35th Ave NE & NE 100th St
    "1_24990",  # 35th Ave NE & NE 97th St
    "1_25000",  # 35th Ave NE & NE 94th St
    "1_25010",  # 35th Ave NE & NE 92nd St
    "1_25090",  # 35th Ave NE & NE 70th St
    "1_25110",  # 35th Ave NE & NE 65th St
    "1_25130",  # 35th Ave NE & NE 60th St
    "1_25201",  # NE 45th St & University Village
    "1_25202",  # NE 45th St & University Village
    "1_25210",  # Montlake Blvd NE & NE 45th St
    "1_25240",  # Montlake Blvd NE & NE Pacific Pl - Bay 3
    "1_25751",  # Montlake Blvd E & Sr 520
    "1_25753",  # Sr 520 & Montlake Blvd E
    "1_25754",  # Sr 520 & Montlake Blvd E
    "1_25755",  # Montlake Blvd NE & NE Pacific Pl - Bay 4
    "1_25765",  # Montlake Blvd NE & NE Pacific Pl - Bay 5
    "1_25790",  # Montlake Blvd NE & NE 45th St
    "1_25791",  # 25th Ave NE & NE 47th St
    "1_25793",  # 25th Ave NE & NE 55th St
    "1_25794",  # 25th Ave NE & NE 60th St
    "1_25795",  # 25th Ave NE & NE 65th St
    "1_25797",  # 25th Ave NE & NE 75th St
    "1_25798",  # 25th Ave NE & NE 80th St
    "1_25840",  # 35th Ave NE & NE 55th St
    "1_25860",  # 35th Ave NE & NE 60th St
    "1_25880",  # 35th Ave NE & NE 65th St
    "1_25900",  # 35th Ave NE & NE 70th St
    "1_25940",  # 35th Ave NE & NE 80th St
    "1_25980",  # 35th Ave NE & NE 89th St
    "1_26000",  # 35th Ave NE & NE 93rd St
    "1_26020",  # 35th Ave NE & NE 97th St
    "1_26050",  # 35th Ave NE & NE 105th St
    "1_26060",  # 35th Ave NE & NE 110th St
    "1_26080",  # 35th Ave NE & NE 115th St
    "1_26100",  # 35th Ave NE & NE 120th St
    "1_26110",  # 35th Ave NE & NE 123rd St
    "1_26370",  # N 40th St & Eastern Ave N
    "1_26381",  # N 40th St & Bagley Ave N
    "1_26410",  # Wallingford Ave N & N 39th St
    "1_26665",  # Westlake & 9th-Denny
    "1_26698",  # Terry & Mercer
    "1_26700",  # Fairview & Campus Drive
    "1_26702",  # Lake Union Park
    "1_26730",  # Westlake Ave N & Mercer St
    "1_26965",  # N 40th St & Wallingford Ave N
    "1_26980",  # N 40th St & Bagley Ave N
    "1_26999",  # N 40th St & Eastern Ave N
    "1_2710",  # Queen Anne Ave N & Aloha St
    "1_27520",  # E Yesler Way & 14th Ave S
    "1_27530",  # E Yesler Way & 16th Ave S
    "1_27540",  # E Yesler Way & 18th Ave S
    "1_2850",  # Madrona Park & Lake Washington Blvd
    "1_2860",  # Madrona Dr & Newport Way
    "1_28680",  # NW 100th Pl & 7th Ave NW
    "1_2870",  # Madrona Dr & E Pine St
    "1_2880",  # Madrona Dr & E Olive St
    "1_2890",  # Madrona Dr & Madrona Pl E
    "1_2900",  # E Denny Way & E Florence Ct
    "1_2910",  # 34th Ave & E Howell St
    "1_29100",  # NE 45th St & 42nd Ave NE
    "1_2911",  # 34th Ave & E Olive St
    "1_29130",  # NE 45th St & 36th Ave NE
    "1_2920",  # 34th Ave & E Pine St
    "1_29236",  # NE 45th St & Thackeray Pl NE
    "1_29238",  # East Montlake Pl E & E Roanoke St
    "1_29240",  # NE Pacific St & 15th Ave NE
    "1_29242",  # NE Pacific Pl & NE Pacific St
    "1_29243",  # NE Pacific Pl & NE Pacific St
    "1_29244",  # 24th Ave E & E Mcgraw St
    "1_29247",  # NE Pacific St & Montlake Blvd NE - Bay 1
    "1_29248",  # 24th Ave E & E Newton St
    "1_29249",  # 24th Ave E & Boyer Ave E
    "1_29251",  # 24th Ave E & E Galer St
    "1_29254",  # 23rd Ave E & E Aloha St
    "1_29256",  # 23rd Ave E & E Republican St
    "1_29257",  # 23rd Ave E & E Thomas St
    "1_29258",  # E John St & 22nd Ave E
    "1_29259",  # E Thomas St & 19th Ave E
    "1_29262",  # E John St & Broadway  E - Bay 2
    "1_29266",  # E Olive Way & Summit Ave E
    "1_29268",  # E Olive Way & Summit Ave E
    "1_29273",  # E John St & 15th Ave E
    "1_29275",  # E Thomas St & 19th Ave E
    "1_29276",  # E John St & 22nd Ave E
    "1_29278",  # 23rd Ave E & E Republican St
    "1_29280",  # 23rd Ave E & E Aloha St
    "1_2930",  # 34th Ave & E Union St
    "1_29300",  # 24th Ave E & E Prospect St
    "1_29320",  # 24th Ave E & E Galer St
    "1_29340",  # 24th Ave E & Boyer Ave E
    "1_29350",  # 24th Ave E & E Newton St
    "1_29361",  # 24th Ave E & E Mcgraw St
    "1_29380",  # East Montlake Pl E & E Roanoke St
    "1_2940",  # E Union St & 33rd Ave
    "1_29405",  # NE Pacific St & Montlake Blvd NE - Bay 2
    "1_29420",  # NE Pacific St & 15th Ave NE
    "1_29423",  # Brooklyn Ave NE & NE Pacific St
    "1_29431",  # 15th Ave NE & NE Pacific St
    "1_29440",  # 15th Ave NE & NE Campus Pkwy
    "1_29455",  # NE 45th St & 9th Ave NE
    "1_2950",  # E Union St & 31st Ave
    "1_29500",  # N 45th St & Sunnyside Ave N
    "1_2960",  # E Union St & 29th Ave
    "1_2970",  # E Union St & 27th Ave
    "1_2980",  # E Union St & 25th Ave
    "1_29865",  # NE 45th St & Roosevelt Way NE
    "1_29889",  # NE 45th St & Memorial Way NE
    "1_29891",  # NE 45th St & 19th Ave NE
    "1_29920",  # NE 45th St & Mary Gates Memorial Dr NE
    "1_29930",  # NE 45th St & 36th Ave NE
    "1_2995",  # E Union St & 23rd Ave
    "1_29950",  # NE 45th St & 40th Ave NE
    "1_29952",  # NE 45th St & 42nd Ave NE
    "1_3030",  # E Union St & 14th Ave
    "1_3036",  # Seneca St & Terry Ave
    "1_30410",  # Beacon Ave S & S Orcas St
    "1_30430",  # Beacon Ave S & S Brandon St
    "1_30440",  # Beacon Ave S & S Dawson St
    "1_30460",  # S Columbian Way & Beacon Ave S
    "1_30480",  # S Columbian Way & Veterans Administration Hospital Rd
    "1_30490",  # S Columbian Way & S Oregon St
    "1_30820",  # S Columbian Way & S Snoqualmie St
    "1_30870",  # Beacon Ave S & S Brandon St
    "1_30890",  # Beacon Ave S & S Orcas St
    "1_30930",  # Beacon Ave S & S Graham St
    "1_30950",  # Beacon Ave S & S Holly St
    "1_31300",  # Thorndyke Ave W & 23rd Ave W
    "1_31310",  # Thorndyke Ave W & Thorndyke Pl W
    "1_31320",  # Thorndyke Ave W & W Boston St
    "1_31330",  # Thorndyke Ave W & W Newton St
    "1_31340",  # W Blaine St & 27th Ave W
    "1_31350",  # Thorndyke Ave W & W Blaine St
    "1_31360",  # Thorndyke Ave W & W Newton St
    "1_31370",  # Thorndyke Ave W & W Boston St
    "1_31380",  # Thorndyke Ave W & W Lynn St
    "1_31390",  # Thorndyke Ave W & 23rd Ave W
    "1_3151",  # Seneca St & 9th Ave
    "1_3155",  # E Union St & Broadway
    "1_3156",  # E Madison St & 12th Ave
    "1_3200",  # E Union St & 20th Ave
    "1_3210",  # E Union St & 23rd Ave
    "1_3220",  # E Union St & 26th Ave
    "1_3230",  # E Union St & Martin L King Jr Way
    "1_3240",  # E Union St & 30th Ave
    "1_3250",  # E Union St & 32nd Ave
    "1_3271",  # 34th Ave & E Olive St
    "1_3280",  # 34th Ave & E Howell St
    "1_3320",  # Madrona Dr & E Pine St
    "1_3330",  # Madrona Dr & Newport Way
    "1_3400",  # Beacon Ave S & Veterans Administration Hospital
    "1_3410",  # Beacon Ave S & Jefferson Golf Course
    "1_34770",  # S Dawson St & 51st Ave S
    "1_34780",  # 50th Ave S & S Hudson St
    "1_34800",  # 50th Ave S & S Alaska St
    "1_34840",  # S Genesee St & 47th Ave S
    "1_34860",  # S Genesee St & 43rd Ave S
    "1_34910",  # S Genesee St & 36th Ave S
    "1_34930",  # S Genesee St & Cascadia Ave S
    "1_34960",  # S Genesee St & 46th Ave S
    "1_35231",  # NE 125th St & 28th Ave NE
    "1_35233",  # NE 125th St & 25th Ave NE
    "1_35250",  # NE 125th St & 20th Ave NE
    "1_35270",  # NE 125th St & 15th Ave NE
    "1_35290",  # NE 103rd St & 5th Ave NE
    "1_35317",  # Northgate Station - Bay 1
    "1_35318",  # Northgate Station - Bay 4
    "1_35319",  # Northgate Station - Bay 3
    "1_35331",  # NE Northgate Way & 23rd Ave NE
    "1_35332",  # NE Northgate Way & 15th Ave NE
    "1_35333",  # NE Northgate Way & 23rd Ave NE
    "1_35334",  # NE Northgate Way & 19th Ave NE
    "1_35336",  # NE Northgate Way & 19th Ave NE
    "1_35380",  # NE 125th St & 15th Ave NE
    "1_35400",  # NE 125th St & 20th Ave NE
    "1_35420",  # NE 125th St & 25th Ave NE
    "1_35660",  # NW 85th St & 3rd Ave NW
    "1_35670",  # N 85th St & 1st Ave NW
    "1_35691",  # East Green Lake Dr N & Meridian Ave N
    "1_35721",  # East Green Lake Dr N & 4th Ave NE
    "1_3580",  # S Charles St & Golf Dr S
    "1_35800",  # 15th Ave NE & NE 50th St
    "1_35825",  # 23rd Ave E & E John St
    "1_35850",  # 23rd Ave & E Pine St
    "1_35860",  # 23rd Ave & E Union St
    "1_35960",  # S Alaska St & 35th Ave S
    "1_35979",  # S Alaska St & Martin L King Jr Way S
    "1_35990",  # S Columbian Way & S Americus St
    "1_36690",  # S Columbian Way & S Americus St
    "1_36700",  # S Alaska St & S Alaska Pl
    "1_36720",  # S Alaska St & 35th Ave S
    "1_36845",  # 23rd Ave & E Olive St
    "1_36931",  # NE 65th St & 14th Ave NE
    "1_36940",  # Roosevelt Station - Bay 2
    "1_36960",  # NE 65th St & Oswego Pl NE
    "1_36961",  # East Green Lake Dr N & 4th Ave NE
    "1_36991",  # East Green Lake Dr N & Meridian Ave N
    "1_37020",  # East Green Lake Dr N & Wallingford Ave N
    "1_37352",  # University Way NE & NE 55th St
    "1_37353",  # University Way NE & NE Ravenna Blvd
    "1_37359",  # NE 65th St & 14th Ave NE
    "1_37381",  # NE 65th St & 20th Ave NE
    "1_37400",  # NE 65th St & 23rd Ave NE
    "1_37410",  # NE 65th St & 25th Ave NE
    "1_37420",  # NE 65th St & 27th Ave NE
    "1_37430",  # NE 65th St & 29th Ave NE
    "1_37440",  # NE 65th St & 31st Ave NE
    "1_37450",  # NE 65th St & 33rd Ave NE
    "1_37460",  # NE 65th St & 35th Ave NE
    "1_37470",  # NE 65th St & 38th Ave NE
    "1_37490",  # NE 65th St & 43rd Ave NE
    "1_37530",  # 50th Ave NE & NE 68th St
    "1_37748",  # NE 75th St & 40th Ave NE
    "1_37749",  # NE 75th St & 40th Ave NE
    "1_37760",  # NE 75th St & 44th Ave NE
    "1_37780",  # NE 75th St & 48th Ave NE
    "1_37790",  # NE 75th St & 50th Ave NE
    "1_37870",  # NE Princeton Way & Princeton Ave NE
    "1_37910",  # NE 65th St & 42nd Ave NE
    "1_37920",  # NE 65th St & 39th Ave NE
    "1_37930",  # NE 65th St & 37th Ave NE
    "1_37940",  # NE 65th St & 35th Ave NE
    "1_37950",  # NE 65th St & 32nd Ave NE
    "1_37970",  # NE 65th St & 28th Ave NE
    "1_37980",  # NE 65th St & 26th Ave NE
    "1_37990",  # NE 65th St & 25th Ave NE
    "1_38020",  # NE 65th St & 18th Ave NE
    "1_38022",  # University Way NE & NE Ravenna Blvd
    "1_38024",  # University Way NE & NE 55th St
    "1_38080",  # 30th Ave NE & NE 135th St
    "1_38090",  # 30th Ave NE & NE 133rd St
    "1_38100",  # 30th Ave NE & NE 130th St
    "1_38110",  # 30th Ave NE & NE 127th St
    "1_38145",  # Lake City Way NE & NE 120th St
    "1_38160",  # Lake City Way NE & NE 115th St
    "1_38180",  # Lake City Way NE & NE 110th St
    "1_38200",  # Lake City Way NE & 24th Ave NE
    "1_38220",  # Lake City Way NE & NE 98th St
    "1_38235",  # Lake City Way NE & 20th Ave NE
    "1_38240",  # Ravenna Ave NE & NE 92nd St
    "1_38260",  # Ravenna Ave NE & NE 86th St
    "1_3830",  # Beacon Ave S & S Hanford St
    "1_38350",  # 15th Ave NE & NE 75th St
    "1_38370",  # 15th Ave NE & NE 70th St
    "1_38390",  # 15th Ave NE & NE 65th St
    "1_38410",  # 15th Ave NE & NE 70th St
    "1_38530",  # Ravenna Ave NE & NE 86th St
    "1_38550",  # Ravenna Ave NE & NE 92nd St
    "1_38567",  # Lake City Way NE & NE 85th St
    "1_38570",  # Lake City Way NE & NE 98th St
    "1_38590",  # Lake City Way NE & 24th Ave NE
    "1_3860",  # Beacon Ave S & S Spokane St
    "1_38610",  # Lake City Way NE & NE 110th St
    "1_38620",  # Lake City Way NE & NE 113th St
    "1_38650",  # Lake City Way NE & NE 120th St
    "1_38670",  # 30th Ave NE & NE 127th St
    "1_38680",  # 30th Ave NE & NE 130th St
    "1_3880",  # Beacon Ave S & Jefferson Golf Course
    "1_3881",  # Beacon Ave S & Veterans Administration Hospital
    "1_3883",  # Beacon Ave S & S Columbian Way
    "1_38870",  # 15th Ave NE & NE 135th St
    "1_38890",  # 15th Ave NE & NE 130th St
    "1_38900",  # 15th Ave NE & NE 127th St
    "1_38910",  # 15th Ave NE & NE 125th St
    "1_38920",  # 15th Ave NE & NE 123rd St
    "1_38930",  # 15th Ave NE & NE 120th St
    "1_38962",  # Pinehurst Way NE & NE 115th St
    "1_39230",  # 15th Ave NE & NE 120th St
    "1_39240",  # 15th Ave NE & NE 123rd St
    "1_39250",  # 15th Ave NE & NE 125th St
    "1_39260",  # 15th Ave NE & NE 127th St
    "1_39290",  # 15th Ave NE & NE 135th St
    "1_39334",  # 15th Ave NE & NE 160th St
    "1_40040",  # Holman Rd NW & 3rd Ave NW
    "1_40058",  # Holman Rd NW & 3rd Ave NW
    "1_40060",  # Holman Rd N & Greenwood Ave N
    "1_40068",  # N Northgate Way & Aurora Ave N
    "1_40070",  # N Northgate Way & Stone Ave N
    "1_40078",  # Thorndyke Ave W & W Blaine St
    "1_40880",  # 13th Ave S & S Bailey St
    "1_40882",  # Airport Way S & S Doris St
    "1_40885",  # Airport Way S & Corson Ave S
    "1_41080",  # Airport Way S & S Doris St
    "1_41450",  # N 85th St & Greenwood Ave N
    "1_41760",  # Swift Ave S & 16th Ave S
    "1_41780",  # 15th Ave S & S Lucile St
    "1_41805",  # 15th Ave S & S Shelton St
    "1_41819",  # 15th Ave S & S Angeline St
    "1_41830",  # 15th Ave S & S Oregon St
    "1_41850",  # 15th Ave S & S Spokane St
    "1_41870",  # 15th Ave S & S Hanford St
    "1_41902",  # Boren Ave & E Yesler Way
    "1_41970",  # Broadway & Pike-Pine
    "1_41982",  # Broadway & E Union St
    "1_41986",  # Broadway & Marion
    "1_41988",  # Broadway & Terrace St
    "1_41989",  # Boren Ave & E Yesler Way
    "1_420",  # 3rd Ave & Virginia St
    "1_42050",  # 15th Ave S & S Hanford St
    "1_42070",  # 15th Ave S & S Spokane St
    "1_42080",  # 15th Ave S & S Oregon St
    "1_42091",  # 15th Ave S & S Angeline St
    "1_42105",  # 15th Ave S & S Shelton St
    "1_42120",  # 15th Ave S & S Dawson St
    "1_42130",  # 15th Ave S & S Lucile St
    "1_4230",  # 5th Ave N & Republican St
    "1_431",  # 3rd Ave & Pike St
    "1_433",  # 3rd Ave & Pike St
    "1_43706",  # Martin L King Jr Way E & E John St
    "1_43710",  # Martin L King Jr Way & E Olive St
    "1_43712",  # Martin L King Jr Way & E Union St
    "1_43788",  # Martin L King Jr Way & E Olive St
    "1_43792",  # Martin L King Jr Way E & E John St
    "1_45731",  # Swift Ave S & S Warsaw St
    "1_45732",  # Swift Ave S & 18th Ave S
    "1_46022",  # Ellis Ave S & S Warsaw St
    "1_481",  # 3rd Ave & Columbia St
    "1_490",  # 3rd Ave & Cherry St
    "1_515",  # 3rd Ave S & S Main St
    "1_5330",  # N 85th St & Greenwood Ave N
    "1_5350",  # N 85th St & Fremont Ave N
    "1_5370",  # N 85th St & Aurora Ave N
    "1_538",  # 3rd Ave & Columbia St
    "1_5380",  # N 85th St & Stone Ave N
    "1_5400",  # N 85th St & Wallingford Ave N
    "1_5402",  # NE 42nd St & 8th Ave NE
    "1_5420",  # N 85th St & Wallingford Ave N
    "1_5440",  # N 85th St & Stone Ave N
    "1_5450",  # N 85th St & Aurora Ave N
    "1_5487",  # Carlyle Hall Rd N & Dayton Ave N
    "1_55681",  # Martin L King Jr Way S & S Holly St
    "1_55711",  # Martin L King Jr Way S & 37th Ave S
    "1_55729",  # Martin L King Jr Way S & S Orcas St
    "1_55771",  # Martin L King Jr Way S & S Edmunds St
    "1_55780",  # Martin L King Jr Way S & S Alaska St
    "1_55812",  # Martin L King Jr Way S & S Andover St
    "1_55831",  # Martin L King Jr Way S & S Walden St
    "1_55851",  # Martin L King Jr Way S & S Hanford St
    "1_55960",  # Martin L King Jr Way S & S Winthrop St
    "1_55980",  # Martin L King Jr Way S & S Walden St
    "1_55991",  # Martin L King Jr Way S & S Andover St
    "1_56000",  # Martin L King Jr Way S & S Dakota St
    "1_56031",  # Martin L King Jr Way S & S Alaska St
    "1_56061",  # Martin L King Jr Way S & S Dawson St
    "1_56111",  # Martin L King Jr Way S & S Graham St
    "1_5710",  # Greenwood Ave N & Holman Rd N
    "1_5730",  # Greenwood Ave N & N 100th St
    "1_5740",  # Greenwood Ave N & N 97th St
    "1_5770",  # Greenwood Ave N & N 90th St
    "1_5771",  # Greenwood Ave N & N 87th St
    "1_5790",  # Greenwood Ave N & N 85th St
    "1_5810",  # Greenwood Ave N & N 80th St
    "1_5840",  # Greenwood Ave N & N 74th St
    "1_5860",  # Greenwood Ave N & N 70th St
    "1_5880",  # Phinney Ave N & N 65th St
    "1_600",  # 3rd Ave & Virginia St
    "1_619",  # 4th Ave S & S Jackson St
    "1_6236",  # 7th Ave N & Denny Way
    "1_625",  # S Washington St & 4th Ave S
    "1_628",  # 4th Ave S & S Washington St
    "1_6520",  # Phinney Ave N & N 60th St
    "1_6580",  # Greenwood Ave N & N 72nd St
    "1_6590",  # Greenwood Ave N & N 75th St
    "1_6615",  # Greenwood Ave N & N 80th St
    "1_6650",  # Greenwood Ave N & N 87th St
    "1_6658",  # NW 90th St & 1st Ave NW
    "1_6660",  # Greenwood Ave N & N 90th St
    "1_6685",  # Greenwood Ave N & N 97th St
    "1_670",  # 4th Ave & Seneca St
    "1_6710",  # Greenwood Ave N & N 103rd St
    "1_68873",  # Lakeview Dr NE & NE 59th St
    "1_68875",  # Lakeview Dr NE & NE 64th St
    "1_68890",  # Lake Washington Blvd NE & NE 52nd St
    "1_68900",  # Lake Washington Blvd NE & NE 52nd St
    "1_68910",  # Lake Washington Blvd NE & NE 43rd St
    "1_68920",  # Lake Washington Blvd NE & NE 38th Pl
    "1_68930",  # Bellevue Way NE & NE 30th Pl
    "1_68940",  # Bellevue Way NE & NE 28th Pl
    "1_69390",  # Bellevue Way NE & NE 28th Pl
    "1_69430",  # Lake Washington Blvd NE & NE 46th St
    "1_69440",  # Lake Washington Blvd NE & NE 52nd St
    "1_70679",  # 6th St S & 9th Ave S
    "1_70681",  # NE 68th St & 6th St S
    "1_7080",  # Aurora Ave N & N 105th St
    "1_7100",  # Aurora Ave N & N 100th St
    "1_71356",  # Sr 520 & 92nd Avenue Northeast
    "1_71359",  # Sr 520 & 92nd Ave NE
    "1_7140",  # Aurora Ave N & N 90th St
    "1_7160",  # Aurora Ave N & N 85th St
    "1_7180",  # Aurora Ave N & N 80th St
    "1_720",  # 4th Ave & Stewart St
    "1_7200",  # Aurora Ave N & N 76th St
    "1_7210",  # Aurora Ave N & N 65th St
    "1_72100",  # NE 70th St & 124th Ave NE
    "1_72120",  # NE 70th St & 120th Ave NE
    "1_72134",  # NE 72nd Pl & 116th Ave NE
    "1_72140",  # NE 68th St & 112th Ave NE
    "1_72155",  # 108th Ave NE & NE 62nd St
    "1_72156",  # 108th Ave NE & NE 68th St
    "1_72161",  # 6th St S & 9th Ave S
    "1_72180",  # State St S & 10th Ave S
    "1_72190",  # State St & 7th Ave S
    "1_72232",  # State St & 6th Ave S
    "1_72250",  # State St S & 10th Ave S
    "1_72288",  # NE 68th St & 110th Ave NE
    "1_72289",  # NE 68th St & 110th Ave NE
    "1_72290",  # NE 68th St & 112th Ave NE
    "1_72294",  # NE 72nd Pl & 116th Ave NE
    "1_72310",  # NE 70th St & 120th Ave NE
    "1_72311",  # NE 70th Pl & 116th Ave NE
    "1_72312",  # NE 70th Pl & 116th Ave NE
    "1_72330",  # NE 70th St & 124th Ave NE
    "1_730",  # 4th Ave & Lenora St
    "1_7430",  # Wall St & 5th Ave
    "1_74395",  # 108th Ave NE & NE 68th St
    "1_74396",  # 108th Ave NE & NE 62nd St
    "1_74400",  # 108th Ave NE & NE 60th St
    "1_74410",  # 108th Ave NE & NE 58th St
    "1_74420",  # 108th Ave NE & NE 53rd St
    "1_74430",  # 108th Ave NE & NE 47th Pl
    "1_74440",  # 108th Ave NE & NE 45th St
    "1_74441",  # 108th Ave NE & NE 39th St
    "1_74442",  # 108th Ave NE & NE 38th Pl
    "1_74446",  # Northup Way & NE 30th St
    "1_74450",  # South Kirkland Park & Ride
    "1_74460",  # 108th Ave NE & Northup Way
    "1_74530",  # 108th Ave NE & NE 45th St
    "1_74533",  # 108th Ave NE & NE 39th St
    "1_74570",  # 108th Ave NE & NE 60th St
    "1_75030",  # Dayton Ave N & N 183rd St
    "1_75060",  # Dayton Ave N & St. Luke Pl N
    "1_75110",  # Dayton Ave N & N 160th St
    "1_75120",  # Dayton Ave N & N 155th St
    "1_75135",  # N 175th St & Aurora Ave N
    "1_75136",  # Fremont Ave N & N 175th St
    "1_75137",  # Fremont Ave N & N 175th St
    "1_75144",  # Fremont Ave N & N 167th St
    "1_75402",  # Stevens Way & Rainier Vista NE
    "1_75403",  # East Stevens Way NE & Benton Ln
    "1_75405",  # West Stevens Way NE & George Washington Ln
    "1_75406",  # East Stevens Way NE & Pend Oreille Rd
    "1_75410",  # Stevens Way & Pend Oreille Rd
    "1_75414",  # Stevens Way & Benton Ln
    "1_75417",  # Stevens Way & Okanogan Ln
    "1_75460",  # Dayton Ave N & N 160th St
    "1_75510",  # Dayton Ave N & St. Luke Pl N
    "1_75520",  # Dayton Ave N & N 179th Pl
    "1_75540",  # Dayton Ave N & N 185th St
    "1_75585",  # N 185th St & Fremont Ave N
    "1_75734",  # N 185th St & Ashworth Ave N
    "1_75750",  # Aurora Ave N & N 180th St
    "1_75751",  # N 175th St & Aurora Ave N
    "1_75754",  # N 175th St & Densmore Ave N
    "1_75760",  # Aurora Ave N & N 175th St
    "1_75770",  # Aurora Ave N & N 170th St
    "1_75789",  # Westminster Way N & N 155th St
    "1_75790",  # Aurora Ave N & N 160th St
    "1_75800",  # Aurora Ave N & N 155th St
    "1_75810",  # Aurora Ave N & N 152nd St
    "1_75840",  # Aurora Ave N & N 155th St
    "1_75860",  # Aurora Ave N & N 165th St
    "1_75884",  # N 175th St & Meridian Ave N
    "1_75889",  # N 175th St & Midvale Ave N
    "1_75890",  # Aurora Ave N & N 180th St
    "1_75901",  # Aurora Ave N & N 185th St
    "1_75902",  # N 185th St & Meridian Ave N
    "1_75910",  # Aurora Ave N & N 192nd St
    "1_75932",  # Aurora Ave N & N 200th St
    "1_7630",  # Woodland Pl N & N 65th St
    "1_7670",  # Linden Ave N & N 72nd St
    "1_76700",  # Lake City Way NE & NE 130th St
    "1_76710",  # Lake City Way NE & NE 125th St
    "1_76730",  # Lake City Way NE & NE 130th St
    "1_76731",  # Lake City Way NE & NE 135th St
    "1_7690",  # Aurora Ave N & N 76th St
    "1_7710",  # Aurora Ave N & N 80th St
    "1_7730",  # Aurora Ave N & N 85th St
    "1_77418",  # 15th Ave NE & NE 200th Ct
    "1_77480",  # 15th Ave NE & NE 175th St
    "1_77490",  # 15th Ave NE & NE 172nd St
    "1_7750",  # Aurora Ave N & N 91st St
    "1_77510",  # 15th Ave NE & NE 168th St
    "1_77520",  # 15th Ave NE & NE 165th St
    "1_77560",  # 5th Ave NE & NE 163rd St
    "1_77570",  # 5th Ave NE & NE 161st St
    "1_77609",  # N 155th St & Meridian Ave N
    "1_77615",  # N 155th St & Ashworth Ave N
    "1_77616",  # NE 155th St & 1st Ave NE
    "1_77619",  # N 155th St & Midvale Ave N
    "1_77630",  # 15th Ave NE & NE 155th St
    "1_7770",  # Aurora Ave N & N 95th St
    "1_77732",  # 5th Ave NE & NE 175th St
    "1_77738",  # NE 175th St & 15th Ave NE
    "1_77780",  # 5th Ave NE & NE 155th St
    "1_77790",  # 5th Ave NE & NE 158th St
    "1_77810",  # 5th Ave NE & NE 163rd St
    "1_77880",  # 15th Ave NE & NE 170th St
    "1_77882",  # 15th Ave NE & NE 172nd St
    "1_77890",  # 15th Ave NE & NE 175th St
    "1_7790",  # Aurora Ave N & N 100th St
    "1_77930",  # 15th Ave NE & NE Perkins Way
    "1_77939",  # 15th Ave NE & NE 192nd St
    "1_77950",  # 15th Ave NE & NE 196th St
    "1_7810",  # Aurora Ave N & N Northgate Way
    "1_7850",  # Aurora Ave N & N 115th St
    "1_800",  # 5th Ave & Spring St
    "1_81236",  # NE 185th St & 3rd Ave NE
    "1_81243",  # Shoreline North/185th Station - Bay 3
    "1_81248",  # 5th Ave NE & NE 170th St
    "1_81252",  # 5th Ave NE & NE 155th St
    "1_81254",  # 5th Ave NE & NE 152nd St
    "1_81302",  # 5th Ave NE & NE 152nd St
    "1_81305",  # 5th Ave NE & NE 170th St
    "1_81309",  # 5th Ave NE & NE 174th St
    "1_81311",  # 10th Ave NE & NE 180th St
    "1_81315",  # 10th Ave NE & NE 180th St
    "1_81316",  # 5th Ave NE & NE 180th St
    "1_81322",  # NE 185th St & 3rd Ave NE
    "1_81361",  # Pinehurst Way NE & NE 115th St
    "1_81367",  # NE Northgate Way & Roosevelt Way NE
    "1_81368",  # Roosevelt Way NE & NE 111th St
    "1_8190",  # Rainier Ave S & S Holly St
    "1_8210",  # Rainier Ave S & S Graham St
    "1_82126",  # NE 75th St & 31st Ave NE
    "1_82127",  # NE 75th St & 20th Ave NE
    "1_82128",  # NE 75th St & 25th Ave NE
    "1_82129",  # NE 75th St & 36th Ave NE
    "1_82145",  # Roosevelt Way NE & NE 80th St
    "1_82155",  # Roosevelt Way NE & NE 85th St
    "1_82165",  # Roosevelt Way NE & NE 90th St
    "1_82167",  # Roosevelt Way NE & NE 92nd St
    "1_82175",  # Roosevelt Way NE & NE 95th St
    "1_82185",  # Roosevelt Way NE & NE 100th St
    "1_82187",  # Roosevelt Way NE & NE 103rd St
    "1_82195",  # Roosevelt Way NE & NE 105th St
    "1_82197",  # Roosevelt Way NE & NE 108th St
    "1_82198",  # NE Northgate Way & Roosevelt Way NE
    "1_82205",  # Roosevelt Way NE & NE 108th St
    "1_82207",  # Roosevelt Way NE & NE 105th St
    "1_82216",  # Roosevelt Way NE & NE 102nd St
    "1_82227",  # Roosevelt Way NE & NE 95th St
    "1_82235",  # Roosevelt Way NE & NE 92nd St
    "1_82237",  # Roosevelt Way NE & NE 90th St
    "1_82247",  # Roosevelt Way NE & NE 85th St
    "1_82266",  # NE 75th St & 16th Ave NE
    "1_82273",  # NE 75th St & 30th Ave NE
    "1_82275",  # NE 75th St & 20th Ave NE
    "1_82276",  # NE 75th St & 25th Ave NE
    "1_8231",  # Rainier Ave S & S Kenny St
    "1_82324",  # Ballinger Way NE & 25th Ave NE
    "1_82326",  # Ballinger Way NE & 23rd Ave NE
    "1_8250",  # Rainier Ave S & S Orcas St
    "1_82775",  # Ballinger Way NE & 23rd Ave NE
    "1_8285",  # Rainier Ave S & 39th Ave S
    "1_8300",  # Rainier Ave S & S Edmunds St
    "1_8310",  # Rainier Ave S & S Alaska St
    "1_8330",  # Rainier Ave S & S Genesee St
    "1_8360",  # Rainier Ave S & 33rd Ave S
    "1_8380",  # Rainier Ave S & S Walden St
    "1_8400",  # Rainier Ave S & S Mount Baker Blvd
    "1_8402",  # Mount Baker Transit Center - Bay 2
    "1_844",  # 5th Ave S & S Weller St
    "1_8494",  # Rainier Ave S & S Charles St
    "1_85040",  # 108th Ave NE & NE 38th Pl
    "1_8510",  # Rainier Ave S & S Dearborn St
    "1_8530",  # S Jackson St & Boren Ave S
    "1_8681",  # Rainier Ave S & S Forest St - Bay 4
    "1_8730",  # Rainier Ave S & Letitia Ave S
    "1_8740",  # Rainier Ave S & S Andover St
    "1_8760",  # Rainier Ave S & S Genesee St
    "1_8790",  # Rainier Ave S & S Edmunds St
    "1_8840",  # Rainier Ave S & S Orcas St
    "1_8870",  # Rainier Ave S & S Graham St
    "1_9132",  # University Way NE & NE 50th St
    "1_9133",  # University Way NE & NE 45th St
    "1_9134",  # U District Station - Bay 4
    "1_9135",  # University Way NE & NE 52nd St
    "1_9138",  # NE Campus Pkwy & 12th Ave NE - Bay 4
    "1_9140",  # University Bridge & NE 40th St
    "1_9144",  # NE Campus Pkwy & University Way NE
    "1_9147",  # Brooklyn Ave NE & NE Campus Pkwy - Bay 3
    "1_9150",  # Eastlake Ave E & E Allison St
    "1_9190",  # Eastlake Ave E & E Louisa St
    "1_940",  # Stewart St & 9th Ave
    "1_9550",  # Eastlake Ave E & E Allison St
    "1_9575",  # NE Campus Pkwy & University Way NE - Bay 2
    "1_9580",  # NE Campus Pkwy & Brooklyn Ave NE - Bay 1
    "1_9581",  # University Way NE & NE 41st St
    "1_9582",  # U District Station - Bay 5
    "1_9584",  # University Way NE & NE 45th St
    "1_9586",  # NE 50th St & University Way NE
    "1_9587",  # U District Station - Bay 1
    "1_9589",  # Roosevelt Way NE & NE 50th St
    "1_9610",  # Roosevelt Way NE & NE 42nd St
    "1_9650",  # 11th Ave NE & NE 45th St
    "1_9670",  # NE 125th St & Lake City Way NE
    "1_96760",  # Martin L King Jr Way & E Union St
    "1_9680",  # NE 125th St & 33rd Ave NE
    "1_9690",  # NE 125th St & 35th Ave NE
    "1_970",  # Stewart St & 4th Ave
    "1_9710",  # NE 125th St & 39th Ave NE
    "1_97137",  # NE 155th St & 5th Ave NE
    "1_9730",  # Sand Point Way NE & NE 120th St
    "1_9750",  # Sand Point Way NE & NE 115th St
    "1_9770",  # Sand Point Way NE & NE 110th St
    "1_9790",  # Sand Point Way NE & NE 106th St
    "1_9820",  # Sand Point Way NE & NE 97th St
    "1_9830",  # Sand Point Way NE & NE 95th St
    "1_9840",  # Sand Point Way NE & NE 93rd St
    "1_9850",  # Sand Point Way NE & Mathews Ave NE
    "1_9860",  # Sand Point Way NE & Inverness Dr NE
    "1_992",  # Howell St & 9th Ave
    "1_99500",  # W Mcgraw St & 31st Ave W
    "1_9972",  # Sand Point Way NE & Princeton Ave NE
    "1_9976",  # Sand Point Way NE & NE 50th St
    "1_9978",  # Sand Point Way NE & 40th Ave NE
    "1_9980",  # NE 55th St & Princeton Ave NE
    "20_261",  # Pier 50 Seattle Ferry Dock
    "29_3267",  # Shoreline North/185th Station Bay 2
    "29_3382",  # Shoreline North/185th Station Bay 1
    "3_1698",  # Boren Ave & Virginia St
    "3_1768",  # 15th Ave NE & NE Campus Pkwy
    "40_1108",  # Westlake
    "40_455",  # Symphony
    "40_501",  # Pioneer Square
    "40_532",  # Pioneer Square
    "40_55778",  # Columbia City
    "40_55949",  # Mount Baker
    "40_990002",  # U District
    "40_990003",  # Roosevelt
    "40_990004",  # Roosevelt
    "40_990005",  # Northgate
    "40_990006",  # Northgate
    "40_99101",  # Stadium
    "40_99603",  # Capitol Hill
    "40_99604",  # Univ of Washington
    "40_99605",  # Univ of Washington
    "40_N17-T1",  # Shoreline North/185th
]
