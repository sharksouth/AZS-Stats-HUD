# AZS Stats HUD

**简体中文** | [English](README.en.md)

一个为《艾泽拉斯幸存者》制作的独立属性面板，让角色和冒险属性直接显示在游戏画面上。

## 功能

- 自动读取游戏提供的属性数据并刷新显示。
- 拖动面板调整位置；拖动右下角可分别调整宽度和高度，文字大小不变。高度不会小于当前内容所需的空间。
- 位置、缩放、显示和锁定状态会保存。
- 可锁定面板，使鼠标穿过。

## 安装

将 `AZSStatsHUD` 文件夹放入游戏目录的 `benilla-config/AddOns/`，确保文件夹内有 `AZSStatsHUD.toc`，然后重新进入游戏并在插件列表中启用。

## 命令

| 命令 | 功能 |
| --- | --- |
| `/ast` | 显示或隐藏 |
| `/ast lock` / `/ast unlock` | 锁定或解锁 |
| `/ast scale 0.8` | 设置整体缩放（0.6–1.6） |
| `/ast reset` | 恢复默认位置和大小 |
| `/ast debug` | 查看数据接收状态 |

## 说明和来源

面板独立读取游戏的 `AZS` 属性消息，不依赖 SurvivorsDragonUi。属性显示及数值含义参考游戏本身和 [SurvivorsDragonUi](https://github.com/migwynkriid13/SurvivorsDragonUi)；本仓库不包含该插件的代码或图片。界面使用游戏运行时提供的内置纹理，不打包游戏素材。

本项目是社区插件，与游戏作者及暴雪没有官方关联。
