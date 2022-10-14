# Vuiiger Engine

## Screenshots

![the game's world map](https://user-images.githubusercontent.com/14899090/183221351-5f6b9d2d-f617-4ed0-838d-6ccbeead8e7d.png)
![the main characters fighting in a dungeon](https://user-images.githubusercontent.com/14899090/183221401-5bf87df2-3001-458f-ac44-f55f65885306.png)

![the inventory menu](https://user-images.githubusercontent.com/14899090/183221872-20b48756-8e38-48f7-93d6-e92d97b6c867.png)
![the player eating grapes](https://user-images.githubusercontent.com/14899090/183221981-14065202-7c6f-4bb7-af74-5f03551b787c.png)

## Dependencies

I use bleeding-edge RGBDS versions to help the maintainers test new features.
You will likely need to compile the master branch of RGBDS manually to be able
to build this project.

- [RGBDS 0.6.0](https://github.com/gbdev/rgbds)
- [GNU Make 4.3](https://www.gnu.org/software/make/)
- A C compiler
- [evscript](https://github.com/eievui5/evscript)

To run unit tests (optional, for development), additional dependancies are required.

- [Bash](https://www.gnu.org/software/bash/), or a similar software which can run bash scripts.
- [evunit](https://github.com/eievui5/evunit)

Windows is not supported.
Use a POSIX environment like [WSL](https://docs.microsoft.com/en-us/windows/wsl/install) or [MSYS2](https://www.msys2.org/).

## Building

Navigate to the project root and execute `make`. This will build the ROM and any
tools needed by it, and place them in the `bin/` directory.

## Naming Conventions

- All labels are `PascalCase`
  - Prefix `x`: ROMX
  - Prefix `v`: VRAM
  - Prefix `s`: SRAM
  - Prefix `w`: WRAM
  - Prefix `h`: HRAM

- Constants are in `ALL_CAPS`
- Macros are in `snake_case`

- RGBDS directives are in all caps (Such as `SECTION`, `INCLUDE`, `ASSERT`, but not `db`, `ds`, etc...)
- Instructions are in lowercase (Such as `ld`, `call`, as well as `db`, `ds`, etc...)
