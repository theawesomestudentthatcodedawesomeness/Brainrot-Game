-- GearData module to define all gear types and crafting requirements
local GearData = {}

-- Gear definitions (ordered by luck boost: least to most)
GearData.Gears = {
	["goofy_ahh_ring"] = {
		name = "Goofy Ring",
		displayName = "Goofy Ring",
		color = Color3.fromRGB(180, 180, 180),
		luckBoost = 30,
		rollPenalty = 0,
		description = "A janky ring made of pure nonsense.",
		rarity = "common",
		sortOrder = 1,
		tier = 1,
		recipe = {
			["Frigo Camelo"] = 4,
			["Lirilì Larilà"] = 2,
			["Ta Ta Ta Ta Sahur"] = 5,
			["Il Cacto Hipopotamo"] = 5,
			["Talpa Di Fero"] = 7,
		},
	},

	["zebra_stripe_bracelet"] = {
		name = "Zebra Stripe Bracelet",
		displayName = "Zebra Stripe Bracelet",
		color = Color3.fromRGB(0, 0, 0),
		luckBoost = 45,
		rollPenalty = 0,
		description = "Black and white stripes that confuse bad luck.",
		rarity = "common",
		sortOrder = 14,
		tier = 1,
		recipe = {
			["Zibra Zubra Zibralini"] = 3,
			["Makakini Bananini"] = 4,
			["Penguino Cocosino"] = 2,
			["Bobrelli Bananelli"] = 3,
		},
	},

	["bobrito_rusty_medal"] = {
		name = "Bobrito's Rusty Medal",
		displayName = "Bobrito's Rusty Medal",
		color = Color3.fromRGB(140, 70, 0),
		luckBoost = 60,
		rollPenalty = 0,
		description = "For questionable bravery in dumb situations.",
		rarity = "uncommon",
		sortOrder = 12,
		tier = 1,
		recipe = {
			["Boneca Ambalabu"] = 6,
			["Frulli Frulla"] = 8,
			["Cocofanto Elefanto"] = 5,
			["Burbaloni Lulilolli"] = 4,
			["Trulimero Trulicina"] = 3,
		},
	},

	["blueberry_octopus_necklace"] = {
		name = "Blueberry Octopus Necklace",
		displayName = "Blueberry Octopus Necklace",
		color = Color3.fromRGB(70, 130, 180),
		luckBoost = 75,
		rollPenalty = 0,
		description = "Eight tentacles of fortune wrapped around your neck.",
		rarity = "uncommon",
		sortOrder = 15,
		tier = 2,
		recipe = {
			["Blueberrinni Octopussini"] = 2,  -- FIXED: Added extra 'n'
			["Glorbo Fruttodrillo"] = 2,       -- FIXED: Globo ? Glorbo, Fruttadrillo ? Fruttodrillo
			["Graipucci Medussi"] = 1,         -- FIXED: Gralpussi ? Graipucci
			["Tigroligre Frutonni"] = 1,       -- FIXED: Tigrolifre ? Tigroligre, Fruttorini ? Frutonni
		},
	},

	["slim_hat_patapim"] = {
		name = "Slim Hat of Patapim",
		displayName = "Slim Hat of Patapim",
		color = Color3.fromRGB(150, 255, 150),
		luckBoost = 80,
		rollPenalty = -5,
		description = "The hat is loud. The luck is louder.",
		rarity = "uncommon",
		sortOrder = 11,
		tier = 2,
		recipe = {
			["Tric Trac Baraboom"] = 3,
			["Trulimero Trulicina"] = 2,
			["Brr Brr Patapim"] = 2,
			["Trippi Troppi"] = 1,
		},
	},

	["dancing_lotus_boots"] = {
		name = "Dancing Lotus Boots",
		displayName = "Dancing Lotus Boots",
		color = Color3.fromRGB(255, 192, 203),
		luckBoost = 90,
		rollPenalty = -3,
		description = "Step lightly, dance gracefully, win frequently.",
		rarity = "uncommon",
		sortOrder = 16,
		tier = 2,
		recipe = {
			["Ballerino Lotolo"] = 2,
			["Flamingulli-gulli-gulli"] = 1,
			["Capybarelli Bananalelli"] = 3,
			["Ecco Cavallo Virtuoso"] = 1,
		},
	},

	["time_stop_sandals"] = {
		name = "Time-Stop Sandals of Lirilì",
		displayName = "Time-Stop Sandals of Lirilì",
		color = Color3.fromRGB(255, 255, 127),
		luckBoost = 100,
		rollPenalty = -10,
		description = "When you walk, time slows. Lirilì's presence is felt.",
		rarity = "rare",
		sortOrder = 9,
		tier = 3,
		recipe = {
			["Lirilì Larilà"] = 25,
			["Il Cacto Hipopotamo"] = 18,
			["Brr Brr Patapim"] = 3,
			["Chef Crabracadabra"] = 2,
		},
	},

	["mechanical_pigeon_goggles"] = {
		name = "Mechanical Pigeon Goggles",
		displayName = "Mechanical Pigeon Goggles",
		color = Color3.fromRGB(135, 206, 235),
		luckBoost = 110,
		rollPenalty = -8,
		description = "See through the eyes of a professional pigeon engineer.",
		rarity = "rare",
		sortOrder = 17,
		tier = 3,
		recipe = {
			["Spillantro Golubino"] = 2,
			["Rhino Toasterino"] = 1,
			["Tortuighini Dragonfrutinni"] = 1,
			["Elephantuchi Bananaruchi"] = 2,
		},
	},

	["banana_peel_chimp_band"] = {
		name = "Banana-Peel Chimp Band",
		displayName = "Banana-Peel Chimp Band",
		color = Color3.fromRGB(255, 255, 0),
		luckBoost = 115,
		rollPenalty = -5,
		description = "A fruity fashion statement that increases luck drastically.",
		rarity = "rare",
		sortOrder = 3,
		tier = 3,
		recipe = {
			["Bananita Dolphinita"] = 2,
			["Chimpanzini Bananaini"] = 1,
			["Orangutini Ananassini"] = 1,
			["Trippi Troppi"] = 2,
		},
	},

	["watermelon_gorilla_gauntlets"] = {
		name = "Watermelon Gorilla Gauntlets",
		displayName = "Watermelon Gorilla Gauntlets",
		color = Color3.fromRGB(255, 20, 147),
		luckBoost = 120,
		rollPenalty = -12,
		description = "Crush your bad luck like a ripe watermelon.",
		rarity = "rare",
		sortOrder = 18,
		tier = 3,
		recipe = {
			["Gorillo Watermellondrillo"] = 1,  -- FIXED: Watermelondrillo ? Watermellondrillo (extra 'l')
			["Tigrrullini Watermellini"] = 1,   -- FIXED: Tigrullini ? Tigrrullini (extra 'r'), Watermelonini ? Watermellini
			["Bulliccrini Bananini"] = 3,
			["Pandaccini Bananini"] = 2,
		},
	},

	["assassino_coffee_blade_pendant"] = {
		name = "Assassino Coffee Blade Pendant",
		displayName = "Assassino Coffee Blade Pendant",
		color = Color3.fromRGB(100, 150, 255),
		luckBoost = 125,
		rollPenalty = 0,
		description = "A pendant brewed with chaos and espresso.",
		rarity = "rare",
		sortOrder = 2,
		tier = 2,
		recipe = {
			["Cappuccino Assassino"] = 2,
			["U Din Din Din Din Dun Ma Din Din Din Dun"] = 1,
			["Brri Brri Bicus Dicus Bombicus"] = 1,
			["Bobrito Bandito"] = 1,
		},
	},

	["orb_of_udindun"] = {
		name = "Orb of Udindun",
		displayName = "Orb of Udindun",
		color = Color3.fromRGB(255, 85, 0),
		luckBoost = 130,
		rollPenalty = -10,
		description = "It vibrates when you say UDIN DUN. RNG surges.",
		rarity = "legendary",
		sortOrder = 13,
		tier = 4,
		recipe = {
			["U Din Din Din Din Dun Ma Din Din Din Dun"] = 3,
			["Brri Brri Bicus Dicus Bombicus"] = 2,
			["Chef Crabracadabra"] = 2,
			["Bananita Dolphinita"] = 1,
		},
	},

	["cappuccina_pirouette_robe"] = {
		name = "Cappuccina Pirouette Robe",
		displayName = "Cappuccina Pirouette Robe",
		color = Color3.fromRGB(160, 190, 255),
		luckBoost = 135,
		rollPenalty = -10,
		description = "A spin-heavy robe for those dancing with destiny.",
		rarity = "legendary",
		sortOrder = 4,
		tier = 4,
		recipe = {
			["Cappuccino Assassino"] = 2,
			["Brr Brr Patapim"] = 2,
			["Girafa Celeste"] = 1,
			["Chimpanzini Bananaini"] = 1,
		},
	},

	["beetle_camel_hybrid_saddle"] = {
		name = "Beetle-Camel Hybrid Saddle",
		displayName = "Beetle-Camel Hybrid Saddle",
		color = Color3.fromRGB(255, 140, 0),
		luckBoost = 150,
		rollPenalty = -18,
		description = "Ride the chaos of automotive desert travel.",
		rarity = "legendary",
		sortOrder = 19,
		tier = 4,
		recipe = {
			["Tracotucotulu Delapeladustuz"] = 1,  -- FIXED: Tracotucullu ? Tracotucotulu
			["Sigma Boy"] = 4,
			["La Esok Sikola"] = 3,
			["Chai Maestro"] = 2,
		},
	},

	["toasterino_rhino_horn"] = {
		name = "Toasterino Rhino Horn",
		displayName = "Toasterino Rhino Horn",
		color = Color3.fromRGB(192, 192, 192),
		luckBoost = 165,
		rollPenalty = -22,
		description = "What can this horn apart within this horn is its personality... it is fascinating.",
		rarity = "legendary",
		sortOrder = 20,
		tier = 4,
		recipe = {
			["Rhino Toasterino"] = 1,
			["Crocodillo Penisini"] = 2,
			["Gorillini Bananini"] = 3,
		},
	},

	["tralalero_shark_kicks"] = {
		name = "Tralalero's Shark Kicks",
		displayName = "Tralalero's Shark Kicks",
		color = Color3.fromRGB(255, 120, 255),
		luckBoost = 180,
		rollPenalty = -15,
		description = "He defined brainrot. Now he boosts your RNG.",
		rarity = "mythic",
		sortOrder = 5,
		tier = 4,
		recipe = {
			["Tralalero Tralala"] = 1,
			["Los Tralaleritos"] = 1,
			["Bombombini Gusini"] = 1,
		},
	},

	["forest_ghost_glove"] = {
		name = "Forest Ghost Glove (Sahur's Grip)",
		displayName = "Forest Ghost Glove (Sahur's Grip)",
		color = Color3.fromRGB(0, 0, 0),
		luckBoost = 180,
		rollPenalty = -20,
		description = "Ghost energy from Sahur amplifies your fate.",
		rarity = "mythic",
		sortOrder = 7,
		tier = 5,
		recipe = {
			["Tun Tun Tun Sahur"] = 1,
			["Ta Ta Ta Ta Sahur"] = 8,
			["Bombombini Gusini"] = 1,
			["Chef Crabracadabra"] = 2,
			["Orangutini Ananassini"] = 1,
		},
	},

	["cosmic_jet_gusini_charm"] = {
		name = "Cosmic Jet Gusini Charm",
		displayName = "Cosmic Jet Gusini Charm",
		color = Color3.fromRGB(170, 220, 255),
		luckBoost = 195,
		rollPenalty = -15,
		description = "Gusini, airborne, glowing, unstoppable.",
		rarity = "mythic",
		sortOrder = 10,
		tier = 4,
		recipe = {
			["Bombombini Gusini"] = 2,
			["Bombardiro Crocodilo"] = 1,
			["Orangutini Ananassini"] = 1,
			["Brri Brri Bicus Dicus Bombicus"] = 1,
			["Crocodillo Ananasinno"] = 1,
		},
	},

	["mateo_infinite_glasses"] = {
		name = "Mateo's Infinite Glasses",
		displayName = "Mateo's Infinite Glasses",
		color = Color3.fromRGB(255, 215, 0),
		luckBoost = 205,
		rollPenalty = -25,
		description = "See through infinite dimensions of chaos with Mateo's endless vision.",
		rarity = "mythic",
		sortOrder = 21,
		tier = 5,
		recipe = {
			["Matteoooooooooooooo"] = 1,
			["Garamararamararaman dan Madudungdung tak tuntung perkuntung"] = 1,
			["Crocodillo Ananasinno"] = 2,
		},
	},

	["exploding_twin_gusini_charm"] = {
		name = "Exploding Twin Gusini Charm",
		displayName = "Exploding Twin Gusini Charm",
		color = Color3.fromRGB(255, 180, 60),
		luckBoost = 215,
		rollPenalty = -20,
		description = "Double the Gusini, double the detonation.",
		rarity = "mythic",
		sortOrder = 6,
		tier = 4,
		recipe = {
			["Bombombini Gusini"] = 3,
			["Bombardiro Crocodilo"] = 2,
			["Bobrito Bandito"] = 2,
			["Los Tralaleritos"] = 1,
		},
	},

	["tob_tobi_camel_crown"] = {
		name = "Tob Tobi Camel Crown",
		displayName = "Tob Tobi Camel Crown",
		color = Color3.fromRGB(255, 100, 100),
		luckBoost = 250,
		rollPenalty = -30,
		description = "The rhythmic crown that combines camels, cactuses and beards in perfect harmony.",
		rarity = "secret",
		sortOrder = 22,
		tier = 5,
		recipe = {
			["Tob Tobi Tob Tob Tobi Tob"] = 1,
			["Tracotucotulu Delapeladustuz"] = 1,  -- FIXED: Tracotucullu ? Tracotucotulu
			["Bombombini Gusini"] = 2,
			["Tortuighini Dragonfrutinni"] = 1,
		},
	},

	["la_vaca_cosmic_crown"] = {
		name = "La Vaca's Cosmic Crown",
		displayName = "La Vaca's Cosmic Crown",
		color = Color3.fromRGB(120, 190, 255),
		luckBoost = 270,
		rollPenalty = -25,
		description = "The divine crown of the cosmic cow herself.",
		rarity = "secret",
		sortOrder = 8,
		tier = 5,
		recipe = {
			["La Vaca Saturno Saturnita"] = 1,
			["Tralalero Tralala"] = 1,
			["Orangutini Ananassini"] = 2,
			["Burbaloni Lulilolli"] = 5,
			["Bombombini Gusini"] = 1,
		},
	},
}

return GearData