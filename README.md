# PersonalGFWList
[![icon][icon.license]][link.license]

自用的 [GFWList][link.gfwlist] 增强工具，主要用于在官方规则基础上**补充自定义规则** 。适配 **[ZeroOmega][link.ZeroOmega] / [SwitchyOmega][link.SwitchyOmega]** 等代理插件，可直接通过订阅自动更新。

## 🎯 主要功能
- 🤖 **自动合并自定义规则**  
  使用 GitHub Actions 自动将 `user-rules.txt` 合并进官方 gfwlist。
- 📝 **自动更新文件信息**  
  合并后自动刷新修改时间、Checksum，并推送到 `release` 分支。
- 🔗 **自动通知其他项目**  
  支持 Webhook，在更新后触发下游项目操作。
- ✔️ **Checksum 校验工具**  
  `scripts/validateChecksum.sh` 用于校验 gfwlist 是否有效。
- 🔧 **自定义规则合并脚本**  
  `scripts/mergeGFWList.sh` 用于处理规则合并和格式整理。

## 🍽️ 食用指南
- 🍴 **Fork 本项目**
- 🔓 在项目中开启 Actions 写入权限  
   （Settings → Actions → General → Workflow permissions → 选择 *Read and write permissions*）
- ✏️ 根据需求修改 `user-rules.txt`
- 🚀 等待 GitHub Actions 自动运行（提交规则 或 每 6 小时一次 或 手动触发）
- 📦 在 `release` 分支获取最新的 `gfwlist.txt`  
- 🔄 将订阅地址填入  [ZeroOmega][link.ZeroOmega] / [SwitchyOmega][link.SwitchyOmega] 中的「规则列表订阅」即可自动同步更新

[icon.license]:            https://img.shields.io/badge/License-GPLv3-blue.svg
[link.license]:            https://github.com/kimi360/PersonalGFWList/blob/main/LICENSE
[link.gfwlist]:            https://github.com/gfwlist/gfwlist
[link.ZeroOmega]:          https://github.com/zero-peak/ZeroOmega
[link.SwitchyOmega]:       https://github.com/FelisCatus/SwitchyOmega

## 📌 注意事项

- GitHub Actions 默认会每 **6 小时**自动合并一次  
- 自定义规则必须符合 gfwlist 格式  
- 如果你需要在更新完成后触发其他仓库，请配置好 `WEBHOOK_URL` 与 `WEBHOOK_TOKEN` secrets 并根据实际情况修改你的请求体。 