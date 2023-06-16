# 4.-4-way-set-associative-cache-with-tree-based-pseudo-LRU-design
此缓存总容量为32KB，Write Back, 替换策略为tree-based pseudo LRU，缓存内部两级流水。地址解码和选择将会被替换的缓存行由第一级流水线实现，访存操作在第二级流水线实现（多周期访存）。在FPGA上工作频率能接近170MHz。


<img width="344" alt="WBuffer-WB" src="https://github.com/IteratorandIterator/4.-4-way-set-associative-cache-with-tree-based-pseudo-LRU-design/assets/98395922/001bac30-19f6-4abf-8194-2a62e164e710">
<img width="443" alt="流程图-WB" src="https://github.com/IteratorandIterator/4.-4-way-set-associative-cache-with-tree-based-pseudo-LRU-design/assets/98395922/9e322722-2289-473d-ab00-f806af9cb8ab">
