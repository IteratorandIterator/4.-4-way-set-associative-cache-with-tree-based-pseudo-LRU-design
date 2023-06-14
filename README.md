# 4.-4-way-set-associative-cache-with-tree-based-pseudo-LRU-design
此缓存总容量为32KB，Write Back, 替换策略为tree-based pseudo LRU，缓存内部两级流水。地址解码和选择将会被替换的缓存行由第一级流水线实现，访存操作在第二级流水线实现（多周期访存）。在FPGA上工作频率能接近170MHz。
