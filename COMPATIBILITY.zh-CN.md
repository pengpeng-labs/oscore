# 兼容性

[English](COMPATIBILITY.md)

oscore 0.1.1 依赖 pplang、pplc、pptc 0.4.0，以及 osbare 0.1.1 提供的
osbare ABI v1。当前接受的机器环境是该 osbare 版本建立的 x86-64 恒等映射环境。

源码兼容性只覆盖文档化的 v1 函数与结构。内部静态数据、表布局、错误诊断文字和
测试镜像组合方式都不是公开 API。
