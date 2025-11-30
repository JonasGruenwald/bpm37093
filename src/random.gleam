import gleam/int
import gleam/list
import gleam/string

const latin_uppercase_letters = [
  "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P",
  "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
]

const waystation_nouns = [
  "Alexandria", "Amsterdam", "Antwerp", "Auckland", "Baltimore", "Barcelona",
  "Boston", "Bremen", "Busan", "Cadiz", "Calais", "Callao", "Cape Town",
  "Cartagena", "Charleston", "Chiba", "Copenhagen", "Danzig", "Dover", "Dubai",
  "Dublin", "Durban", "Genoa", "Glasgow", "Guangzhou", "Hamburg", "Havana",
  "Helsinki", "Hong Kong", "Houston", "Istanbul", "Jakarta", "Karachi", "Kobe",
  "Lagos", "Leningrad", "Lisbon", "Liverpool", "London", "Los Angeles",
  "Marseille", "Melbourne", "Miami", "Mombasa", "Montreal", "Mumbai", "Nagasaki",
  "Naples", "New Orleans", "New York", "Newcastle", "Odessa", "Osaka", "Oslo",
  "Panama", "Perth", "Philadelphia", "Plymouth", "Said", "Portland",
  "Portsmouth", "Riga", "Rio", "Rotterdam", "Diego", "San Francisco", "Santos",
  "Seattle", "Shanghai", "Singapore", "Southampton", "Stockholm", "Sydney",
  "Tangier", "Tokyo", "Toronto", "Trieste", "Valencia", "Vancouver", "Venice",
  "Vladivostok", "Wellington", "Yokohama", "Zanzibar",
]

const waystation_adjectives = [
  "Celestial", "Quantum", "Nebular", "Stellar", "Cosmic", "Astral", "Orbital",
  "Void", "Galactic", "Plasma", "Photonic", "Neural", "Crystalline",
  "Antimatter", "Hyperspatial", "Temporal", "Graviton", "Exo", "Trans", "Meta",
  "Ultra", "Chrono", "Nano", "Cyber", "Synth", "Holo", "Ion", "Neutron",
  "Subspace", "Warp", "Fusion", "Tachyon", "Singularity", "Transdimensional",
  "Heliospheric", "Interstellar", "Cryogenic", "Thermogenic", "Magnetic",
  "Kinetic", "Axial", "Radiant", "Luminous", "Prismatic", "Vectored",
]

pub fn waystation_name() -> String {
  [
    list.sample(waystation_adjectives, 1),
    list.sample(waystation_nouns, 1),
    [int.random(9999) |> int.to_string()],
  ]
  |> list.flatten()
  |> string.join(" ")
  |> string.uppercase()
}

const ship_nouns = [
  "Horizon", "Voyager", "Explorer", "Pioneer", "Pathfinder", "Navigator",
  "Seeker", "Wanderer", "Sentinel", "Guardian", "Vanguard", "Herald", "Runner",
  "Courier", "Drifter", "Nomad", "Pilgrim", "Wayfarer", "Phoenix", "Dragon",
  "Falcon", "Eagle", "Raven", "Hawk", "Serpent", "Hydra", "Chimera", "Sphinx",
  "Leviathan", "Kraken", "Dawn", "Dusk", "Eclipse", "Aurora", "Nebula", "Nova",
  "Comet", "Meteor", "Pulsar", "Quasar", "Beacon", "Ember", "Odyssey", "Venture",
  "Endeavor", "Discovery", "Fortune", "Destiny", "Legacy", "Genesis", "Exodus",
  "Prometheus", "Icarus", "Atlas", "Cutlass", "Corsair", "Balinger"
]

const ship_adjectives = [
  "Swift", "Bold", "Fierce", "Brave", "Noble", "Mighty", "Silent", "Shadow",
  "Ghost", "Phantom", "Spectral", "Stealth", "Crimson", "Azure", "Emerald",
  "Obsidian", "Silver", "Golden", "Iron", "Steel", "Titanium", "Diamond",
  "Platinum", "Chromium", "Dark", "Bright", "Burning", "Frozen", "Electric",
  "Volatile", "Ancient", "Eternal", "Infinite", "Sacred", "Divine", "Cursed",
  "Lost", "Broken", "Shattered", "Torn", "Scarred", "Weathered", "Rising",
  "Falling", "Dancing", "Soaring", "Drifting", "Wandering",
]

pub fn ship_name() -> String {
  [
    [
      list.sample(latin_uppercase_letters, 2)
      |> string.join(""),
    ],
    list.sample(ship_adjectives, 1),
    list.sample(ship_nouns, 1),
  ]
  |> list.flatten()
  |> string.join(" ")
}
