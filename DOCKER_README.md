# IOPaint Docker 部署指南

本文档介绍了新增的Docker相关文件和使用方法。

## 新增文件

### 1. `docker_build_push.sh` - Docker镜像构建和推送脚本

自动化构建CPU和GPU版本的Docker镜像并推送到Docker Hub。

**使用方法:**
```bash
# 构建CPU版本
./docker_build_push.sh 1.3.5 cpu

# 构建GPU版本  
./docker_build_push.sh 1.3.5 gpu

# 构建所有版本
./docker_build_push.sh 1.3.5 all
```

**功能特性:**
- 支持CPU和GPU版本分别构建
- 自动标记版本号和latest标签
- 彩色日志输出
- 错误处理和状态检查
- 推送到Docker Hub (用户名: kkape)

### 2. `docker-compose.yml` - Docker Compose配置

提供了完整的Docker Compose配置，支持多种部署场景。

**使用方法:**
```bash
# CPU版本部署
docker-compose --profile cpu up -d

# GPU版本部署
docker-compose --profile gpu up -d

# 开发环境部署
docker-compose --profile dev up -d
```

**配置特性:**
- 支持CPU/GPU/开发三种profile
- 完整的环境变量配置
- 数据卷持久化
- 网络配置
- 重启策略

### 3. `DEPLOYMENT.md` - 完整部署和使用文档

详细的部署指南和API使用说明。

**内容包括:**
- 本地部署步骤
- Docker部署方法
- API接口详细说明
- 前后端分离实现示例
- 环境变量配置
- 故障排除指南

### 4. 更新的Dockerfile

增强了原有的CPU和GPU Dockerfile：

**新增功能:**
- 环境变量配置支持
- 自动启动脚本
- 灵活的参数配置
- 更好的错误处理

## 快速开始

### 1. 使用预构建镜像

```bash
# CPU版本
docker run -p 8080:8080 kkape/iopaint:cpu

# GPU版本
docker run --gpus all -p 8080:8080 kkape/iopaint:gpu
```

### 2. 使用Docker Compose

```bash
# 启动CPU版本
docker-compose --profile cpu up -d

# 访问服务
open http://localhost:8080
```

### 3. 自定义配置

```bash
docker run -p 8080:8080 \
  -e IOPAINT_MODEL=lama \
  -e IOPAINT_DEVICE=cpu \
  -e IOPAINT_QUALITY=95 \
  -v $(pwd)/output:/app/output \
  -e IOPAINT_OUTPUT_DIR=/app/output \
  kkape/iopaint:cpu
```

## 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `IOPAINT_HOST` | 0.0.0.0 | 服务监听地址 |
| `IOPAINT_PORT` | 8080 | 服务端口 |
| `IOPAINT_MODEL` | lama | 使用的模型 |
| `IOPAINT_DEVICE` | cpu/cuda | 计算设备 |
| `IOPAINT_QUALITY` | 95 | 图片质量 |
| `IOPAINT_LOW_MEM` | false | 低内存模式 |
| `IOPAINT_OUTPUT_DIR` | - | 输出目录 |

## API使用示例

### JavaScript
```javascript
const api = new IOPaintAPI('http://localhost:8080');
const result = await api.inpaint(imageFile, maskFile, {
  prompt: 'beautiful landscape',
  steps: 20
});
```

### Python
```python
from iopaint_client import IOPaintClient
client = IOPaintClient('http://localhost:8080')
result = client.inpaint('image.jpg', 'mask.png', prompt='beautiful garden')
```

### cURL
```bash
curl -X POST http://localhost:8080/api/v1/inpaint \
  -H "Content-Type: application/json" \
  -d '{
    "image": "base64_encoded_image",
    "mask": "base64_encoded_mask",
    "prompt": "beautiful landscape"
  }'
```

## 故障排除

### 常见问题

1. **内存不足**: 设置 `IOPAINT_LOW_MEM=true`
2. **GPU不可用**: 检查nvidia-docker2安装
3. **端口冲突**: 修改端口映射 `-p 8081:8080`
4. **模型下载失败**: 挂载模型缓存目录

### 日志查看

```bash
# 查看容器日志
docker logs iopaint-cpu

# 实时日志
docker logs -f iopaint-cpu
```

## 更多信息

详细的部署和使用说明请参考 `DEPLOYMENT.md` 文件。

## 支持

如有问题，请提交Issue或参考官方文档。
