/**
 * Generates Gleam module with space data from JSON files.
 */

import brightestStars from "./brightest_stars_50ly.json"
import lucy from "./bpm37093.json"

const targetModuleFile = process.argv[2] || "space_data.gleam";

const toSpaceObject = (entity) => `Object(
  name: "${entity.full_name}",
  short_name: "${entity.name}",
  position: Vec3(
    x: ${entity.x},
    y: ${entity.y},
    z: ${entity.z},
  ),
  earth_distance: ${entity.distance_ly},
  )`

let content = `//// Generated space data
import vec/vec3.{ Vec3}
import space.{Object}

`

const starDefinitions = brightestStars.map(star => toSpaceObject(star)).join(",\n\n");

const starListDefinition = `/// Star list
pub const stars = [
${starDefinitions}
]

`
content += starListDefinition;

const lucyDefinition = `/// BPM 37093 ("Lucy") white dwarf star
pub const lucy = ${toSpaceObject(lucy[0])}

`
content += lucyDefinition;

const solDefinition = `/// The Sun
pub const sol = Object(
  name: "Sol",
  short_name: "Sol",
  position: Vec3(
    x: 0.0,
    y: 0.0,
    z: 0.0,
  ),
  // Haha can you imagine though??
  earth_distance: 0.0,
)

`

content += solDefinition;

import { writeFileSync } from "fs";
writeFileSync(targetModuleFile, content);
console.log(`Wrote space data to ${targetModuleFile}`);