# scReportLite v0.7.0 浏览器验收清单

使用 RStudio Console 在包根目录运行：

```r
source("tests/manual/accept_v070.R", echo = TRUE)
```

脚本静态断言通过后，打开生成的 `v070_acceptance.html`，按顺序检查。

## 1. 报告包

- [ ] `v070_acceptance.html` 存在。
- [ ] `v070_acceptance_files/` 存在。
- [ ] HTML 与依赖目录一起移动后仍能双击打开。
- [ ] 页面加载后控制台没有红色 JavaScript 错误。

## 2. Preview

- [ ] 显示 240 cells。
- [ ] 显示 8 clusters。
- [ ] 显示 4 samples。
- [ ] Resolution overview 同时显示 0.2 和 0.4。
- [ ] 0.2 显示 4 clusters，0.4 显示 8 clusters。
- [ ] Preview 不提供交互式 resolution 切换或 clustree。

## 3. QC

- [ ] QC 页面能够打开。
- [ ] `nCount_RNA`、`nFeature_RNA`、`percent.mt` 可切换。
- [ ] retained 与 filtered 状态都存在。
- [ ] sample 切换后绘图和统计同步更新。
- [ ] 图形 resize 后没有遮挡或空白。

## 4. Feature

- [ ] FeatureScatter、Variable Features、Top Expressed、Elbow 均可打开。
- [ ] FeatureScatter x/y 指标可以切换。
- [ ] cluster/sample 着色能正常切换。
- [ ] Variable Features 显示完整数据并保留重点标签。
- [ ] Top Expressed 的 summary 与 outlier 详情可见。
- [ ] 子视图切换不会污染其他 Feature 子视图状态。

## 5. PCA

- [ ] Elbow、PC Score、PCA pair 视图均可打开。
- [ ] PC_1 至 PC_4 可以选择。
- [ ] cluster 与 sample 着色都正确。
- [ ] loading 表能够随 PC 选择更新。
- [ ] PCA 点数与输入细胞数一致。

## 6. UMAP cluster 模式

- [ ] UMAP 使用全部 240 个细胞。
- [ ] 8 个 cluster 的颜色稳定且互不混淆。
- [ ] 单选 cluster 时其他细胞正确变暗。
- [ ] 多选 cluster 时选择状态正确合并。
- [ ] reset 恢复全部细胞和正式 `cluster_col` 颜色。
- [ ] marker table 随 cluster 选择更新。

## 7. UMAP sample 模式

- [ ] Sample tab 显示 4 个样本。
- [ ] 单选 sample 时细胞高亮正确。
- [ ] sample composition 显示对应 cluster 计数。
- [ ] cluster 与 sample 联合选择符合交集语义。
- [ ] 切回 cluster 模式后状态和颜色可恢复。

## 8. UMAP gene 模式

- [ ] Gene tab 显示 CD3D、MS4A1、LST1、COL1A1。
- [ ] 基因搜索可用。
- [ ] 点击基因后 UMAP 按表达值着色。
- [ ] Gene Expression panel 显示所选基因摘要。
- [ ] 页面中不出现 `Gene expression data not available`。
- [ ] 切换不同基因后摘要和颜色同步更新。
- [ ] 退出 gene 模式后正式 cluster 颜色恢复。

## 9. 响应式与稳定性

- [ ] 宽屏下左右区域和中央图形位置正确。
- [ ] 窗口缩窄后侧栏/抽屉行为正确。
- [ ] 快速切换五个顶层页面不会产生空白图。
- [ ] 快速连续点击 cluster、sample、gene 不会抛错。
- [ ] Plotly modebar、缩放、平移和 reset 可用。

## 10. 验收结论

记录：

```text
R version:
scReportLite commit:
Browser and version:
Operating system:
Generated HTML size:
Generated _files size:
Console errors:
Failed checklist items:
Overall result: PASS / FAIL
```

