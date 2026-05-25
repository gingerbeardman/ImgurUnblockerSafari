# ImgurUnblocker for Safari

A Safari Web Extension port of [HexedHero/ImgurUnblocker](https://github.com/HexedHero/ImgurUnblocker) for macOS that replaces Imgur image links with the DuckDuckGo proxy so they load in regions where Imgur is blocked (such as the UK).

It works on embedded content and direct links. Album pages are not supported (the original extension's limitation).

## Building

Open `ImgurUnblocker/ImgurUnblocker.xcodeproj` in Xcode and run the `ImgurUnblocker` scheme. The Safari extension is built as part of the host app.

`regen-icons.sh` rebuilds the icon set from the source SVG.

## Credits

Original extension by [HexedHero](https://github.com/HexedHero/ImgurUnblocker) — MIT licensed. This repository ports it to Safari on macOS.

## License

MIT — see [LICENSE.md](LICENSE.md).
