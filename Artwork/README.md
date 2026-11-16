# FelBot artwork

Current custom artwork sources:

- `FelBot-header.png`: the warlock demon banner.
- `FelBot-wordmark.png`: the transparent green and purple graffiti logo used at the top of the main README.
- `FelBot-icon-source.png`: the square FB master with an opaque black background, derived from the graffiti wordmark using built-in image generation.
- `FelBot-icon.png`: the 400 x 400 PNG ready for the CurseForge project logo.

The addon loads the converted textures in `../Media/Header.tga` and `../Media/Wordmark.tga`. `Convert-Header.ps1` and `Convert-Wordmark.ps1` regenerate these textures from the PNG sources when run from this Artwork directory.

`Convert-Icon.ps1` exports the CurseForge PNG and `../Media/Icon.tga` (256 x 256) for the in-game addon listing. The icon uses the F and B from the existing lettering style: bright fel green with purple depth on a solid black square. The full generation prompt is saved in `FelBot-icon-prompt.txt`.

The custom artwork is covered by the project's MIT licence. Blizzard spell and item artwork is referenced from the game client and is not included here.

## 0.5.15 screenshots

The current README uses the supplied images in `FelBiot 0.5.15 Screenshots` (the supplied folder name is preserved). The Buffs image shows 0.5.15. The other eleven images reuse the earlier 0.5.10 captures; the guide notes this so older layouts are not presented as new screenshots.
