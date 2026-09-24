# 字体

`ark-pixel-12px.otf` 是从下面两个开源像素字体构建出来的 12px 简体中文像素字体（SIL Open Font License 1.1）：

- **Ark Pixel Font 12px**（方舟像素字体，比例宽度，简体中文字形）by TakWolf — https://github.com/TakWolf/ark-pixel-font ，许可证见 `OFL-ark-pixel.txt`
- **Cubic 11**（俐方體11號）by ACh-K — https://github.com/ACh-K/Cubic-11 ，许可证见 `OFL-cubic-11.txt`

构建方式和 [Fusion Pixel Font](https://github.com/TakWolf/fusion-pixel-font) 相同：以 Ark Pixel 的字形源文件为主，
Ark Pixel 还没画完的汉字从 Cubic 11 按 12px 栅格化补上；之后裁剪为 GB2312 全部字符 + ASCII + 游戏里用到的字符。
按 OFL 要求，修改后的字体使用了不同的字体名（Ark Pixel 12px Game），且只能随软件分发、不能单独出售。
