# Eagle Map Loader | MTA:SA

Eagle map loader is a resource for MTA:SA that allows for easy and nearly instant loading and proccessing of custom maps

## Supported Features

The following is a list of features this resource provides
- [x] = Supported
- [ ] = Planned support

#### Objects

- [X] Object placement
- [X] Custom ID assignment
- [x] LOD placement and assignment
- [X] Zone based map support
- [x] Compatability with default SA map
- [ ] MTA map editor (.map format) # Untested
  - [ ] Import
  - [ ] Export
  
#### Definitions

- [X] Custom ID assignment
- [X] Custom model loading
- [X] Quick map loading
- [X] Zone based map support
- [ ] Object Effects
  - [ ] Vegitation swaying
  - [ ] Moving objects EX : LCs draw bridge
  - [X] Day time & Night time only objects

## Usage

1. [Download](https://github.com/BlueEagle12/MTA-SA---Eagle-Loader) 
2. Place the folder 'eagleMapProccessor' in your resources folder
3. Start the resource
4. Start maps that use the resource

## Map creation

See these two GITHUBs for map creation : 

[Scripts for Blender](https://github.com/BlueEagle12/Eagle-Map-Proccessor---Blender-Scripts)

[Map proccessor for generating maps](https://github.com/BlueEagle12/MTA-SA-Eagle-Map-Proccessor)

#### Resource Exports

* [X] - loadMapDefinitions - `ResoueceName,Table with map definitions`
  - Used to load a map
* [X] - unloadMapDefinitions - `ResourceName`
  - Used to unload a map
* [X] - setElementStream - `object,ID`
  - Used to set an object or building ID. Using setElementID() will do the same thing.
* [X] - streamObject - `streamObject ( int streamID, float x, float y, float z, [ float rx, float ry, float rz )`
  - Create an object using eagleLoader, same pararmeters as createObject
* [X] - streamBuilding - `streamBuilding ( int streamID, float x, float y, float z [, float rx, float ry, float rz, int interior = 0 ] )`
  - Create a building using eagleLoader, same pararmeters as createBuilding


[Discord](https://discord.gg/q8ZTfGqRXj)
