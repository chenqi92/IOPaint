# IOPaint 部署和使用指南

IOPaint 是一个强大的图像修复工具，支持多种AI模型进行图像修复、对象移除、背景替换等功能。本文档详细介绍了如何在本地和Docker环境中部署IOPaint，以及如何使用其API接口。

## 目录

- [本地部署](#本地部署)
- [Docker部署](#docker部署)
- [API接口说明](#api接口说明)
- [前后端分离使用](#前后端分离使用)
- [环境变量配置](#环境变量配置)
- [故障排除](#故障排除)

## 本地部署

### 系统要求

- Python 3.8+
- 支持CUDA的GPU（可选，用于GPU加速）
- 至少4GB RAM（推荐8GB+）

### 安装步骤

1. **克隆项目**
```bash
git clone https://github.com/Sanster/IOPaint.git
cd IOPaint
```

2. **安装依赖**
```bash
# 创建虚拟环境（推荐）
python -m venv venv
source venv/bin/activate  # Linux/Mac
# 或 venv\Scripts\activate  # Windows

# 安装依赖
pip install -r requirements.txt

# 安装插件包
lama-cleaner --install-plugins-package
```

3. **启动服务**
```bash
# 基础启动
lama-cleaner start --host 0.0.0.0 --port 8080 --model lama

# GPU加速启动
lama-cleaner start --host 0.0.0.0 --port 8080 --model lama --device cuda

# 高级配置启动
lama-cleaner start \
  --host 0.0.0.0 \
  --port 8080 \
  --model lama \
  --device cuda \
  --output-dir ./output \
  --quality 95 \
  --enable-interactive-seg \
  --enable-remove-bg
```

### 可用模型

- **传统修复模型**: `lama`, `ldm`, `zits`, `mat`, `fcf`, `manga`, `cv2`, `migan`
- **扩散模型**: `runwayml/stable-diffusion-inpainting`, `diffusers/stable-diffusion-xl-1.0-inpainting-0.1`

## Docker部署

### 快速开始

#### CPU版本
```bash
# 拉取并运行CPU版本
docker run -d \
  --name iopaint-cpu \
  -p 8080:8080 \
  kkape/iopaint:cpu
```

#### GPU版本
```bash
# 拉取并运行GPU版本（需要NVIDIA Docker支持）
docker run -d \
  --name iopaint-gpu \
  --gpus all \
  -p 8080:8080 \
  kkape/iopaint:gpu
```

### 使用Docker Compose

项目提供了完整的`docker-compose.yml`配置文件，支持CPU和GPU两种部署方式。

#### CPU部署
```bash
# 启动CPU版本
docker-compose --profile cpu up -d

# 查看日志
docker-compose logs -f iopaint-cpu
```

#### GPU部署
```bash
# 启动GPU版本（需要nvidia-docker2）
docker-compose --profile gpu up -d

# 查看日志
docker-compose logs -f iopaint-gpu
```

#### 开发环境
```bash
# 使用本地构建的镜像
docker-compose --profile dev up -d
```

### 自定义配置

通过环境变量自定义配置：

```bash
docker run -d \
  --name iopaint-custom \
  -p 8080:8080 \
  -e IOPAINT_MODEL=lama \
  -e IOPAINT_DEVICE=cpu \
  -e IOPAINT_QUALITY=95 \
  -e IOPAINT_LOW_MEM=true \
  -v $(pwd)/input:/app/input \
  -v $(pwd)/output:/app/output \
  -e IOPAINT_INPUT=/app/input \
  -e IOPAINT_OUTPUT_DIR=/app/output \
  kkape/iopaint:cpu
```

### 构建自定义镜像

使用提供的构建脚本：

```bash
# 构建CPU版本
./docker_build_push.sh 1.3.5 cpu

# 构建GPU版本
./docker_build_push.sh 1.3.5 gpu

# 构建所有版本
./docker_build_push.sh 1.3.5 all
```

## API接口说明

IOPaint 提供了完整的RESTful API接口，支持前后端分离开发。

### 基础信息

- **Base URL**: `http://localhost:8080/api/v1`
- **Content-Type**: `application/json`
- **图片格式**: Base64编码

### 主要接口

#### 1. 获取服务器配置
```http
GET /api/v1/server-config
```

**响应示例**:
```json
{
  "plugins": [],
  "modelInfos": [...],
  "enableFileManager": false,
  "enableAutoSaving": true,
  "samplers": ["plms", "ddim", ...]
}
```

#### 2. 图像修复接口
```http
POST /api/v1/inpaint
```

**请求参数**:
```json
{
  "image": "base64_encoded_image",
  "mask": "base64_encoded_mask",
  "ldm_steps": 20,
  "ldm_sampler": "plms",
  "hd_strategy": "CROP",
  "prompt": "",
  "negative_prompt": "",
  "sd_seed": 42,
  "sd_strength": 1.0,
  "sd_guidance_scale": 7.5,
  "sd_num_inference_steps": 20
}
```

**响应**: 修复后的图像（二进制数据）

#### 3. 切换模型
```http
POST /api/v1/model
```

**请求参数**:
```json
{
  "name": "lama",
  "type": "inpaint"
}
```

#### 4. 调整蒙版
```http
POST /api/v1/adjust_mask
```

**请求参数**:
```json
{
  "mask": "base64_encoded_mask",
  "operate": "expand",
  "kernel_size": 5
}
```

### 完整参数说明

#### InpaintRequest 参数详解

| 参数名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `image` | string | - | Base64编码的原始图像 |
| `mask` | string | - | Base64编码的蒙版图像（白色区域为需要修复的区域） |
| `ldm_steps` | int | 20 | LDM模型的步数 |
| `ldm_sampler` | string | "plms" | LDM采样器类型 |
| `hd_strategy` | string | "CROP" | 高分辨率策略：CROP/RESIZE |
| `hd_strategy_crop_trigger_size` | int | 800 | 触发裁剪的尺寸阈值 |
| `hd_strategy_crop_margin` | int | 128 | 裁剪边距 |
| `prompt` | string | "" | 正向提示词（扩散模型） |
| `negative_prompt` | string | "" | 负向提示词（扩散模型） |
| `sd_seed` | int | 42 | 随机种子（-1为随机） |
| `sd_strength` | float | 1.0 | 扩散强度 (0.0-1.0) |
| `sd_guidance_scale` | float | 7.5 | 引导比例 |
| `sd_num_inference_steps` | int | 20 | 推理步数 |
| `sd_mask_blur` | int | 11 | 蒙版边缘模糊程度 |
| `sd_match_histograms` | bool | false | 是否匹配直方图 |

## 前后端分离使用

### 前端实现示例

#### JavaScript/TypeScript

```javascript
class IOPaintAPI {
  constructor(baseURL = 'http://localhost:8080') {
    this.baseURL = baseURL;
  }

  // 将文件转换为Base64
  async fileToBase64(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result.split(',')[1]);
      reader.onerror = reject;
      reader.readAsDataURL(file);
    });
  }

  // 图像修复
  async inpaint(imageFile, maskFile, options = {}) {
    const imageBase64 = await this.fileToBase64(imageFile);
    const maskBase64 = await this.fileToBase64(maskFile);
    
    const requestData = {
      image: imageBase64,
      mask: maskBase64,
      ldm_steps: options.steps || 20,
      ldm_sampler: options.sampler || 'plms',
      hd_strategy: options.strategy || 'CROP',
      prompt: options.prompt || '',
      negative_prompt: options.negativePrompt || '',
      sd_seed: options.seed || 42,
      sd_strength: options.strength || 1.0,
      sd_guidance_scale: options.guidanceScale || 7.5,
      sd_num_inference_steps: options.inferenceSteps || 20,
      ...options
    };

    const response = await fetch(`${this.baseURL}/api/v1/inpaint`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(requestData)
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    return response.blob();
  }

  // 获取服务器配置
  async getServerConfig() {
    const response = await fetch(`${this.baseURL}/api/v1/server-config`);
    return response.json();
  }

  // 切换模型
  async switchModel(modelName) {
    const response = await fetch(`${this.baseURL}/api/v1/model`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        name: modelName,
        type: 'inpaint'
      })
    });
    return response.json();
  }
}

// 使用示例
const api = new IOPaintAPI();

// 处理图像修复
async function handleInpaint(imageFile, maskFile) {
  try {
    const resultBlob = await api.inpaint(imageFile, maskFile, {
      prompt: 'beautiful landscape',
      steps: 30,
      guidanceScale: 8.0
    });

    // 显示结果
    const resultURL = URL.createObjectURL(resultBlob);
    document.getElementById('result').src = resultURL;
  } catch (error) {
    console.error('修复失败:', error);
  }
}
```

#### Python客户端示例

```python
import requests
import base64
from io import BytesIO
from PIL import Image

class IOPaintClient:
    def __init__(self, base_url="http://localhost:8080"):
        self.base_url = base_url

    def image_to_base64(self, image_path_or_pil):
        """将图像转换为Base64编码"""
        if isinstance(image_path_or_pil, str):
            # 文件路径
            with open(image_path_or_pil, "rb") as f:
                return base64.b64encode(f.read()).decode()
        else:
            # PIL Image对象
            buffer = BytesIO()
            image_path_or_pil.save(buffer, format="PNG")
            return base64.b64encode(buffer.getvalue()).decode()

    def inpaint(self, image, mask, **kwargs):
        """图像修复"""
        # 转换图像为Base64
        image_b64 = self.image_to_base64(image)
        mask_b64 = self.image_to_base64(mask)

        # 构建请求数据
        data = {
            "image": image_b64,
            "mask": mask_b64,
            "ldm_steps": kwargs.get("steps", 20),
            "ldm_sampler": kwargs.get("sampler", "plms"),
            "hd_strategy": kwargs.get("strategy", "CROP"),
            "prompt": kwargs.get("prompt", ""),
            "negative_prompt": kwargs.get("negative_prompt", ""),
            "sd_seed": kwargs.get("seed", 42),
            "sd_strength": kwargs.get("strength", 1.0),
            "sd_guidance_scale": kwargs.get("guidance_scale", 7.5),
            "sd_num_inference_steps": kwargs.get("inference_steps", 20),
        }

        # 发送请求
        response = requests.post(
            f"{self.base_url}/api/v1/inpaint",
            json=data,
            headers={"Content-Type": "application/json"}
        )

        if response.status_code == 200:
            # 返回PIL Image对象
            return Image.open(BytesIO(response.content))
        else:
            raise Exception(f"请求失败: {response.status_code} - {response.text}")

    def get_server_config(self):
        """获取服务器配置"""
        response = requests.get(f"{self.base_url}/api/v1/server-config")
        return response.json()

    def switch_model(self, model_name):
        """切换模型"""
        data = {"name": model_name, "type": "inpaint"}
        response = requests.post(
            f"{self.base_url}/api/v1/model",
            json=data,
            headers={"Content-Type": "application/json"}
        )
        return response.json()

# 使用示例
client = IOPaintClient()

# 加载图像和蒙版
original_image = Image.open("input.jpg")
mask_image = Image.open("mask.png")

# 执行修复
result = client.inpaint(
    original_image,
    mask_image,
    prompt="beautiful garden",
    steps=30,
    guidance_scale=8.0
)

# 保存结果
result.save("output.jpg")
```

### 用户涂抹区域的实现

#### HTML5 Canvas实现

```html
<!DOCTYPE html>
<html>
<head>
    <title>IOPaint 涂抹工具</title>
    <style>
        .canvas-container {
            position: relative;
            display: inline-block;
        }
        #maskCanvas {
            position: absolute;
            top: 0;
            left: 0;
            cursor: crosshair;
        }
        .controls {
            margin: 10px 0;
        }
        button {
            margin: 5px;
            padding: 10px 15px;
        }
    </style>
</head>
<body>
    <div class="controls">
        <input type="file" id="imageInput" accept="image/*">
        <label>画笔大小: <input type="range" id="brushSize" min="5" max="50" value="20"></label>
        <button onclick="clearMask()">清除蒙版</button>
        <button onclick="processImage()">开始修复</button>
    </div>

    <div class="canvas-container">
        <canvas id="imageCanvas"></canvas>
        <canvas id="maskCanvas"></canvas>
    </div>

    <div>
        <h3>修复结果:</h3>
        <img id="result" style="max-width: 500px;">
    </div>

    <script>
        const imageCanvas = document.getElementById('imageCanvas');
        const maskCanvas = document.getElementById('maskCanvas');
        const imageCtx = imageCanvas.getContext('2d');
        const maskCtx = maskCanvas.getContext('2d');
        const brushSizeSlider = document.getElementById('brushSize');

        let isDrawing = false;
        let currentImage = null;

        // 加载图像
        document.getElementById('imageInput').addEventListener('change', function(e) {
            const file = e.target.files[0];
            if (file) {
                const reader = new FileReader();
                reader.onload = function(event) {
                    const img = new Image();
                    img.onload = function() {
                        // 设置画布尺寸
                        imageCanvas.width = maskCanvas.width = img.width;
                        imageCanvas.height = maskCanvas.height = img.height;

                        // 绘制原始图像
                        imageCtx.drawImage(img, 0, 0);

                        // 清除蒙版
                        maskCtx.fillStyle = 'black';
                        maskCtx.fillRect(0, 0, maskCanvas.width, maskCanvas.height);

                        currentImage = file;
                    };
                    img.src = event.target.result;
                };
                reader.readAsDataURL(file);
            }
        });

        // 鼠标事件处理
        maskCanvas.addEventListener('mousedown', startDrawing);
        maskCanvas.addEventListener('mousemove', draw);
        maskCanvas.addEventListener('mouseup', stopDrawing);
        maskCanvas.addEventListener('mouseout', stopDrawing);

        function startDrawing(e) {
            isDrawing = true;
            draw(e);
        }

        function draw(e) {
            if (!isDrawing) return;

            const rect = maskCanvas.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;

            maskCtx.globalCompositeOperation = 'source-over';
            maskCtx.fillStyle = 'white';
            maskCtx.beginPath();
            maskCtx.arc(x, y, brushSizeSlider.value / 2, 0, Math.PI * 2);
            maskCtx.fill();
        }

        function stopDrawing() {
            isDrawing = false;
        }

        function clearMask() {
            maskCtx.fillStyle = 'black';
            maskCtx.fillRect(0, 0, maskCanvas.width, maskCanvas.height);
        }

        // 处理图像修复
        async function processImage() {
            if (!currentImage) {
                alert('请先选择图像');
                return;
            }

            // 获取蒙版数据
            const maskBlob = await new Promise(resolve => {
                maskCanvas.toBlob(resolve, 'image/png');
            });

            // 调用API
            const api = new IOPaintAPI();
            try {
                const result = await api.inpaint(currentImage, maskBlob, {
                    prompt: '',
                    steps: 20
                });

                // 显示结果
                const resultURL = URL.createObjectURL(result);
                document.getElementById('result').src = resultURL;
            } catch (error) {
                alert('修复失败: ' + error.message);
            }
        }
    </script>
</body>
</html>
```

## 环境变量配置

### 完整环境变量列表

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `IOPAINT_HOST` | 0.0.0.0 | 服务监听地址 |
| `IOPAINT_PORT` | 8080 | 服务端口 |
| `IOPAINT_MODEL` | lama | 使用的模型名称 |
| `IOPAINT_DEVICE` | cpu | 计算设备 (cpu/cuda) |
| `IOPAINT_QUALITY` | 95 | 输出图片质量 (0-100) |
| `IOPAINT_NO_HALF` | false | 使用全精度模型 |
| `IOPAINT_LOW_MEM` | false | 低内存模式 |
| `IOPAINT_CPU_OFFLOAD` | false | CPU卸载模式 |
| `IOPAINT_DISABLE_NSFW_CHECKER` | false | 禁用NSFW检查 |
| `IOPAINT_INPUT` | - | 输入目录或文件 |
| `IOPAINT_OUTPUT_DIR` | - | 输出目录 |

### Docker环境变量示例

```bash
# 基础配置
docker run -d \
  -p 8080:8080 \
  -e IOPAINT_MODEL=lama \
  -e IOPAINT_DEVICE=cpu \
  kkape/iopaint:cpu

# 高性能GPU配置
docker run -d \
  --gpus all \
  -p 8080:8080 \
  -e IOPAINT_MODEL=runwayml/stable-diffusion-inpainting \
  -e IOPAINT_DEVICE=cuda \
  -e IOPAINT_LOW_MEM=true \
  -e IOPAINT_CPU_OFFLOAD=true \
  kkape/iopaint:gpu

# 生产环境配置
docker run -d \
  --name iopaint-prod \
  -p 8080:8080 \
  -e IOPAINT_MODEL=lama \
  -e IOPAINT_DEVICE=cpu \
  -e IOPAINT_QUALITY=100 \
  -e IOPAINT_OUTPUT_DIR=/app/output \
  -v $(pwd)/output:/app/output \
  -v $(pwd)/models:/root/.cache \
  --restart unless-stopped \
  kkape/iopaint:cpu
```

## 故障排除

### 常见问题

#### 1. 内存不足
**症状**: 处理大图像时出现OOM错误
**解决方案**:
```bash
# 启用低内存模式
-e IOPAINT_LOW_MEM=true
-e IOPAINT_CPU_OFFLOAD=true
```

#### 2. GPU不可用
**症状**: CUDA相关错误
**解决方案**:
```bash
# 检查GPU状态
nvidia-smi

# 使用CPU模式
-e IOPAINT_DEVICE=cpu

# 或安装nvidia-docker2
sudo apt-get install nvidia-docker2
sudo systemctl restart docker
```

#### 3. 模型下载失败
**症状**: 网络连接错误或下载中断
**解决方案**:
```bash
# 使用本地模型
-v /path/to/models:/root/.cache

# 或设置代理
-e HTTP_PROXY=http://proxy:port
-e HTTPS_PROXY=http://proxy:port
```

#### 4. 端口冲突
**症状**: 端口已被占用
**解决方案**:
```bash
# 更改端口映射
-p 8081:8080

# 或更改容器内端口
-e IOPAINT_PORT=8081
-p 8081:8081
```

### 性能优化建议

1. **GPU加速**: 使用CUDA设备可显著提升处理速度
2. **内存管理**: 大图像处理时启用低内存模式
3. **模型选择**: 根据需求选择合适的模型（速度vs质量）
4. **批处理**: 对于大量图像，使用批处理模式
5. **缓存模型**: 挂载模型缓存目录避免重复下载

### 日志查看

```bash
# Docker容器日志
docker logs iopaint-cpu

# 实时日志
docker logs -f iopaint-cpu

# Docker Compose日志
docker-compose logs -f iopaint-cpu
```

## 总结

IOPaint 提供了灵活的部署选项和完整的API接口，支持从简单的本地部署到复杂的生产环境配置。通过合理的配置和优化，可以在各种环境中稳定运行，为用户提供高质量的图像修复服务。

如有问题，请参考[官方文档](https://github.com/Sanster/IOPaint)或提交Issue。
