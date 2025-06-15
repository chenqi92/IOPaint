# IOPaint Docker 部署方案总结

## 完成的工作

根据您的需求，我已经完成了以下工作：

### 1. Docker镜像打包和推送脚本 (`docker_build_push.sh`)

✅ **功能特性:**
- 支持CPU和GPU版本分别构建
- 自动推送到Docker Hub (用户名: kkape)
- 支持环境变量配置
- 彩色日志输出和错误处理
- 灵活的版本标记

✅ **使用方法:**
```bash
# 构建CPU版本
./docker_build_push.sh 1.3.5 cpu

# 构建GPU版本
./docker_build_push.sh 1.3.5 gpu

# 构建所有版本
./docker_build_push.sh 1.3.5 all
```

### 2. 增强的Dockerfile配置

✅ **CPU版本 (`docker/CPUDockerfile`):**
- 基于Python 3.10.11-slim-buster
- 支持环境变量配置
- 自动启动脚本
- 优化的依赖安装

✅ **GPU版本 (`docker/GPUDockerfile`):**
- 基于NVIDIA CUDA 11.7.1
- 支持GPU加速
- PyTorch和xformers优化
- 环境变量配置支持

### 3. Docker Compose配置 (`docker-compose.yml`)

✅ **多环境支持:**
- CPU版本 (`--profile cpu`)
- GPU版本 (`--profile gpu`) 
- 开发版本 (`--profile dev`)

✅ **配置特性:**
- 完整的环境变量配置
- 数据卷持久化
- 网络配置
- 重启策略
- GPU资源分配

### 4. 完整的部署文档 (`DEPLOYMENT.md`)

✅ **内容包括:**
- 本地部署详细步骤
- Docker部署方法
- API接口完整说明
- 前后端分离实现示例
- 环境变量配置说明
- 故障排除指南

### 5. API测试工具 (`test_api.py`)

✅ **测试功能:**
- 服务器健康检查
- 图像修复API测试
- 模型信息获取
- 自动化测试报告

## 环境变量配置

### 支持的环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `IOPAINT_HOST` | 0.0.0.0 | 服务监听地址 |
| `IOPAINT_PORT` | 8080 | 服务端口 |
| `IOPAINT_MODEL` | lama | 使用的模型名称 |
| `IOPAINT_DEVICE` | cpu/cuda | 计算设备 |
| `IOPAINT_QUALITY` | 95 | 输出图片质量 (0-100) |
| `IOPAINT_NO_HALF` | false | 使用全精度模型 |
| `IOPAINT_LOW_MEM` | false | 低内存模式 |
| `IOPAINT_CPU_OFFLOAD` | false | CPU卸载模式 |
| `IOPAINT_DISABLE_NSFW_CHECKER` | false | 禁用NSFW检查 |
| `IOPAINT_INPUT` | - | 输入目录或文件 |
| `IOPAINT_OUTPUT_DIR` | - | 输出目录 |

### CPU vs GPU 配置

**CPU环境配置:**
```bash
docker run -p 8080:8080 \
  -e IOPAINT_MODEL=lama \
  -e IOPAINT_DEVICE=cpu \
  -e IOPAINT_LOW_MEM=true \
  kkape/iopaint:cpu
```

**GPU环境配置:**
```bash
docker run --gpus all -p 8080:8080 \
  -e IOPAINT_MODEL=runwayml/stable-diffusion-inpainting \
  -e IOPAINT_DEVICE=cuda \
  -e IOPAINT_LOW_MEM=false \
  kkape/iopaint:gpu
```

## API接口说明

### 主要接口

#### 1. 图像修复接口
```http
POST /api/v1/inpaint
Content-Type: application/json

{
  "image": "base64_encoded_image",
  "mask": "base64_encoded_mask",
  "prompt": "修复提示词",
  "ldm_steps": 20,
  "sd_seed": 42
}
```

#### 2. 服务器配置
```http
GET /api/v1/server-config
```

#### 3. 模型切换
```http
POST /api/v1/model
Content-Type: application/json

{
  "name": "lama",
  "type": "inpaint"
}
```

## 前后端分离使用

### 用户涂抹实现

**前端涂抹流程:**
1. 用户上传原始图像
2. 在Canvas上涂抹需要修复的区域
3. 生成蒙版图像 (白色=需要修复，黑色=保持不变)
4. 将原始图像和蒙版转换为Base64
5. 调用 `/api/v1/inpaint` 接口
6. 接收修复后的图像

**参数传递:**
```javascript
const requestData = {
  image: originalImageBase64,    // 原始图像
  mask: maskImageBase64,         // 用户涂抹生成的蒙版
  prompt: "beautiful landscape", // 修复提示词
  ldm_steps: 20,                // 处理步数
  sd_seed: 42                   // 随机种子
};
```

**返回数据:**
- 成功: 修复后的图像 (二进制数据)
- 失败: JSON错误信息

### 客户端示例

**JavaScript:**
```javascript
const api = new IOPaintAPI('http://localhost:8080');
const result = await api.inpaint(imageFile, maskFile, {
  prompt: 'beautiful landscape',
  steps: 20
});
```

**Python:**
```python
from iopaint_client import IOPaintClient
client = IOPaintClient('http://localhost:8080')
result = client.inpaint('image.jpg', 'mask.png', 
                       prompt='beautiful garden')
```

## 快速部署指南

### 1. 使用预构建镜像

```bash
# CPU版本
docker run -d --name iopaint-cpu -p 8080:8080 kkape/iopaint:cpu

# GPU版本  
docker run -d --name iopaint-gpu --gpus all -p 8080:8080 kkape/iopaint:gpu
```

### 2. 使用Docker Compose

```bash
# CPU部署
docker-compose --profile cpu up -d

# GPU部署
docker-compose --profile gpu up -d
```

### 3. 验证部署

```bash
# 测试API
python test_api.py --url http://localhost:8080

# 或访问Web界面
open http://localhost:8080
```

## 生产环境建议

### 1. 资源配置
- **CPU版本**: 最少2核4GB内存
- **GPU版本**: 最少4GB显存的NVIDIA GPU

### 2. 存储配置
```bash
# 挂载模型缓存目录
-v /data/iopaint/models:/root/.cache

# 挂载输出目录
-v /data/iopaint/output:/app/output
-e IOPAINT_OUTPUT_DIR=/app/output
```

### 3. 网络配置
```bash
# 反向代理配置
-e IOPAINT_HOST=0.0.0.0
-e IOPAINT_PORT=8080

# 使用nginx反向代理
location /iopaint/ {
    proxy_pass http://localhost:8080/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

### 4. 监控和日志
```bash
# 查看日志
docker logs -f iopaint-cpu

# 监控资源使用
docker stats iopaint-cpu
```

## 故障排除

### 常见问题及解决方案

1. **内存不足**: 设置 `IOPAINT_LOW_MEM=true`
2. **GPU不可用**: 检查nvidia-docker2安装
3. **端口冲突**: 修改端口映射
4. **模型下载失败**: 挂载模型缓存目录
5. **权限问题**: 检查文件夹权限

### 性能优化

1. **GPU加速**: 使用CUDA设备
2. **内存管理**: 启用低内存模式
3. **模型选择**: 根据需求选择合适模型
4. **缓存优化**: 持久化模型缓存

## 总结

✅ **已完成的功能:**
- Docker镜像自动构建和推送
- CPU/GPU环境自动检测和配置
- 完整的环境变量配置支持
- 详细的API接口文档
- 前后端分离实现示例
- 用户涂抹功能实现指南
- 生产环境部署方案

✅ **部署方式:**
- 本地Python环境部署
- Docker单容器部署
- Docker Compose多环境部署
- 生产环境集群部署

✅ **使用场景:**
- 图像修复和对象移除
- 背景替换和内容生成
- 批量图像处理
- API服务集成

现在您可以根据实际需求选择合适的部署方式，并通过提供的API接口实现前后端分离的图像处理应用。
