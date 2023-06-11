# Esprit

## Screenshots

![esprit-screenshot0](https://github.com/eievui5/esprit/assets/14899090/3c3cd93b-a5e5-4717-8e7a-60533293bd12)
![esprit-screenshot1](https://github.com/eievui5/esprit/assets/14899090/7df06aa4-ed79-461e-b67c-10ed729d785a)

![esprit-screenshot2](https://github.com/eievui5/esprit/assets/14899090/22f68f8d-a4c8-4374-a075-7fefc2aa25b3)
![esprit-screenshot3](https://github.com/eievui5/esprit/assets/14899090/d18b33f1-30b9-49ad-8144-8c27dba94990)

## Dependencies

I use bleeding-edge RGBDS versions to help the maintainers test new features.
You will likely need to compile the master branch of RGBDS manually to be able
to build this project.

- [RGBDS 0.6.0](https://github.com/gbdev/rgbds)
- [GNU Make 4.3](https://www.gnu.org/software/make/)
- [Rust/cargo](https://www.rust-lang.org/)
- [evscript](https://github.com/eievui5/evscript)

Windows is not supported.
Use a POSIX environment like [WSL](https://docs.microsoft.com/en-us/windows/wsl/install) or [MSYS2](https://www.msys2.org/).

## Building

Navigate to the project root and execute `make`.
This will build the ROM and any tools needed by it, and place them in the `bin/` directory.

A few options are available for debugging.
Adding `CONFIG=` to your make invocation will allow you to enable some of these.
(For example, `make "CONFIG= FIRST_DUNGEON=xLakeDungeon"` will cause the game to begin in the lake instead of the forest)

The build-time options can be found in `src/include/config.inc`

## Naming Conventions

- All labels are `PascalCase`
  - Prefix `x`: ROMX
  - Prefix `v`: VRAM
  - Prefix `s`: SRAM
  - Prefix `w`: WRAM
  - Prefix `h`: HRAM

- Constants are in `ALL_CAPS`
- Macros are in `snake_case`

- All instructions and directives are in lowercase (`ld`, `call`, `db`, `section`, etc...)
